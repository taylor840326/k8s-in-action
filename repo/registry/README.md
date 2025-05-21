# Docker Registry

> Alpha

轻量级镜像仓库，用于存储镜像，并提供镜像的拉取和推送功能。

## 部署

修改 [values.yml](values.yml) 文件，配置 ingress 和 persistence 信息。

```sh
helmwave up --build
```

## 卸载

```sh
helmwave down
```
