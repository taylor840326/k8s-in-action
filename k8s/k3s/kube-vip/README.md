# kube-vip

> Alpha

用于提供 k3s apiserver 负载均衡与高可用

## 部署

在部署完第一台 k3s 后, 修改 [daemonset.yaml](daemonset.yaml) 中的:
* `vip_interface` 为 vip 所在 interface
* `address` 为 vip 地址, 从网络管理员申请获取

```bash
kubectl apply -k . 
```

> 因为从第二台 k3s join 指定 --server 地址为此 vip 时其必须存在

## 排错

* vip 基于 ARP 被动查询和 gARP 变化主动更新
* 可以 `ssh <vip>` 查看所在节点
* 高可用和负载均衡基于 ipvs 实现
* 在 vip 所在节点执行 `ipvsadm -ln` 查看 ipvs 规则, 执行 `ipvsadm -lnc` 查看 ipvs 连接
* 当节点或者其上 apiserver 服务不可用时, kube-vip 会把节点所在 ip 从 ipvs 规则中移除, 并把 vip 分配给其他节点
* 当节点恢复时, kube-vip 会重新把节点所在 ip 加入 ipvs 规则, 并把 vip 分配给节点