# K8S监控采集与HPA配置：弹性伸缩实战指南

## 情境与背景

监控数据采集频率和HPA（Horizontal Pod Autoscaler）配置是Kubernetes弹性伸缩的核心要素。作为高级DevOps/SRE工程师，必须掌握合理的采集策略和HPA配置方法。本文从DevOps/SRE视角，详细讲解监控采集频率设置和HPA配置的最佳实践。

## 一、监控数据采集频率

### 1.1 采集频率配置

**配置示例**：
```yaml
# Prometheus采集配置
scrape_configs:
  - job_name: "kubernetes-nodes"
    scrape_interval: "15s"
    scrape_timeout: "10s"
    static_configs:
      - targets: ["node-exporter:9100"]
  
  - job_name: "kubernetes-pods"
    scrape_interval: "30s"
    scrape_timeout: "20s"
    kubernetes_sd_configs:
      - role: pod
  
  - job_name: "custom-metrics"
    scrape_interval: "10s"
    scrape_timeout: "5s"
    static_configs:
      - targets: ["api-service:8080"]
```

### 1.2 采集频率策略

**策略配置**：
```yaml
# 采集频率策略
scrape_strategy:
  critical:
    interval: "10s"
    timeout: "5s"
    description: "关键业务指标"
  
  important:
    interval: "15s"
    timeout: "10s"
    description: "核心服务指标"
  
  normal:
    interval: "30s"
    timeout: "20s"
    description: "常规服务指标"
  
  low:
    interval: "60s"
    timeout: "30s"
    description: "非关键指标"
```

### 1.3 指标分类与频率

**指标分类**：

| 指标类型 | 采集频率 | 说明 |
|:--------:|:--------:|------|
| **节点指标** | 15-30s | CPU、内存、磁盘、网络 |
| **K8S状态指标** | 30-60s | Pod状态、Deployment状态 |
| **应用业务指标** | 10-15s | QPS、延迟、错误率 |
| **日志指标** | 60s | 日志计数、错误数 |
| **自定义指标** | 10-30s | 根据业务重要性 |

## 二、HPA配置详解

### 2.1 CPU HPA配置

**配置示例**：
```yaml
# CPU HPA配置
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: cpu-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

### 2.2 内存HPA配置

**配置示例**：
```yaml
# 内存HPA配置
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: memory-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 75
```

### 2.3 混合指标HPA配置

**配置示例**：
```yaml
# 混合指标HPA配置
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: mixed-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 75
```

### 2.4 自定义指标HPA配置

**配置示例**：
```yaml
# 自定义指标HPA配置
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: custom-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Pods
      pods:
        metric:
          name: http_requests_per_second
        target:
          type: AverageValue
          averageValue: "100"
```

## 三、HPA参数调优

### 3.1 扩缩容策略

**策略配置**：
```yaml
# 扩缩容策略
behavior:
  scaleUp:
    stabilizationWindowSeconds: 30
    policies:
      - type: Percent
        value: 100
        periodSeconds: 60
      - type: Pods
        value: 4
        periodSeconds: 60
    selectPolicy: Max
  
  scaleDown:
    stabilizationWindowSeconds: 600
    policies:
      - type: Percent
        value: 10
        periodSeconds: 60
      - type: Pods
        value: 1
        periodSeconds: 60
    selectPolicy: Min
```

### 3.2 参数说明

**参数详解**：

| 参数 | 说明 | 建议值 |
|:----:|------|--------|
| **minReplicas** | 最小副本数 | 2+（保证高可用） |
| **maxReplicas** | 最大副本数 | 根据业务峰值 |
| **stabilizationWindowSeconds** | 稳定窗口 | 扩容30-60s，缩容300-600s |
| **scaleUp policies** | 扩容策略 | 百分比或固定数量 |
| **scaleDown policies** | 缩容策略 | 保守策略 |

## 四、监控与HPA集成

### 4.1 指标采集与HPA

**集成架构**：
```yaml
# 监控与HPA集成
integration:
  prometheus:
    service: "prometheus-service"
    port: 9090
  
  metrics_server:
    enabled: true
    resources:
      requests:
        cpu: "100m"
        memory: "200Mi"
  
  custom_metrics:
    api_server:
      enabled: true
      service: "custom-metrics-apiserver"
```

### 4.2 Metrics Server配置

**配置示例**：
```yaml
# Metrics Server配置
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metrics-server
  namespace: kube-system
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metrics-server
  namespace: kube-system
spec:
  replicas: 1
  selector:
    matchLabels:
      k8s-app: metrics-server
  template:
    metadata:
      labels:
        k8s-app: metrics-server
    spec:
      serviceAccountName: metrics-server
      containers:
        - name: metrics-server
          image: k8s.gcr.io/metrics-server/metrics-server:v0.6.4
          args:
            - "--cert-dir=/tmp"
            - "--secure-port=4443"
            - "--kubelet-preferred-address-types=InternalIP"
```

## 五、最佳实践

### 5.1 采集频率优化

**优化策略**：
```yaml
# 采集频率优化策略
optimization:
  reduce_scrape_load:
    - "合并相似的采集任务"
    - "使用标签选择器过滤"
    - "设置合理的采集超时"
  
  prioritize_critical:
    - "关键指标高频采集"
    - "非关键指标低频采集"
    - "按需采集（基于标签）"
```

### 5.2 HPA配置最佳实践

**配置建议**：
```yaml
# HPA最佳实践
hpa_best_practices:
  min_replicas:
    recommendation: "至少2个副本"
    reason: "保证高可用"
  
  max_replicas:
    recommendation: "根据业务峰值计算"
    formula: "峰值QPS / 单Pod处理能力"
  
  target_utilization:
    cpu: "60-80%"
    memory: "70-85%"
  
  scale_down_delay:
    recommendation: "至少5分钟"
    reason: "避免频繁扩缩容"
```

### 5.3 避免的坑

**常见问题**：

| 问题 | 原因 | 解决方案 |
|:----:|------|----------|
| **采集频率过高** | 资源消耗大 | 根据指标重要性分级 |
| **HPA震荡** | 阈值设置不合理 | 调整稳定窗口和策略 |
| **扩缩容不及时** | 指标延迟 | 优化采集频率 |
| **资源不足** | 集群资源有限 | 配置Cluster Autoscaler |

## 六、实战案例分析

### 6.1 案例1：高频采集优化

**场景描述**：
- 监控资源消耗过大
- 需要优化采集频率

**优化方案**：
```yaml
# 优化后的采集配置
scrape_configs:
  - job_name: "critical-services"
    scrape_interval: "10s"
    static_configs:
      - targets: ["api-gateway:8080"]
  
  - job_name: "normal-services"
    scrape_interval: "30s"
    kubernetes_sd_configs:
      - role: pod
        namespaces:
          names: ["default"]
  
  - job_name: "monitoring-services"
    scrape_interval: "60s"
    static_configs:
      - targets: ["node-exporter:9100"]
```

### 6.2 案例2：HPA配置优化

**场景描述**：
- HPA频繁扩缩容
- 需要优化配置

**优化方案**：
```yaml
# 优化后的HPA配置
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: optimized-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 3
  maxReplicas: 15
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 75
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
        - type: Percent
          value: 50
          periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 900
      policies:
        - type: Percent
          value: 5
          periodSeconds: 300
```

## 七、面试1分钟精简版（直接背）

**完整版**：

监控数据采集频率根据指标类型有所不同，Prometheus默认是15秒，关键业务指标可以配置为10-15秒，非关键指标可以设为30-60秒。HPA配置方面，我们配置基于CPU和内存的自动扩缩容，目标阈值分别设为70%和75%，最小副本数设置为2保证高可用，最大副本数根据业务峰值设置。同时支持基于自定义指标的HPA，如QPS、请求延迟等。

**30秒超短版**：

采集频率15-60秒，关键指标高频。HPA配置CPU/内存指标，最小2副本，阈值70-75%。

## 八、总结

### 8.1 核心要点

1. **采集频率**：根据指标重要性分级设置（10s-60s）
2. **HPA配置**：CPU目标60-80%，内存目标70-85%
3. **最小副本**：至少2个保证高可用
4. **最大副本**：根据业务峰值计算
5. **扩缩容策略**：扩容激进，缩容保守

### 8.2 配置原则

| 原则 | 说明 |
|:----:|------|
| **分级采集** | 关键指标高频，非关键指标低频 |
| **高可用优先** | 最小副本数>=2 |
| **避免震荡** | 设置合理的稳定窗口 |
| **弹性伸缩** | 结合Cluster Autoscaler |

### 8.3 记忆口诀

```
采集频率分等级，15到60秒合适，
HPA配置看指标，CPU内存双保障，
最小副本要保证，最大副本有上限，
扩容激进缩容稳，弹性伸缩保稳定。
```

> **参考链接**：[SRE运维面试题全解析：从理论到实践（第二部分）]({% post_url 2026-04-15-sre-interview-questions-part2 %})