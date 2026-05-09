# Prometheus副本重复采集：数据去重与冗余处理最佳实践

## 情境与背景

Prometheus高可用部署和联邦集群架构中，副本重复采集是常见问题。本指南详细讲解数据冗余的成因、影响以及各种去重方案，包括Thanos Query去重、PromQL聚合、Promtool修复等最佳实践。

## 一、数据重复问题概述

### 1.1 问题成因分析

**常见重复场景**：

```markdown
## 数据重复问题概述

### 问题成因分析

**高可用副本重复**：

```yaml
ha_duplication:
  scenario: "Prometheus双副本部署"
  cause: "两个副本都抓取相同target"
  example: |
    Prometheus-1: 抓取 job="api-server" instance="10.0.0.1:9090"
    Prometheus-2: 抓取 job="api-server" instance="10.0.0.1:9090"
  result: "同一指标出现两次，数据点重复
```

**联邦集群重复**：

```yaml
federation_duplication:
  scenario: "多数据中心联邦"
  cause: "各中心Prometheus抓取相同全局指标"
  example: |
    DC1-Prometheus: 抓取 kubernetes_nodes指标
    DC2-Prometheus: 抓取 kubernetes_nodes指标
  result: " federation汇聚后数据重复
```

**数据回填重复**：

```yaml
backfill_duplication:
  scenario: "历史数据回填"
  cause: "同一时间段回填多次"
  result: "同时间点多个数据值
```

**抓取配置重复**：

```yaml
scrape_duplication:
  scenario: "配置错误"
  cause: "同一job配置了多个scrape地址"
  result: "重复抓取同一目标
```
```

### 1.2 问题影响

**负面影响**：

```yaml
negative_impacts:
  storage:
    - "存储空间浪费"
    - "数据膨胀"
    
  query:
    - "查询结果翻倍"
    - "grafana图表数据翻倍"
    - "聚合计算错误"
    
  alerting:
    - "告警重复触发"
    - "误判风险"
    
  performance:
    - "查询延迟增加"
    - "内存占用增加"
```
```

## 二、replica标签去重方案

### 2.1 Thanos Query去重原理

**去重机制**：

```markdown
## replica标签去重方案

### Thanos Query去重原理

**去重流程图**：

```mermaid
flowchart LR
    A["Prometheus-1\n{job=\"api\", replica=\"1\"}"] --> B["Thanos Query"]
    A2["Prometheus-2\n{job=\"api\", replica=\"2\"}"] --> B
    B --> C["去重逻辑"]
    C --> D["{job=\"api\"}\n单条数据"]
    
    style C fill:#64b5f6
```

**去重规则**：

```yaml
deduplication_rules:
  principle: "相同指标名称 + 相同标签 + 不同replica → 合并为一条"
  
  merge_strategy:
    - "选择最新时间戳的值"
    - "或按时间窗口聚合"
    
  configurable:
    - "deduplication_factor参数"
    - "默认2，即2分钟内的数据视为同一条"
```
```

### 2.2 Prometheus配置

**external_labels配置**：

```yaml
# Prometheus启动参数
args:
  - '--storage.tsdb.path=/prometheus'
  - '--web.enable-lifecycle'
  - '--global.external_labels.replica=$(POD_NAME)'
  - '--global.external_labels.cluster=$(CLUSTER_NAME)'

# 环境变量
env:
  - name: POD_NAME
    valueFrom:
      fieldRef:
        fieldPath: metadata.name
  - name: CLUSTER_NAME
    value: "prod-cluster"
```

**StatefulSet配置**：

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: prometheus
spec:
  serviceName: prometheus
  replicas: 2
  selector:
    matchLabels:
      app: prometheus
  template:
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:latest
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        args:
        - '--storage.tsdb.path=/prometheus'
        - '--global.external_labels.replica=$(POD_NAME)'
        - '--web.enable-lifecycle'
```

**Prometheus配置YAML**：

```yaml
global:
  external_labels:
    cluster: 'prod'
    env: 'production'
```

### 2.3 Thanos Query配置

**Query去重配置**：

```yaml
# Thanos Query配置
apiVersion: apps/v1
kind: Deployment
metadata:
  name: thanos-query
spec:
  selector:
    matchLabels:
      app: thanos-query
  template:
    spec:
      containers:
      - name: query
        image: quay.io/thanos/thanos:v0.32.0
        args:
        - query
        # 指定用于去重的标签
        - '--query.replica-label=replica'
        - '--query.replica-label=prometheus'
        # 去重因子（时间窗口）
        - '--store.sd-dns-resolver=miekgdns'
```

**Grafana数据源配置**：

```yaml
# Grafana连接Thanos
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-datasources
data:
  datasources.yaml: |
    apiVersion: 1
    datasources:
    - name: Thanos
      type: prometheus
      access: proxy
      url: http://thanos-query:10902
      jsonData:
        timeInterval: 15s
        httpMethod: POST
```

## 三、PromQL去重方案

### 3.1 聚合函数去重

**常用去重PromQL**：

```promql
# 使用sum聚合去重
sum by (job, instance) (up{job="api-server"})

# 使用avg聚合去重
avg by (job, instance) (up{job="api-server"})

# 使用group_left保留左侧标签
sum by (job) (rate(http_requests_total[5m])) * on(job) group_left(instance) up{job="api-server"}
```

**场景示例**：

```yaml
dedup_queries:
  simple_sum:
    query: "sum by (job) (up)"
    use_case: "统计每个job的实例数"
    
  rate_with_labels:
    query: "sum by (job, handler) (rate(http_requests_total[5m]))"
    use_case: "按job和handler统计QPS"
    
  instance_info:
    query: |
      sum by (instance) (up{job="node-exporter"})
      * on(instance) group_left(instance, arch)
      node_cpu_info
    use_case: "合并实例信息和CPU信息"
```
```

### 3.2 label_replace去重

**标签处理**：

```promql
# 移除replica标签
label_replace(up, "replica", "", "replica", ".*")

# 重命名标签
label_replace(up, "prometheus", "replica", "replica", "(.*)")

# 使用标签填充默认值
label_replace(up{replica=""}, "replica", "default", "replica", "^$")
```

**完整去重查询模板**：

```promql
# 标准去重模板
sum by (job, instance, __name__) (
  rate(http_requests_total[5m])
)

# 带标签保留的去重
sum by (job, instance) (
  rate(http_requests_total[5m])
) > 0
```
```

## 四、Promtool修复方案

### 4.1 数据检查

**检查重复数据**：

```bash
# 使用promtool检查TSDB数据
promtool tsdb dump /prometheus/data

# 检查指定时间范围的数据
promtool tsdb analyze /prometheus/data --from=2024-01-01T00:00:00Z --to=2024-01-02T00:00:00Z

# 查看数据块信息
ls -la /prometheus/data/01*/chunks/
```

**识别重复指标**：

```bash
# 导出指标分析
curl -s http://localhost:9090/api/v1/label/__name__/values | jq '.data[]' | grep -c "http_requests"

# 检查同一时间点的数据
curl -s 'http://localhost:9090/api/v1/query?query=up{job="api-server"}&time=1704067200' | jq
```

### 4.2 数据修复

**清理重复数据**：

```bash
# 创建快照备份
curl -X POST http://localhost:9090/api/v1/admin/tsdb/snapshot

# 使用promtool验证数据
promtool tsdb verify /prometheus/data

# 修复WAL
promtool tsdb check /prometheus/wal --repair
```

**重写数据块**：

```python
#!/usr/bin/env python3
# dedup_blocks.py - 清理重复数据块

import os
import struct
from typing import List, Tuple

def find_duplicate_samples(block_path: str) -> List[Tuple[int, str]]:
    """查找重复的样本"""
    duplicates = []
    # 实现查找逻辑
    return duplicates

def remove_duplicate_samples(block_path: str, duplicates: List[Tuple[int, str]]):
    """删除重复样本"""
    # 实现删除逻辑
    pass

if __name__ == "__main__":
    block_path = "/prometheus/data/01BX9Z5NZ..."
    duplicates = find_duplicate_samples(block_path)
    if duplicates:
        remove_duplicate_samples(block_path, duplicates)
        print(f"Removed {len(duplicates)} duplicate samples")
```

## 五、dedup插件方案

### 5.1 插件原理

**dedup机制**：

```yaml
dedup_plugin:
  description: "Prometheus官方dedup插件"
  
  working_principle:
    - "读取原始样本流"
    - "根据timestamp和label去重"
    - "输出去重后的样本"
    
  configuration:
    - "dedup.interval: 去重时间窗口"
    - "dedup.labels: 去重标签列表"
```
```

### 5.2 部署配置

**插件配置**：

```yaml
# 使用prometheus/dedup作为中间件
# upstream: Prometheus scrapers
# downstream: Storage

# 部署架构
# [Prometheus-1] → [dedup] → [Remote Write]
# [Prometheus-2] → [dedup] → [Remote Write]

# dedup配置
dedup:
  interval: "2m"
  labels:
    - "job"
    - "instance"
    - "__name__"
```

## 六、生产环境最佳实践

### 6.1 配置检查清单

**防止重复采集**：

```yaml
prevention_checklist:
  scrape:
    - "检查scrape_configs无重复"
    - "确认target唯一性"
    - "验证job名称不冲突"
    
  ha:
    - "配置external_labels.replica"
    - "Thanos Query配置replica-label"
    
  federation:
    - "明确各中心抓取范围"
    - "使用honor_labels避免标签冲突"
```
```

### 6.2 监控去重状态

**去重监控指标**：

```yaml
deduplication_monitoring:
  thanos_query:
    - "thanos_query_duplicates_detected"
    - "thanos_query_merged_samples_total"
    
  prometheus:
    - "prometheus_target_scrapes_sample_duplicate_to_total"
    - "prometheus_target_scrapes_exceeded_target_limit"
```

**告警规则**：

```yaml
groups:
- name: deduplication
  rules:
  - alert: HighDuplicationRate
    expr: |
      rate(prometheus_target_scrapes_sample_duplicate_to_total[5m]) / rate(prometheus_target_scrapes_sample_length_total[5m]) > 0.1
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "数据重复率过高"
      description: "重复样本占比超过10%"
```
```

### 6.3 容量影响评估

**存储节省估算**：

```yaml
storage_savings:
  with_dedup:
    original: "100GB/天"
    after_dedup: "50GB/天"
    savings: "50%"
    
  calculation:
    - "副本数 × 单副本数据"
    - "去重因子 = 副本数"
    
  example:
    ha_replicas: 2
    daily_data: 50GB
    with_dedup: "50GB"
    without_dedup: "100GB"
```

## 七、面试1分钟精简版（直接背）

**完整版**：

副本重复采集去重方案：1. 原因分析：高可用多副本同时抓取、联邦集群数据重叠、回填重复、数据配置错误；2. Thanos去重：配置--global.external_labels.replica=$(HOSTNAME)，Thanos Query设置--query.replica-label=replica实现自动去重；3. PromQL聚合：使用sum by()或avg by()按标签聚合；4. dedup插件：作为中间件在Prometheus和存储之间做后处理。生产建议：Thanos架构下使用replica标签去重，自建架构使用PromQL聚合或dedup插件。

**30秒超短版**：

数据去重：配置external_labels的replica标签，Thanos Query自动根据replica去重，PromQL用sum聚合也可以去重。

## 八、总结

### 8.1 方案对比

```yaml
solution_comparison:
  replica_label:
   适用: "Thanos架构"
    复杂度: "低"
    效果: "自动"
    
  promql_aggregation:
    适用: "临时查询"
    复杂度: "低"
    效果: "手动"
    
  promtool:
    适用: "离线修复"
    复杂度: "中"
    效果: "彻底"
    
  dedup_plugin:
    适用: "自建系统"
    复杂度: "高"
    效果: "自动"
```

### 8.2 最佳实践清单

```yaml
best_practices_checklist:
  config:
    - "配置external_labels.replica"
    - "Thanos Query设置replica-label"
    - "避免重复scrape_configs"
    
  monitoring:
    - "监控重复率指标"
    - "配置重复率告警"
    
  query:
    - "Grafana使用去重数据源"
    - "重要指标使用聚合查询"
```

### 8.3 记忆口诀

```
副本重复采集，replica标签是核心，
Thanos Query自动去，PromQL聚合也行，
Promtool离线修，dedup插件中间层，
监控重复率指标，生产环境保数据准确。
```

> **参考链接**：[SRE运维面试题全解析：从理论到实践（第二部分）]({% post_url 2026-04-15-sre-interview-questions-part2 %})