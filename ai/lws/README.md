# [lws](https://github.com/kubernetes-sigs/lws) 

> Beta

提供轻量级分布式推理服务, 适用于部署 DeepSeek V3/R1 671B 等大模型

## 部署

```bash
helmwave up --build
```

## 示例

* [examples/sglang.yaml](examples/sglang.yaml)
* [examples/vllm.yaml](examples/vllm.yaml)

```bash
# 部署
kubectl apply -f examples/sglang.yaml

# 查询
kubectl get pods 
kubectl get svc 

# 访问, 假设 get svc 结果为 EXTERNAL-IP = 172.16.21.210
curl -X POST http://172.16.21.210/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-ai/DeepSeek-R1",
    "messages": [{"role": "user", "content": "Hello, how are you?"}]
  }'

# 删除
kubectl delete -f examples/sglang.yaml
```

## 卸载

```bash
helmwave delete
```