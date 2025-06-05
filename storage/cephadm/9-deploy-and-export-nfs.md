# 部署与导出 NFS

由于端口冲突问题，如果需要建立多个 nfs cluster，每个 nfs cluster 需要部署在不同节点

```bash
# 创建 nfs 集群，这将创建 2 个服务 `nfs.bj1nfs01` 和 `ingress.nfs.bj1nfs01`, 另外从管理申请一个 vip 地址(同时必须填上 netmask）
ceph nfs cluster create bj1nfs01 "2 label:nfs" --ingress --ingress-mode haproxy-protocol --virtual_ip 100.68.17.1/20 
# 设置 .nfs 池 crush 规则, 解决 ceph osd pool autoscale-status 输出为空以及 PG Autoscale 不工作问题
ceph osd pool set .nfs crush_rule rep_ssd

# 创建 cephfs 导出 nfs 协议, --client_addr 指定允许的 nfs 客户端 ip 或者 ip 段挂载, 初始允许 ceph 集群所有节点访问
ceph nfs export create cephfs --cluster-id bj1nfs01 --pseudo-path /bj1cfs01 --fsname bj1cfs01 --client_addr 100.68.17.0/20

# 导出配置
ceph nfs export info bj1nfs01 /bj1cfs01 -o bj1cfs01nfs.json
# 在 clients.addresses 中添加允许的 nfs 客户端 ip 或者 ip 段
# 然后应用配置
ceph nfs export apply bj1nfs01 -i bj1cfs01nfs.json
```

