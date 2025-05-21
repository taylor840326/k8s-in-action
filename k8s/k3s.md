# K3S

> Beta

准备用于 pdsh 的节点列表

```sh
cat << 'EOF' > server
bj1mn[01-03]
EOF

cat << 'EOF' > agent
bj1gn[001-003]
EOF
```


## 安装 haproxy 和 keepalived 用于 k3s apiserver 负载均衡

```sh
# 安装 haproxy 和 keepalived
pdsh -w ^server apt install -y haproxy keepalived

# 准备 haproxy 配置文件
cat << 'EOF' > haproxy.cfg
frontend k3s-frontend
    bind *:7443
    mode tcp
    option tcplog
    default_backend k3s-backend

backend k3s-backend
    mode tcp
    option tcp-check
    balance roundrobin
    default-server inter 10s downinter 5s
    server bj1mn01 172.18.15.101:6443 check
    server bj1mn02 172.18.15.101:6443 check
    server bj1mn03 172.18.15.101:6443 check
EOF
pdcp -w ^server haproxy.cfg /etc/haproxy/haproxy.cfg
pdsh -w ^server systemctl restart haproxy

# 准备 keepalived 配置文件
# * virtual_router_id 请**随机从 0-255 之间选择一个值**，如果相同网络环境有其它用户也启动 keepalived, 需要避免此值相同, 否则会导致冲突
# * 172.18.15.199 为 vip (**子网掩码值必须和物理网络一致**, 否则可能无法访问)，可以使用局域网中空闲的 IP，如果使用数据中心则需要联系管理员获取
cat << 'EOF' > bj1mn01-keepalived.conf
vrrp_script chk_haproxy {
    script 'killall -0 haproxy' # faster than pidof
    interval 2
}

vrrp_instance haproxy-vip {
    interface eth0 # change it
    state MASTER 
    priority 100 

    virtual_router_id 52

    virtual_ipaddress {
      172.18.15.199/24
    }

    unicast_src_ip 172.18.15.101
    unicast_peer {
      172.18.15.102
      172.18.15.103
    }

    track_script {
        chk_haproxy
    }
}
EOF
pdcp -w bj1mn01 bj1mn01-keepalived.conf /etc/keepalived/keepalived.conf

cat << 'EOF' > bj1mn02-keepalived.conf
vrrp_script chk_haproxy {
    script 'killall -0 haproxy' # faster than pidof
    interval 2
}

vrrp_instance haproxy-vip { 
    interface eth0 # change it
    state BACKUP 
    priority 90 

    virtual_router_id 52    

    virtual_ipaddress {
      172.18.15.199/24
    }

    unicast_src_ip 172.18.15.102
    unicast_peer {
      172.18.15.101
      172.18.15.103
    }

    track_script {
        chk_haproxy
    }
}
EOF
pdcp -w bj1mn02 bj1mn02-keepalived.conf /etc/keepalived/keepalived.conf

cat << 'EOF' > bj1mn03-keepalived.conf
vrrp_script chk_haproxy {
    script 'killall -0 haproxy' # faster than pidof
    interval 2
}

vrrp_instance haproxy-vip { 
    interface eth0 # change it
    state BACKUP 
    priority 80 

    virtual_router_id 52    

    virtual_ipaddress {
      172.18.15.199/24
    }

    unicast_src_ip 172.18.15.103
    unicast_peer {
      172.18.15.101
      172.18.15.102
    }

    track_script {
        chk_haproxy
    }
}
EOF 
pdcp -w bj1mn03 bj1mn03-keepalived.conf /etc/keepalived/keepalived.conf

# 重启 keepalived
pdsh -w ^server systemctl restart keepalived
```

## 安装 k3s

所有节点准备

```sh
pdsh -w ^all mkdir -p /etc/rancher/k3s

# 设置 docker.io 镜像代理, 原因是 docker 官网有限速
# 其他设置因为开启 embedded-registry 需要 
cat << 'EOF' > registries.yaml
mirrors:
  docker.io:
    endpoint:
      - "https://mirror.gcr.io"
  registry.k8s.io:
  gcr.io:
  ghcr.io:
  nvcr.io:
  k8s.gcr.io:
  quay.io:
  cr.example.com:
EOF
pdcp -w ^all registries.yaml /etc/rancher/k3s

# 设置 containerd 代理
# * 假设 172.18.3.171 为代理服务器的 IP 地址，8080 为代理服务器的端口
# * NO_PROXY 中还可以 bypass 域名，例如 `*.example.com`, 一般需要设置 harbor 搭建镜像仓库
# 设置 `CATTLE_NEW_SIGNED_CERT_EXPIRATION_DAYS=3650` 使自动签订的证书有效期为10年
cat << 'EOF' > k3s.service.env
CONTAINERD_HTTP_PROXY=http://172.18.3.171:8080
CONTAINERD_HTTPS_PROXY=http://172.18.3.171:8080
NO_PROXY="127.0.0.1/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,100.64.0.0/10,localhost,*.example.com"
CATTLE_NEW_SIGNED_CERT_EXPIRATION_DAYS=3650
EOF
chmod 0600 k3s.service.env
pdcp -w ^server k3s.service.env /etc/systemd/system
# 复制后，其中 CATTLE_NEW_SIGNED_CERT_EXPIRATION_DAYS 在 agent 不是必须的可以移除掉
cp k3s.service.env k3s-agent.service.env
pdcp -w ^agent k3s-agent.service.env /etc/systemd/system
```

### 安装 k3s server

```sh
# 准备 scheduler 配置文件, 用于调度优先填满一个 GPU 节点
cat << 'EOF' > scheduler.yaml
apiVersion: kubescheduler.config.k8s.io/v1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: /etc/rancher/k3s/k3s.yaml
profiles:
- pluginConfig:
  - args:
      scoringStrategy:
        resources:
        - name: cpu
          weight: 1
        - name: memory
          weight: 1
        - name: nvidia.com/gpu
          weight: 3
        type: MostAllocated
    name: NodeResourcesFit
EOF
pdcp -w ^server scheduler.yaml /etc/rancher/k3s/scheduler.yaml

# 准备 server 配置文件
# * node-ip 请替换为当前 server 节点的 IP 地址
# * token 执行 `echo $(tr -dc a-z0-9 </dev/urandom | head -c 32)` 生成
# * cluster-cidr 和 service-cidr 设置 Pod 和 Service 的 IP 地址范围, 需要询问用户是否存在地址段冲突问题
# * tls-san 设置需要签名的 IP 或者域名，通常设置为 vip 和需要通过外网连接 k3s 的 IP 地址, 如果不设置则 kubeconfig 中需要设置跳过安全检查
# * disable 关闭 k3s 缺省部署的服务，后续步骤部署 `nginx` 和 `metallb` 作为替代
cat << 'EOF' > server.yaml
node-ip: <node-ip>
token: <token>
cluster-cidr: 172.24.0.0/13
service-cidr: 172.23.0.0/16
tls-san:
- 172.18.15.199
flannel-backend: "none"
disable-network-policy: true
disable:
- traefik
- servicelb
- local-storage
embedded-registry: true
kubelet-arg:
- runtime-request-timeout=15m
- container-log-max-files=3
- container-log-max-size=10Mi
kube-scheduler-arg:
- authentication-tolerate-lookup-failure=false
- config=/etc/rancher/k3s/scheduler.yaml
EOF
chmod 0600 server.yaml
pdcp -w ^server server.yaml /etc/rancher/k3s/config.yaml
```

```sh
# 在 bj1mn01 上初始化集群
# * 如果 k3s server 不需要支持 HA，则去掉 `--cluster-init` 即可，除 bj1mn01 外其他所有节点使用下面 agent 方式加入集群
curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh \
  | INSTALL_K3S_MIRROR=cn INSTALL_K3S_VERSION=v1.32.4+k3s1 sh -s - server \
    --cluster-init

# 在剩余 bj1mn[02-03] 节点上加入集群, 其中 172.18.15.101 为 bj1mn01 的 IP 地址, 请修改为实际 IP
curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh \
  | INSTALL_K3S_MIRROR=cn INSTALL_K3S_VERSION=v1.32.4+k3s1 sh -s - server \
	  --server https://172.18.15.199:7443
```

> * 最新文档版本可以从 [channel](https://update.k3s.io/v1-release/channels/stable) 中查询

### 安装 k3s agent

```sh
# 准备 agent 配置文件
# * node-ip 请替换为当前 agent 节点的 IP 地址
# * token 请替换为上面 server 配置中的 token
cat << 'EOF' > agent.yaml
node-ip: <node-ip>
token: <token>
kubelet-arg:
- runtime-request-timeout=15m
- container-log-max-files=3
- container-log-max-size=10Mi
EOF
chmod 0600 agent.yaml
pdcp -w ^agent agent.yaml /etc/rancher/k3s/config.yaml
```

```sh
# 在非 mn 节点上加入集群, 其中 172.18.15.101 为 bj1mn01 的 IP 地址, 请修改为实际 IP
curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh \
	| INSTALL_K3S_MIRROR=cn INSTALL_K3S_VERSION=v1.32.4+k3s1 sh -s - agent \
	--server https://172.18.15.199:7443
```

### 访问 k3s 集群

- 在集群中执行 kubectl 即可访问
- 在非集群的局域网网内
  ```sh
  cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
  sed -i 's/127.0.0.1:6443/172.18.15.199:7443/g' ~/.kube/config
  kubectl get node
  ```
- 在外网访问，假如能通过外网 IP 1.2.3.4 访问任意的 mn 节点 7443 端口
  ```sh
  cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
  sed -i 's/127.0.0.1:6443/1.2.3.4:7443/g' ~/.kube/config
  kubectl get node
  ```
- 如果访问的 IP 未在 server 配置中的 `--tls-san`，则需要跳过安全检查，移除 kubeconfig 中的 `certificate-authority-data: xxx` 并添加 `insecure-skip-tls-verify: true` 即可

### 常用配置

- 修改 CoreDNS 和 Metrics Server 的配置

  ```bash
  kubectl patch deployment coredns -n kube-system --type merge --patch-file k3s-patch/coredns-patch.yaml
  kubectl patch deployment metrics-server -n kube-system --type merge --patch-file k3s-patch/metrics-server-patch.yaml
  ```

- 为控制节点打上污点

  ```bash
  kubectl taint node bj1mn01 node-role.kubernetes.io/control-plane:NoSchedule
  kubectl taint node bj1mn02 node-role.kubernetes.io/control-plane:NoSchedule
  kubectl taint node bj1mn03 node-role.kubernetes.io/control-plane:NoSchedule
  ```

- 修复在训练场景无法申请大内存的问题

  ```sh
  pdsh -w ^server "sed -i '/LimitCORE/a LimitMEMLOCK=infinity' /etc/systemd/system/k3s.service"
  pdsh -w ^agent "sed -i '/LimitCORE/a LimitMEMLOCK=infinity' /etc/systemd/system/k3s-agent.service"
  pdsh -w ^all systemctl daemon-reload
  pdsh -w ^server systemctl restart k3s
  pdsh -w ^agent systemctl restart k3s-agent
  ```

## 常见问题

* 证书过期问题

  ```sh
  # 检查证书有效期
  k3s certificate check

  # 调整证书有效期从 1 年调整为 10 年, 需要更新 systemd env 变量
  CATTLE_NEW_SIGNED_CERT_EXPIRATION_DAYS=3650

  # 重新签发证书, 有效期大于 90 天必须执行
  k3s certificate rotate

  # 滚动重启每个节点，重启不会触发 Pod 重启
  systemctl restart k3s
  systemctl restart k3s-agent
  ```

## 卸载 k3s

```sh
pdsh -w ^agent k3s-agent-uninstall.sh
pdsh -w ^server k3s-uninstall.sh
```
