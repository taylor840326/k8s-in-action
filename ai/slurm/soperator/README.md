# [Soperator](https://github.com/nebius/soperator)

> Alpha

## 前置

* K8S 集群版本要求 1.30 或以上
* CNI 必须支持**保留客户端源 IP**，其中 Cilium 经过测试
* PVC 支持共享文件系统, 例如 NFS 或 CephFS
* [NFD](../nfd) 已部署

## 部署

```bash
helmwave up --build

cd bj1slurm01
helmwave up --build
```

## 卸载

```bash
cd bj1slurm01
helmwave down

cd ..
helmwave down
```

