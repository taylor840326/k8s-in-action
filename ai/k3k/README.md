# K3K

## 部署 k3k

```bash
helmwave up --build
```

## 管理集群

```bash
kubectl apply -f bj1k3s01.yaml
kubectl delete -f bj1k3s01.yaml
```

## 卸载

```bash
helmwave down
```

