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