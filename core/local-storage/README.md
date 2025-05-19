# local-storage

> GA

节点本地盘 csi，常用于自身带数据冗余的数据库使用

## 部署

如果需要自定义使用本地路径位置，需要修改 [patch.yaml](./patch.yaml), 注意修改同时 2 处        

```bash
kubectl apply -k .

# 等待所有 pod 就绪
kubectl wait -n local-path-storage --for=condition=ready pod -l app=local-path-provisioner
```

## 测试

```bash
kubectl apply -f tests.yaml
kubectl exec -it local-demo-pod -- bash
kubectl delete -f tests.yaml
```

## 添加额外本地 nvme ssd

例如，添加 /dev/nvme0n1 其挂载路径为 `/opt/local-nvme0`

1. 格式化 `/dev/nvme0n1` 并挂载到 `/opt/local-nvme0`
2. 修改 [patch.yaml](./patch.yaml) 在 `paths: ["/opt/local-path"]` 添加为 `paths: ["/opt/local-path", "/opt/local-nvme0"]`
3. 更新 `kubectl apply -k .` 
4. 部署新的 storageclass `kubectl apply -f local-nvme0.yaml`

## 卸载

```bash
kubectl delete -k.
```