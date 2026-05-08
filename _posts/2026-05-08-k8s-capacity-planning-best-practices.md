# K8S容量规划与流量管理：Pod密度与访问量分析

## 情境与背景

Kubernetes容量规划和流量管理是生产环境稳定运行的关键。作为高级DevOps/SRE工程师，需要掌握Pod密度规划和流量管理策略。本文从DevOps/SRE视角，深入讲解K8S容量规划和流量管理的最佳实践。

## 一、Pod密度规划

### 1.1 节点规格选择

**常用节点规格**：

| 规格 | CPU | 内存 | 适用场景 |
|:----:|:---:|:----:|----------|
| 小型 | 8核 | 16GB | 开发测试 |
| 中型 | 16核 | 64GB | 通用服务 |
| 大型 | 32核 | 128GB | 生产环境 |
| 超大型 | 64核 | 256GB | 大数据/AI |

**选择原则**：
- 根据Pod资源需求选择
- 考虑成本和性能平衡
- 预留20%资源作为缓冲

### 1.2 Pod密度计算

**计算公式**：
```
单节点Pod数 ≈ (节点可用资源) / (单Pod资源需求)
```

**示例计算**：
```yaml
# 节点规格
node:
  cpu: "32 cores"
  memory: "128GB"
  
# 单Pod资源需求
pod:
  cpu_request: "500m"
  memory_request: "512Mi"
  
# 可用资源（预留20%）
available:
  cpu: "25.6 cores"
  memory: "102.4GB"
  
# 计算结果
max_pods:
  by_cpu: 51
  by_memory: 200
  actual: 30-50  # 取保守值
```

### 1.3 Pod密度影响因素

**影响因素**：

| 因素 | 说明 | 影响 |
|:----:|------|------|
| **Pod资源配置** | CPU/内存请求 | 直接影响密度 |
| **节点规格** | CPU/内存总量 | 基础限制 |
| **系统开销** | K8S组件占用 | 约10%资源 |
| **网络带宽** | Pod网络通信 | 高密度可能受限 |
| **存储IO** | Pod存储访问 | 高密度可能受限 |

## 二、资源配置最佳实践

### 2.1 Pod资源配置

**配置示例**：
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
    - name: app
      image: my-app:latest
      resources:
        requests:
          cpu: "500m"
          memory: "512Mi"
        limits:
          cpu: "1"
          memory: "1Gi"
```

**配置原则**：
- requests设置为常规运行所需资源
- limits设置为峰值资源上限
- requests与limits比例合理（通常1:2）

### 2.2 资源预留

**预留配置**：
```yaml
# Kubelet配置
kubelet:
  reservedResources:
    cpu: "2"
    memory: "4Gi"
    ephemeral-storage: "10Gi"
```

**预留目的**：
- 保障K8S系统组件运行
- 防止资源耗尽导致节点不可用
- 预留应急资源

### 2.3 QoS等级

**QoS配置**：

| QoS等级 | 说明 | 资源保障 | 驱逐策略 |
|:-------:|------|:--------:|----------|
| **Guaranteed** | requests=limits | 最高 | 最后驱逐 |
| **Burstable** | requests<limits | 中等 | 中间驱逐 |
| **BestEffort** | 无requests/limits | 最低 | 优先驱逐 |

**配置示例**：
```yaml
# Guaranteed QoS
resources:
  requests:
    cpu: "1"
    memory: "1Gi"
  limits:
    cpu: "1"
    memory: "1Gi"
```

## 三、流量管理

### 3.1 QPS计算

**计算公式**：
```
QPS = 并发数 / 平均响应时间
```

**示例**：
```yaml
# 流量参数
traffic:
  concurrency: 10000  # 并发连接数
  avg_response_time: "100ms"  # 平均响应时间
  
# 计算QPS
qps: 100000  # 10万QPS
```

### 3.2 并发连接管理

**连接管理配置**：
```yaml
# 连接池配置
connection_pool:
  http:
    max_connections: 1000
    max_idle_connections: 100
    connection_timeout: "30s"
    idle_timeout: "60s"
  
  grpc:
    max_concurrent_streams: 100
    keepalive_time: "2h"
```

### 3.3 流量控制策略

**限流配置**：
```yaml
# 限流配置
rate_limiting:
  enabled: true
  qps_limit: 100000
  burst_limit: 10000
  
  per_user:
    enabled: true
    limit: 1000
```

**熔断配置**：
```yaml
# 熔断配置
circuit_breaker:
  enabled: true
  failure_threshold: 50
  success_threshold: 10
  timeout: "30s"
```

## 四、负载均衡策略

### 4.1 Service配置

**配置示例**：
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: ClusterIP
  selector:
    app: my-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
  sessionAffinity: None
```

### 4.2 负载均衡算法

**算法对比**：

| 算法 | 说明 | 适用场景 |
|:----:|------|----------|
| **RoundRobin** | 轮询 | 通用场景 |
| **LeastConnections** | 最少连接 | 长连接场景 |
| **IPHash** | IP哈希 | 会话保持 |
| **Random** | 随机 | 简单场景 |

### 4.3 Ingress配置

**配置示例**：
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
    - hosts:
        - my-app.example.com
      secretName: my-tls-secret
  rules:
    - host: my-app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-service
                port:
                  number: 80
```

## 五、监控与告警

### 5.1 容量监控

**监控指标**：

| 指标 | 说明 | 阈值 |
|:----:|------|------|
| `node_cpu_usage` | 节点CPU使用率 | <70% |
| `node_memory_usage` | 节点内存使用率 | <75% |
| `node_pod_count` | 节点Pod数量 | <max_pods * 80% |
| `pod_resource_usage` | Pod资源使用率 | <limits * 80% |

### 5.2 流量监控

**监控指标**：

| 指标 | 说明 | 阈值 |
|:----:|------|------|
| `requests_per_second` | QPS | 根据业务设定 |
| `response_time` | 响应时间 | <500ms |
| `error_rate` | 错误率 | <1% |
| `connection_count` | 并发连接数 | <max_connections |

### 5.3 告警规则

**配置示例**：
```yaml
# 容量告警
groups:
  - name: capacity-alerts
    rules:
      - alert: NodeCPUHigh
        expr: node_cpu_usage > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Node CPU usage is high"
      
      - alert: NodeMemoryHigh
        expr: node_memory_usage > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Node memory usage is high"
```

## 六、实战案例分析

### 6.1 案例1：容量规划

**场景描述**：
- 预期Pod数：1000个
- 单Pod资源：500m CPU / 512Mi内存
- 节点规格：32核 / 128GB

**计算过程**：
```yaml
# 计算节点数
node_count: 20  # 1000 Pod / 50 Pod per node

# 资源预留
reserved:
  cpu: 40 cores  # 20 nodes * 2 cores
  memory: 80GB   # 20 nodes * 4GB
```

### 6.2 案例2：流量管理

**场景描述**：
- 日均QPS：100万
- 峰值QPS：200万
- 平均响应时间：100ms

**配置方案**：
```yaml
# HPA配置
hpa:
  min_replicas: 10
  max_replicas: 100
  target_cpu: 70
  
# 限流配置
rate_limiting:
  qps_limit: 200000
  burst_limit: 50000
```

## 七、面试1分钟精简版（直接背）

**完整版**：

我们生产环境的节点规格是32核CPU、128GB内存，单个节点通常运行30-50个Pod，具体数量取决于Pod的资源配置，平均每个Pod占用约500m CPU和512Mi内存。平台访问量方面，客户系统日均QPS达到百万级，核心服务并发连接数在万级。我们通过HPA自动扩缩容和Cluster Autoscaler节点扩容来应对流量变化，确保系统稳定运行。

**30秒超短版**：

生产节点32核/128GB，单节点运行30-50个Pod，平均每个Pod 500m CPU/512Mi内存。平台日均QPS百万级，并发万级，通过HPA和Cluster Autoscaler应对流量变化。

## 八、总结

### 8.1 核心要点

1. **Pod密度**：根据节点规格和Pod资源需求规划，通常30-50个/节点
2. **资源配置**：合理设置requests和limits，选择合适的QoS等级
3. **流量管理**：计算QPS和并发数，配置限流和熔断
4. **监控告警**：建立容量和流量监控体系

### 8.2 规划原则

| 原则 | 说明 |
|:----:|------|
| **预留缓冲** | 预留20%资源应对突发 |
| **弹性伸缩** | 根据负载动态调整 |
| **分级保障** | 核心服务优先保障 |
| **持续优化** | 根据实际情况调整配置 |

### 8.3 记忆口诀

```
节点Pod数看配置，30-50是常规，
资源预留要合理，QoS等级要设置，
访问量看QPS，并发连接要控制，
监控告警要完善，弹性伸缩保稳定。
```

> **参考链接**：[SRE运维面试题全解析：从理论到实践（第二部分）]({% post_url 2026-04-15-sre-interview-questions-part2 %})