# 移除指定主机

本文档参考如下文档： https://www.ibm.com/docs/en/storage-ceph/7?topic=installation-removing-hosts

## 获取主机详情

执行如下命令获取主机列表

```bash
# ceph orch host ls
HOST      ADDR        LABELS                         STATUS  
...
bj1sn004	10.11.62.8                           
...
```

## 移除主机上的daemon

本文档以移除bj1sn004节点为例，执行如下命令。

```bash
# ceph orch host drain bj1sn004
```

查看主机移除状态

```bash
# ceph orch host ls
HOST      ADDR        LABELS                         STATUS  
...
bj1sn004	10.11.62.8        _no_schedule,_no_conf_keyring                    
...
_no_schedule标签会自动应用在即将下线的节点上。
```

```bash
# ceph orch osd rm status
查看osd 移除进程
```

```bash
# ceph -s
可以看到ceph集群会处于recovering状态直到osd服务全部下线完成。
完成后osd数量已经变更为目标值。
```

```bash
# ceph orch ps bj1sn004
No daemons reported
确认是否还有daemon在运行
```

## 完全移除主机

```bash
# ceph orch rm bj1sn004
```

如果主机离线并且不可恢复， 则可以从集群中移除

```bash
# ceph orch host rm bj1sn004 --offline --force
```
如果数据没有冗余则此操作造成数据丢失。另外，可能需要更新 service spec 文件以移除主机描述。

# 维护模式

## 进入维护模式

确认主机停止不会影响数据可靠性

```bash
# ceph orch host ok-to-stop <hostname>
```

进入维护模式，则停止主机上所有守护进程
1. 应用 noout 在指定主机上
2. 停止主机上的守护进程
3. 阻止主机上的服务开机自启动

```bash
# ceph orch host maintenance enter <hostname> [--force]
```

## 退出维护模式

```bash
# ceph orch host maintenace exit <hostname> 

```

# OSD 问题排查

## 移除OSD

执行如下命令移除OSD

```bash
# ceph orch osd rm 127 --zap
移除OSD并且擦除底层设备数据
```

移除过程可以通过如下命令查看

```bash
# ceph orch osd rm status
```

## 新加OSD异常处理

通常一个OSD的处理过程涉及到如下几个技术概念

1. Block Device 块设备。通常是我们需要使用的NVME盘
1. Device Mapper Linux内核提供的块设备虚拟化框架
1. PV 物理卷
1. VG 卷组
1. LV 逻辑卷
1. OSD Ceph的基本存储单元

### 无法应用OSD设备

执行如下命令获取到当前可被Ceph部署的块设备

```bash
# ceph orch device ls --refresh
HOST      PATH           TYPE  DEVICE ID                                       SIZE  AVAILABLE  REFRESHED  REJECT REASONS
node01 /dev/nvme0n1   ssd   INTEL_SSDPF2KX153T1_PHAX2420026M15PFGN         13.9T  No         3m ago     Has a FileSystem, Insufficient space (<10 extents) on vgs, LVM detected
node01 /dev/nvme1n1  ssd   INTEL_SSDPF2KX153T1_PHAX243300BU15PFGN         13.9T  No         3m ago     Has a FileSystem, Insufficient space (<10 extents) on vgs, LVM detected
```
这种情况已知的是块设备nvme0n1、nvme1n1上存在文件系统标识，需要先移除其上的文件系统。

通过查询cephadm日志可以获取到相关报错信息

```bash
# ceph log last cephadm
/usr/bin/docker: stderr  stderr: Can't open /dev/nvme0n1 exclusively.  Mounted filesystem?
/usr/bin/docker: stderr  stderr: Can't open /dev/nvme0n1 exclusively.  Mounted filesystem?
```
存在文件系统标识可能的原因是：

1. 该设备之前被格式化过，存在ext4等文件系统。
1. 该设备上存在LVM卷组。
1. 该设备未存在任何文件系统信息和卷组信息，但存在残留的Device Mapper设备。

排查步骤:

找出执行节点osd和lvm设备的映射关系

```bash
# cd /var/lib/ceph/760e0f98-3eb2-11f0-aa31-c7fa5250ca7b/
进入到指定节点的ceph工作目录。这里是node01的ceph工作目录。
760e0f98-3eb2-11f0-aa31-c7fa5250ca7b是当前Ceph集群的UUID。每个集群都不一样。
# ls -l osd.1*|grep -B2 block
osd.113:
total 64
lrwxrwxrwx 1 167 167   93 Jun  5 16:14 block -> /dev/ceph-47b61f6c-5cc6-4d07-9f21-6dc119e76fb7/osd-block-c3f63365-9779-4abd-a407-cbcdaa930238
--
osd.118:
total 64
lrwxrwxrwx 1 167 167   93 Jun  5 16:14 block -> /dev/ceph-528f74e4-16d6-4ea7-988a-829113f4e9f8/osd-block-0ac1a692-03ca-4ecf-8e63-a1f25bc58739
--
以上信息输出了当前节点osd和lvm设备映射关系.
```

找出lvm设备和物理块设备的映射关系

```bash
# lsblk
nvme0n1                                                                                               259:0    0    14T  0 disk
└─ceph--47b61f6c--5cc6--4d07--9f21--6dc119e76fb7-osd--block--c3f63365--9779--4abd--a407--cbcdaa930238 253:1    0    14T  0 lvm
nvme1n1                                                                                               259:1    0    14T  0 disk
└─ceph--a556cf73--f02d--4582--8068--fdf20b06f50c-osd--block--8287b68e--ea1d--4c66--a257--6d598ae20eb2 253:0    0    14T  0 lvm
```

对比上面两个信息这样就能知道需要处理哪个设备了。这里假设需要将nvme0n1设备上的lvm和文件系统抹除。

```bash
# lvmremove /dev/ceph-47b61f6c-5cc6-4d07-9f21-6dc119e76fb7/osd-block-c3f63365-9779-4abd-a407-cbcdaa930238
抹除其上的逻辑卷
# vgremove ceph-47b61f6c-5cc6-4d07-9f21-6dc119e76fb7
抹除其上的卷组
# pvremove /dev/nvme0n1
抹除其上的物理卷
# sgdisk --zap-all /dev/nvme0n1
抹除设备上的分区信息
```

还有一种情况是虽然nvme0n1设备上没有文件系统标识和卷组信息，但存在残留的Device Mapper设备信息。

```bash
# vgs |grep -v VG|awk '{print $1}'|sort >vgs.txt
# ls /dev/ |grep ceph- |sort >dev.txt
# diff -u dev.txt vgs.txt
```
对比后多出来的vg信息就是需要处理的Device Mapper设备.

```bash
# dmsetup remove /dev/mapper/ceph-47b61f6c-5cc6-4d07-9f21-6dc119e76fb7-osd-block-c3f63365-9779-4abd-a407-cbcdaa930238
```

执行完上述步骤后在Ceph集群内执行刷新设备命令查看是否已成功识别。

```bash
# ceph orch device ls --refresh
```	
如果AVAILABLE显示的是Yes表示该设备已经可以被加入到Ceph集群中。