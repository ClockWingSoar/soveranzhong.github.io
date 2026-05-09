# Prometheus数据采集与指标设计：RED/USE方法论与生产实践指南

## 情境与背景

Prometheus是云原生监控的核心，但很多团队在使用时缺乏系统的指标设计方法论。本指南详细讲解Prometheus的指标模型、RED和USE方法论、四种指标类型的适用场景，以及生产环境中指标设计的最佳实践。

## 一、Prometheus指标模型

### 1.1 数据模型

**Prometheus指标结构**：

```markdown
## Prometheus指标模型

### 数据模型

**指标格式**：

```yaml
metric_name{label1="value1", label2="value2"} value timestamp

# 示例
http_requests_total{method="GET", endpoint="/api/users", status="200"} 12345 1704067200
```

**命名规范**：

```yaml
naming_conventions:
  format: "{namespace}_{name}_{type}"
  
  components:
    namespace: "产品/服务名"
    name: "指标功能描述"
    type: "后缀如total/count/histogram"
    
  examples:
    - "http_requests_total"
    - "kubernetes_pod_status_phase"
    - "process_cpu_seconds_total"
```
```

### 1.2 四种指标类型

**指标类型详解**：

```yaml
metric_types:
  counter:
    description: "只增不减的累计值"
    use_case: "请求总数、错误总数"
    example: "http_requests_total"
    code: |
      # 累加
      http_requests_total{path="/api"} 100
      http_requests_total{path="/api"} 101
      
  gauge:
    description: "可增可减的当前值"
    use_case: "CPU使用率、内存占用"
    example: "cpu_usage_percent"
    code: |
      # 可增可减
      cpu_usage_percent{host="node-1"} 45.2
      cpu_usage_percent{host="node-1"} 50.1
      
  histogram:
    description: "对采样数据分桶统计"
    use_case: "请求延迟、响应大小"
    example: "http_request_duration_seconds"
    buckets: "[0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]"
    
  summary:
    description: "直接计算分位数"
    use_case: "需要精确分位数"
    example: "http_request_duration_seconds"
    quantiles: "[0.5, 0.9, 0.99]"
```

**Histogram vs Summary对比**：

```yaml
histogram_vs_summary:
  histogram:
    advantages:
      - "服务端计算分位数"
      - "可跨服务聚合"
      - "bucket可自定义"
    disadvantages:
      - "客户端开销小"
      - "分位数精度取决于bucket"
      
  summary:
    advantages:
      - "精确分位数"
      - "客户端直接输出"
    disadvantages:
      - "不可跨服务聚合"
      - "客户端开销大"
```

## 二、RED方法论

### 2.1 RED定义

**RED方法论概述**：

```markdown
## RED方法论

### RED定义

**适用场景**：

```yaml
red适用场景:
  description: "用于监控微服务/API等面向用户的服务"
  
  three_metrics:
    Rate:
      definition: "请求速率"
      question: "服务收到多少请求？"
      example: "每秒多少请求"
      
    Errors:
      definition: "错误率"
      question: "有多少请求失败？"
      example: "5xx错误比例"
      
    Duration:
      definition: "响应时间"
      question: "处理请求需要多久？"
      example: "P99延迟"
```

**RED指标示例**：

```yaml
red_metrics_example:
  service: "用户服务 user-service"
  
  Rate:
    - "user_service_requests_total"
    - "label: method, endpoint, status"
    
  Errors:
    - "user_service_errors_total"
    - "label: method, endpoint, error_type"
    
  Duration:
    - "user_service_request_duration_seconds"
    - "type: histogram"
    - "buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2.5]"
```

### 2.2 RED应用示例

**HTTP服务RED指标**：

```go
// Go语言实现RED指标
package main

import (
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promhttp"
    "net/http"
)

var (
    // Rate: 请求总数
    httpRequestsTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "http_requests_total",
            Help: "Total number of HTTP requests",
        },
        []string{"method", "endpoint", "status"},
    )

    // Duration: 请求延迟
    httpRequestDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "http_request_duration_seconds",
            Help:    "HTTP request latency distribution",
            Buckets: []float64{.005, .01, .025, .05, .1, .25, .5, 1, 2.5, 5, 10},
        },
        []string{"method", "endpoint"},
    )
)

func init() {
    prometheus.MustRegister(httpRequestsTotal, httpRequestDuration)
}

func metricsMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        // Rate计数
        httpRequestsTotal.WithLabelValues(r.Method, r.URL.Path, "200").Inc()
        
        // Duration记录
        // ... 记录延迟
    })
}
```

**Python实现**：

```python
# Python实现RED指标
from prometheus_client import Counter, Histogram, generate_latest

# Rate: 请求总数
http_requests = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

# Duration: 延迟分布
http_request_duration = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency',
    ['method', 'endpoint'],
    buckets=[0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]
)

# Errors直接用Counter的status label
```

## 三、USE方法论

### 3.1 USE定义

**USE方法论概述**：

```markdown
## USE方法论

### USE定义

**适用场景**：

```yaml
use适用场景:
  description: "用于监控系统资源如CPU、内存、磁盘、网络"
  
  three_metrics:
    Utilization:
      definition: "资源利用率"
      question: "资源被使用了多少？"
      example: "CPU使用率百分比"
      
    Saturation:
      definition: "资源饱和度"
      question: "资源有多满？"
      example: "CPU队列长度"
      
    Errors:
      definition: "错误数"
      question: "资源出错了吗？"
      example: "网络丢包数"
```

**USE指标示例**：

```yaml
use_metrics_example:
  resource: "CPU"
  
  Utilization:
    - "node_cpu_usage_percent"
    - "或: 1 - idle"
    
  Saturation:
    - "node_load1"  # 1分钟负载
    - "node_load5"  # 5分钟负载
    
  Errors:
    - "node_cpu_errors_total"  # CPU错误（如果有）

use_metrics_example_disk:
  resource: "Disk"
  
  Utilization:
    - "disk_usage_percent"
    
  Saturation:
    - "io_queue_length"
    
  Errors:
    - "disk_read_errors_total"
    - "disk_write_errors_total"
```

### 3.2 常用资源监控指标

**系统资源指标**：

```yaml
system_metrics:
  cpu:
    utilization: "node_cpu_seconds_total{mode=\"idle\"}"
    saturation: "node_load1"
    
  memory:
    utilization: "node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes"
    saturation: "node_vmstat_pgpgin"
    
  disk:
    utilization: "1 - node_filesystem_avail_bytes{fstype!~\"tmpfs|fuse.lxcfs\"} / node_filesystem_size_bytes"
    saturation: "node_disk_io_time_seconds_total"
    
  network:
    utilization: "rate(node_network_receive_bytes_total[5m])"
    saturation: "rate(node_network_receive_drop_total[5m])"
```

**Kubernetes资源指标**：

```yaml
k8s_metrics:
  node:
    cpu_utilization: "kubectl top node"
    memory_utilization: "kubectl top node"
    
  pod:
    cpu_usage: "kubectl top pod"
    memory_usage: "kubectl top pod"
    
  container:
    restart_count: "kube_pod_container_status_restarts_total"
    last_termination_reason: "kube_container_last_termination_reason"
```

## 四、标签设计原则

### 4.1 标签命名规范

**标签设计原则**：

```markdown
## 标签设计原则

### 标签命名规范

**命名规范**：

```yaml
label_naming:
  style: "lowercase with underscores"
  
  examples:
    good: "user_id, request_count, http_status"
    bad: "userId, requestCount, HTTPStatus"
    
  cardinality:
    low_cardinality:
      - "status: 200, 404, 500"
      - "method: GET, POST, PUT, DELETE"
      - "endpoint: /api/users, /api/orders"
      
    high_cardinality:
      - "user_id: 1, 2, 3, ... (10万+)"
      - "request_id: uuid格式"
      - "trace_id: 分布式追踪ID"
```

### 4.2 高基数问题

**高基数标签危害**：

```yaml
high_cardinality_problems:
  storage:
    - "指标数量爆炸"
    - "存储成本剧增"
    example: "userID有100万用户 → 100万时间序列"
    
  query:
    - "查询延迟增加"
    - "内存占用过高"
    
  cardinality_limit:
    prometheus: "每张指标卡片的标签组合数有限制"
    practical: "单指标标签组合应 < 10万"
```

**解决方案**：

```yaml
high_cardinality_solutions:
  avoid_labels:
    - "user_id"
    - "session_id"
    - "request_id"
    - "trace_id"
    
  alternative:
    - "使用trace_id关联外部系统"
    - "用k/v存储原始数据"
    - "用histogram/summary聚合"
    
  good_labels:
    - "service"
    - "endpoint"
    - "method"
    - "status"
    - "job"
    - "instance"
```

## 五、采集配置最佳实践

### 5.1 抓取配置

**scrape_configs配置**：

```yaml
# Prometheus抓取配置
global:
  scrape_interval: 15s      # 抓取间隔
  evaluation_interval: 15s  # 规则评估间隔

scrape_configs:
  - job_name: 'kubernetes-apiservers'
    kubernetes_sd_configs:
    - role: endpoints
    scheme: https
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    relabel_configs:
    - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
      action: keep
      regex: default;kubernetes;https
```

**relabel_configs使用**：

```yaml
relabel_configs_examples:
  # 1. 过滤target
  - source_labels: [__meta_kubernetes_pod_label_app]
    regex: 'my-app'
    action: keep
    
  # 2. 重命名标签
  - source_labels: [__meta_kubernetes_pod_name]
    regex: '(.*)'
    target_label: pod
    replacement: '${1}'
    
  # 3. 添加标签
  - target_label: environment
    replacement: 'production'
    
  # 4. 删除标签
  - regex: '__meta_kubernetes_pod_label_(.*)'
    action: labeldrop
```

### 5.2 采集频率选择

**抓取间隔选择**：

```yaml
scrape_interval_selection:
  10s:
    use_case: "高实时性要求场景"
    example: "核心交易系统"
    pros: "数据精确"
    cons: "资源消耗大"
    
  15s:
    use_case: "一般生产环境"
    example: "普通微服务"
    pros: "平衡之选"
    cons: "中等资源消耗"
    
  30s:
    use_case: "低频变化指标"
    example: "配置指标、日志统计"
    pros: "资源节省"
    cons: "数据粒度粗"
    
  60s+:
    use_case: "业务统计指标"
    example: "每日订单量"
    pros: "极低消耗"
    cons: "无法做实时告警"
```

### 5.3 资源消耗估算

**Prometheus资源需求**：

```yaml
resource_requirements:
  per_target:
    memory: "~1MB"
    cpu: "~0.5m"
    
  estimation:
    formula: |
      Memory ≈ Targets × ScrapeInterval × SamplesPerScrape × 3
      CPU ≈ Targets × ScrapeInterval × 0.1m
      
  example:
    targets: 1000
    scrape_interval: 15s
    memory: "1000 × 15 × 100 × 3 ≈ 450MB"
```

## 六、生产环境最佳实践

### 6.1 指标设计检查清单

**设计原则**：

```yaml
design_checklist:
  naming:
    - "遵循{namespace}_{name}_{type}规范"
    - "使用小写字母和下划线"
    - "包含单位后缀（如_seconds, _bytes）"
    
  labels:
    - "避免高基数标签"
    - "标签命名一致"
    - "控制在5-10个标签以内"
    
  types:
    - "累计值用Counter"
    - "瞬时值用Gauge"
    - "延迟分布用Histogram"
    - "精确分位用Summary"
```

### 6.2 常用指标命名约定

**社区约定**：

```yaml
community_conventions:
  # 请求类指标
  http_requests_total:
    description: "HTTP请求总数"
    labels: "method, handler, status"
    
  http_request_duration_seconds:
    description: "HTTP请求延迟"
    type: "histogram"
    buckets: "[0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]"
    
  # 业务类指标
  orders_total:
    description: "订单总数"
    labels: "status, type"
    
  user_login_total:
    description: "用户登录次数"
    labels: "method, status"
```

### 6.3 Grafana仪表盘设计

**仪表盘最佳实践**：

```yaml
grafana_dashboard:
  panels:
    - "使用变量实现动态筛选"
    - "统一时间范围"
    - "适当使用模板"
    
  variables:
    - name: "env"
      query: "label_values(http_requests_total, env)"
      
    - name: "service"
      query: "label_values(http_requests_total{env=\"$env\"}, service)"
```

### 6.4 告警规则设计

**告警设计原则**：

```yaml
alert_design:
  severity:
    critical: "服务不可用"
    warning: "性能降级"
    info: "需要关注"
    
  for_duration:
    critical: "5m (5分钟持续)"
    warning: "10m (10分钟持续)"
    
  thresholds:
    error_rate:
      critical: "> 1%"
      warning: "> 0.1%"
      
    latency_p99:
      critical: "> 2s"
      warning: "> 1s"
```

**告警规则示例**：

```yaml
groups:
- name: service-alerts
  rules:
  - alert: HighErrorRate
    expr: |
      sum(rate(http_requests_total{status=~"5.."}[5m])) /
      sum(rate(http_requests_total[5m])) > 0.01
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "服务错误率过高"
      description: "错误率: {{ $value | humanizePercent }}"
```

## 七、面试1分钟精简版（直接背）

**完整版**：

Prometheus指标设计：1. 方法论：RED用于服务监控（Rate请求速率、Errors错误率、Duration响应时间），USE用于资源监控（Utilization利用率、Saturation饱和度、Errors错误）；2. 指标类型：Counter用于累计值、Gauge用于瞬时值、Histogram用于延迟分布、Summary用于精确分位数；3. 标签设计：避免高基数标签（userID/requestID），控制在5-10个标签；4. 采集频率：一般15秒，高实时要求10秒；5. 命名规范：{namespace}_{name}_{type}，如http_requests_total_seconds。生产实践：Histogram优于Summary（可聚合）。

**30秒超短版**：

指标设计用RED（服务）和USE（资源），Counter累计Gauge瞬时，Histogram分布Summary分位，避免高基数标签，采集间隔15秒。

## 八、总结

### 8.1 方法论对比

```yaml
methodology_comparison:
  RED:
    适用: "微服务/API"
    指标: "Rate/Errors/Duration"
    
  USE:
    适用: "系统资源"
    指标: "Utilization/Saturation/Errors"
```

### 8.2 指标类型选择

```yaml
type_selection:
  counter:
    选: "需要累计的场景"
    
  gauge:
    选: "需要显示当前值的场景"
    
  histogram:
    选: "需要延迟分布且可聚合"
    
  summary:
    选: "需要精确分位数且不需聚合"
```

### 8.3 记忆口诀

```
指标设计有方法，RED看服务USE看资源，
Counter累计Gauge瞬，Histogram分布Summary分位，
标签设计要精简，高基数标签要避免，
采集间隔十五秒，命名规范记心间。
```

> **参考链接**：[SRE运维面试题全解析：从理论到实践（第二部分）]({% post_url 2026-04-15-sre-interview-questions-part2 %})