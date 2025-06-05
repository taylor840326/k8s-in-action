# Ceph集群监控数据

## 监控数据推送到外部prometheus服务

如果外部prometheus服务开启了remote write 功能，就可以把当前集群的监控数据推送过来统一管理。

本文档前提条件是prometheis的remote write 要求推送的数据是snappy格式。

本文档使用telegraf工具进行监控数据的推送

### telegraf.conf文件

```toml
[global_tags]
  cluster_type="ceph"   #这部分为公共的label信息，后面会加到每个metrics的label中
  cluster_name="bj1"

[agent]
  # 每15秒抓取一次数据
  interval = "15s"    
  round_interval = true
  # 每次推送最多多少metrics
  metric_batch_size = 50000
  #  推送前缓冲池大小
  metric_buffer_limit = 100000
  collection_jitter = "0s"
  # 每30秒往目标prometheus推送一次数据
  flush_interval = "30s"
  flush_jitter = "0s"
  precision = "0s"
  debug = true

[[inputs.prometheus]]
   # 这里面是mgr的地址，通常端口为9283
   urls = ["http://x.x.x.x:9283/metrics"]


[[outputs.http]]
  # 目标prometheus服务的remote write 地址
  url = "http://xxxx:9090/api/v1/write"
  use_system_proxy= false
  timeout = "60s"
  method = "POST"
  username = "xxxx"
  password = "xxxx"
  data_format = "prometheusremotewrite"
  [outputs.http.headers]
    Content-Type = "application/x-protobuf"
    Content-Encoding = "snappy"
    X-Prometheus-Remote-Write-Version = "0.1.0"

[[outputs.prometheus_client]]
  # 可以通过9273端口访问抓取到的metric数据
  listen = ":9273"
```

### 启动telegraf

这里使用docker启动

```bash
docker run --name telegraf \
	--restart always \
	-p 9273:9273 \
	-v `pwd`/telegraf.conf:/etc/telegraf/telegraf.conf:ro \
	-d telegraf:1.32.3
```
注意： 使用1.32.3版本的telegraf，新版本有时间解析错误的问题。
