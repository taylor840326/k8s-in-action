# [GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/index.html)

用于支持配置 GPU 设备的 Kubernetes 集群, 主要包含安装 GPU 驱动，Container Runtime Nvidia, K8S Device Plugin 等

## 准备

宿主机安装最新 GPU 驱动

## 部署

- 驱动

  - [推荐]使用宿主机部署 GPU 驱动以满足灵活性
  - 如果计划使用 GPU Operator 部署 GPU 驱动, 则修改

    - 修改 [values.yml](values.yml) 中的 `driver.enabled: true`
    - 部署自定义配置 `kubectl apply -k driver`
    - 如果环境配置 Infiniband/RoCE 设备，且 GPU 是企业级卡（例如 A100, H100 和 B200 等） 则设置 [values.yml](values.yml) 中的 `driver.rdma.enabled: true` 选项, 如果 IB/RoCE 驱动使用宿主机管理则设置 `driver.rdma.useHostMofed: true` 
    - 设置 host 上 `nvidia-smi` 命令可执行

      ```sh
      cat << 'EOF' > nvidia-smi.sh
      alias nvidia-smi="chroot /run/nvidia/driver nvidia-smi"
      EOF

      pdcp -w ^all nvidia-smi.sh /etc/profile.d/
      source /etc/profile.d/nvidia-smi.sh
      ```

- 自定义 dcgm-exporter 配置和抓取指标到 vm 中

  ```sh
  kubectl apply -f dcgm-exporter-config.yml
  ```

  在 Grafana 中添加 Nvidia DCGM Dashboard (Import 时使用 ID: `21362`)

- 部署 helm chart

  ```sh
  helmwave up --build
  ```

- 设置 GPU 节点缺省 Container Runtime 使用 `nvidia`

  > 只需要修改 GPU 节点的配置

  ```sh
  pdsh -w ^all "sed -i '/token/a default-runtime: nvidia' /etc/rancher/k3s/config.yaml"
  pdsh -w ^server systemctl restart k3s
  pdsh -w ^agent systemctl restart k3s-agent
  ```

- 测试

  运行一个 Cuda 示例用于检查基础环境是否准备好

  ```sh
  kubectl apply -f tests.yaml
  kubectl logs -f cuda-vectoradd
  kubectl delete -f tests.yaml
  ```

- 卸载

  ```sh
  helmwave down

  kubectl delete -k dcgm
  kubectl delete -k driver
  ```
