# [Rook Ceph](https://rook.io/)

> Beta

## 基本概念

[Ceph 基本概念与架构](https://www.redbooks.ibm.com/abstracts/redp5721.html)

## 准备

- 至少 3 台机器，每台至少插入 1 块本地盘
- 推荐额外配置 1 条网络用于集群内数据复制, 可以极大提升存储性能
  - 如果只有 1 条网络，则移除 `rook-ceph-cluster` 配置中的 `cephClusterSpec.network`
  - 如果有 2 条网络，根据实际的宿主机网络设置 `public` 和 `cluster` 网段
- 为存储节点打上额外 label, 即只有这些节点会部署 rook 集群
  ```sh
  kubectl label node bj1sn001 node-role.kubernetes.io/storage=true
  kubectl label node bj1sn002 node-role.kubernetes.io/storage=true
  kubectl label node bj1sn003 node-role.kubernetes.io/storage=true
  kubectl label node bj1sn004 node-role.kubernetes.io/storage=true
  ```

## 部署 Operator

  ```sh
  kubectl apply -k operator/

  # 等待 operator 就绪
  kubectl wait -n rook-ceph --for=condition=ready pod -l app=rook-ceph-operator
  ```

## 部署 CephCluster

  根据实际情况修改 [cluster/patch.yaml](./cluster/patch.yaml) 中的 public 和 cluster 网段

  ```sh
  # 部署 CephCluster
  kubectl apply -k cluster/

  # 查看 CephCluster 状态
  kubectl get cephclusters

  # 查看 CephCluster 详细信息
  kubectl describe cephcluster rook-ceph
  ```

## [安装 kubectl-rook-ceph 用于运维](https://github.com/rook/kubectl-rook-ceph)

1. 安装 [krew](https://krew.sigs.k8s.io/docs/user-guide/setup/install/)
2. 安装 kubectl-rook-ceph 执行 `kubectl krew install rook-ceph`
3. 使用 `kubectl rook-ceph ceph -s` 命令查看集群状态

## 排错

* [查看 osd 数量是否符合预期](https://rook.io/docs/rook/latest-release/Troubleshooting/ceph-common-issues/?h=osd+prepare#solution_4)

  ```sh
  # 查看 osd 数量是否符合预期
  kubectl rook-ceph ceph osd tree
  kubectl get po -n rook-ceph

  # 查看 osd 准备日志，找到未加入 osd 原因
  kubectl -n rook-ceph get pod -l app=rook-ceph-osd-prepare
  kubectl -n rook-ceph logs rook-ceph-osd-prepare-xxx-xxx provision

  # 重启 operator 触发重新发现 osd
  kubectl rollout restart deployment rook-ceph-operator
  ```

  通常 osd 未加入是磁盘或者之前集群残留，参见 [销毁集群](#销毁集群) 章节

## [创建 RBD 块存储](https://rook.io/docs/rook/latest-release/CRDs/Block-Storage/ceph-block-pool-crd/)

* 创建 rbd 存储池和 storageclass

  * 每个租户需要使用独立的 rbd 部署
  * 复制示例 [rbd/bj1rbd01.yaml](./rbd/bj1rbd01.yaml), 修改所有 `bj1rbd01` 为实际的名称
  * 根据实际情况修改 `CephBlockPool.spec.deviceClass` 为 `hdd` 或 `ssd` 等

  ```bash
  kubectl apply -f rbd/bj1rbd01.yaml
  ```

* 测试验证 RBD 工作正常

  测试验证 RBD 工作正常, 首先修改 [rbd/tests/pvc.yaml](./rbd/tests/pvc.yaml) 中的 `storageClassName` 为实际的名称

  ```bash
  kubectl apply -k rbd/tests/

  kubectl exec -it csirbd-demo-pod -- bash
  ```

## [创建 CephFS 文件系统](https://rook.io/docs/rook/latest-release/CRDs/Shared-Filesystem/ceph-filesystem-crd/)

* 创建 cephfs 文件系统和 storageclass

  * 每个租户需要使用独立的 cephfs 部署
  * 复制示例 [cephfs/bj1cfs01.yaml](./cephfs/bj1cfs01.yaml), 修改所有 `bj1cfs01` 为实际的名称
  * 生产环境 `metadataPool.deviceClass` 需要配置为 `ssd`, `dataPools.deviceClass` 根据实际情况选择 `hdd` 或 `ssd`
  * 生产环境 `dataPools.erasurecoded` 配置中的 `codingChunks` 即冗余至少为 `2`, 一般配置 `2+2` (需要4节点), `4+2` (需要6节点) 或 `8+3` (需要11节点)。 其中 `2+2` 是可靠性，性能和得盘率比较均衡配置选项。
  * 生产环境 `metadataServer.resources.memory` 至少 `32Gi`, 其与热元数据数量相关, 每个元数据大约占用内存 `3k` 大小，如果元数据缓存大小不足则会频繁回收内存造成严重性能下降
  * 缺省使用纠删码其得盘率更高，如果需要更高性能则可以使用副本，注释 `dataPools.erasurecoded` 整段配置, 并修改 `StorageClass.parameters.pool` 为 `bj1cfs01-replicated`

  ```bash
  kubectl apply -f cephfs/bj1cfs01.yaml
  ```

* 测试验证 CephFS 工作正常

  测试验证 CephFS 工作正常, 首先修改 [cephfs/tests/pvc.yaml](./cephfs/tests/pvc.yaml) 中的 `storageClassName` 为实际的名称

  ```bash
  kubectl apply -k cephfs/tests/

  kubectl exec -it csicephfs-demo-pod -- bash
  ```

## [使用 Ceph Dashboard](https://rook.io/docs/rook/latest-release/Storage-Configuration/Monitoring/ceph-dashboard/)

通常不直接使用 Ceph Dashboard 管理集群而是使用 rook, Ceph Dashboard 作为一个 GUI 查看工具

```bash
kubectl port-forward svc/rook-ceph-mgr-dashboard 8443
```

访问 https://localhost:8443 即可, 用户名为 `admin`, 密码使用下面命令获取

```bash
kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo
```

## [销毁集群](https://rook.io/docs/rook/latest-release/Getting-Started/ceph-teardown/)

```bash
# 销毁集群
kubectl rook-ceph destroy-cluster
# 输入 yes-really-destroy-cluster 后开始执行

# 删除 operator
kubectl delete -k operator/

# 删除宿主机残留
pdsh -w bj1sn[001-004] 'rm -rf /var/lib/rook'

# 抹除磁盘,下面方法任选其一
pdsh -w bj1sn[001-004] 'sgdisk --zap-all /dev/xxx'
pdsh -w bj1sn[001-004] 'dd if=/dev/zero bs=1M count=100 oflag=direct,dsync of=/dev/xxx'
# ssd 使用 blkdiscard 抹除而非 dd
pdsh -w bj1sn[001-004] 'blkdiscard /dev/xxx'
```

## 日常维护

[Rook 日常维护](./day-2.md)