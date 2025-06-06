# 部署 Ceph RBD

依赖 [部署 Ceph 集群](1-deploy-ceph-cluster.md)

## 简介

Ceph RBD 是 Ceph 提供的块存储服务，常用于数据库、虚拟机、容器等场景。

## 在 Ceph 集群上创建 RBD Pool

1. 创建副本 Pool 
    
    ```bash
    # 创建副本 pool 用于 rbd
    ceph osd pool create bj1rbd01 32 32 rep_ssd --bulk
    # (可选) 设置 pool 预计大小 (有助于 PG 数量分配到合理值)
    ceph osd pool set bj1rbd01 target_size_bytes 200T
    # 查看 pool 配置
    ceph osd pool get bj1rbd01 all

    # 初始化 pool 用于 rbd
    rbd pool init bj1rbd01
    ```

    Ceph支持为存储池创建quota

   ```bash
   # 为bj1rbd01设置quota为10T
   ceph osd pool set-quota bj1rbd01 max_bytes 10995116277760
   # 查看bj1rbd01的quota设定
   ceph osd pool get-quota bj1rbd01
   ```
    
3. 生成 Client 访问 Key
    
    ```bash
    ceph auth get-or-create client.bj1rbd01 mon 'profile rbd' osd 'profile rbd pool=bj1rbd01' mgr 'profile rbd pool=bj1rbd01' |tee /etc/ceph/ceph.client.bj1rbd01.keyring
    chmod 600 /etc/ceph/ceph.client.bj1rbd01.keyring
    ```

## 在 Linux 客户端使用

1. 安装 rbd 工具

    ```bash
    apt install -y ceph-common
    rbd --version
    ```
    
2. 获取 conf 和 key 文件存放到 `/etc/ceph` 目录下
    
    ```bash
    /etc/ceph/ceph.conf
    /etc/ceph/ceph.client.bj1rbd01.keyring
    ```
    
3. 创建 30G image 
    
    ```bash
    # 创建 30G image1
    rbd create --size 30G bj1rbd01/image1

    # 查看
    rbd ls bj1rbd01
    rbd info bj1rbd01/image1
    # 扩容
    rbd resize --size 50G bj1rbd01/image1
    # 缩容
    rbd resize --size 20G bj1rbd01/image1 --allow-shrink
    # 永久删除
    rbd rm bj1rbd01/image1

    # 移动到回收站
    rbd trash mv bj1rbd01/image1
    # 查看回收站
    rbd trash ls bj1rbd01
    # 恢复
    rbd trash restore bj1rbd01/<id>
    # 永久删除
    rbd trash rm bj1rbd01/<id>
    # 清空回收站 (这将永久删除)
    rbd trash purge bj1rbd01
    ```

4. 映射块设备到客户端上

    ```bash
    # 映射到本地
    rbd device map bj1rbd01/image1
    # 查看
    rbd device ls
    # 取消映射
    rbd device unmap bj1rbd01/image1
    ```

5. 格式化为本地文件系统并挂载使用

    ```bash
    mkfs.xfs /dev/rbd0
    mkdir /mnt/image1
    mount /dev/rbd0 /mnt/image1
    ```

## 在 Kubernetes 上使用

访问 [Ceph CSI RBD](../../core/ceph-csi-rbd/README.md)
