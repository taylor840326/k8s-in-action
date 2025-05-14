# [nfd](https://github.com/kubernetes-sigs/node-feature-discovery)

检测硬件特性并相应地标记节点，以便用于调度决策。 通常被 gpu-operator 和 network-operator 等工具使用。

## 部署

```bash
helmwave up --build

# 等待 Pod 启动
kubectl wait --namespace nfd \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=nfd \
  --timeout=120s
```

修改 [instance-type.yaml](./instance-type.yaml) 以符合实际情况, 然后部署为节点打上额外 label

```bash
kubectl apply -k .
```

## 验证

```bash
kubectl get node --show-labels
```

观察节点是否设置正确 label

## 卸载

```bash
kubectl delete -k .

helmwave down
```
