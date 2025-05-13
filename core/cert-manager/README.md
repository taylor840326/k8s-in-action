# [Cert Manager](https://cert-manager.io/docs/)

> GA

## 部署

```sh
helmwave up --build

# 等待所有 pod 就绪
kubectl wait -n cert-manager --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager
```

修改 [certs/clusterissuer.yaml](./certs/clusterissuer.yaml) 中的 email 为自己的邮箱地址, 然后部署证书签发

```bash
kubectl apply -k issuer/
```

## 测试

修改 [tests/ingress.yaml](./tests/ingress.yaml) 中的 `hosts` 和 `host` 为实际 DNS 域名

```sh
# 部署
kubectl apply -k tests

# 访问 https://kuard.play.example.com

# 卸载
kubectl delete -k tests
```

可以通过查看签名过程

```sh
kubectl get ing
kubectl get cert
kubectl get challenges
```

## 卸载

```sh
kubectl delete -k issuer/

helmwave down
```
