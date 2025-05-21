# NFS CSI

> Beta

## 前置准备

- 创建 RAID 设备。如果使用多块本地磁盘，可以创建软 RAID，参考 https://ruan.dev/blog/2022/06/29/create-a-raid5-array-with-mdadm-on-linux
- 创建 NFS Server。参考 https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nfs-mount-on-ubuntu-22-04

## 部署 

- 部署 NFS CSI

  ```sh
  helmwave up --build
  ```

- 部署 storageclass

  假设 NFS Server 在 172.16.21.11，共享目录为 /data, 把这些信息配置在 shared-nfs.yaml 中

  ```sh
  # 把 k8s 使用目录放在独立的子目录 /data/volumes 下
  mkdir /data/volumes

  kubectl apply -f shared-nfs.yaml
  ```

  > 如果使用多个 NFS 则重复上述步骤

## 测试

```sh
# 部署测试用例
kubectl apply -f tests.yml

# 等待部署 pod 运行
kubectl  get po

# 进入 pod 观察 nfs 是否挂载以及正常读写
kubectl exec -it deployment-nfs-xxxxx-xxx -- bash

# 清理测试用例
kubectl delete -f tests.yml
```

## 卸载

```sh
kubectl delete -f shared-nfs.yml

helmwave down
```
