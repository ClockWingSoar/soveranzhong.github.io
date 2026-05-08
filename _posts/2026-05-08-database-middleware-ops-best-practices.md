# K8S平台数据库与中间件运维：生产环境实战指南

## 情境与背景

现代K8S平台通常依赖多种数据库和中间件来支撑业务运转。作为高级DevOps/SRE工程师，需要全面掌握各类数据库和中间件的选型、架构设计和运维能力。本文从DevOps/SRE视角，详细讲解K8S平台上数据库与中间件的运维最佳实践。

## 一、数据库与中间件概览

### 1.1 技术栈分类

**组件分类**：

| 类型 | 组件 | 用途 | 部署方式 |
|:----:|------|------|----------|
| **关系型** | MySQL/PostgreSQL | 业务数据存储 | 物理机/VM |
| **NoSQL** | MongoDB | 文档存储 | K8S |
| **缓存** | Redis Cluster | 缓存/会话 | K8S |
| **消息队列** | Kafka/RocketMQ | 异步通信 | K8S |
| **搜索** | Elasticsearch | 日志/搜索 | K8S |
| **对象存储** | MinIO/S3 | 文件存储 | K8S |
| **时序数据库** | Prometheus/InfluxDB | 监控数据 | K8S |

### 1.2 架构设计原则

**设计原则**：
```yaml
# 架构设计原则
architecture_principles:
  - "高可用": "多副本部署"
  - "可扩展": "水平扩展能力"
  - "数据安全": "备份加密"
  - "性能优化": "合理资源配置"
  - "监控完善": "全链路监控"
```

## 二、关系型数据库运维

### 2.1 MySQL运维

**部署架构**：
```yaml
# MySQL高可用部署
mysql:
  type: "MySQL Group Replication"
  version: "8.0"
  replicas: 3
  
  resources:
    cpu: "2"
    memory: "4Gi"
    
  storage:
    type: "SSD"
    size: "500Gi"
    
  backup:
    schedule: "0 2 * * *"
    retention: "7 days"
```

**备份策略**：
```yaml
# MySQL备份配置
backup:
  method: "xtrabackup"
  schedule: "0 2 * * *"
  retention:
    daily: 7
    weekly: 4
    monthly: 12
  
  destination:
    local: "/backup/mysql"
    remote: "s3://mysql-backup"
```

### 2.2 PostgreSQL运维

**部署架构**：
```yaml
# PostgreSQL高可用部署
postgresql:
  type: "Patroni + etcd"
  version: "15"
  replicas: 3
  
  resources:
    cpu: "2"
    memory: "4Gi"
    
  storage:
    type: "SSD"
    size: "500Gi"
```

## 三、NoSQL数据库运维

### 3.1 MongoDB运维

**部署架构**：
```yaml
# MongoDB副本集部署
mongodb:
  type: "Replica Set"
  version: "6.0"
  replicas: 3
  
  resources:
    cpu: "2"
    memory: "4Gi"
    
  storage:
    type: "SSD"
    size: "200Gi"
    
  oplog:
    size: "50Gi"
```

**副本集配置**：
```yaml
# MongoDB副本集配置
replicaSet:
  name: "rs0"
  members:
    - host: "mongo-0:27017"
      priority: 2
    - host: "mongo-1:27017"
      priority: 1
    - host: "mongo-2:27017"
      priority: 1
```

### 3.2 Redis运维

**部署架构**：
```yaml
# Redis Cluster部署
redis:
  type: "Cluster"
  version: "7.0"
  nodes: 6
  
  resources:
    cpu: "2"
    memory: "8Gi"
    
  persistence:
    enabled: true
    type: "rdb"
    
  replication:
    enabled: true
    min_slaves: 2
```

**高可用配置**：
```yaml
# Redis Sentinel配置
sentinel:
  replicas: 3
  monitor:
    master_name: "mymaster"
    quorum: 2
```

## 四、消息队列运维

### 4.1 Kafka运维

**部署架构**：
```yaml
# Kafka集群部署
kafka:
  version: "3.6"
  replicas: 3
  partitions: 12
  replication_factor: 3
  
  resources:
    cpu: "4"
    memory: "8Gi"
    
  storage:
    type: "SSD"
    size: "1Ti"
    
  config:
    num.network.threads: 8
    num.io.threads: 16
    socket.send.buffer.bytes: 102400
```

**主题配置**：
```yaml
# Kafka主题配置
topics:
  - name: "business-events"
    partitions: 12
    replication_factor: 3
    retention_hours: 168
    
  - name: "application-logs"
    partitions: 6
    replication_factor: 2
    retention_hours: 72
```

### 4.2 RocketMQ运维

**部署架构**：
```yaml
# RocketMQ部署
rocketmq:
  version: "5.1"
  
  nameserver:
    replicas: 2
    resources:
      cpu: "1"
      memory: "2Gi"
  
  broker:
    replicas: 2
    resources:
      cpu: "2"
      memory: "4Gi"
    storage:
      size: "500Gi"
```

## 五、搜索与存储运维

### 5.1 Elasticsearch运维

**部署架构**：
```yaml
# Elasticsearch部署
elasticsearch:
  version: "8.12"
  replicas: 3
  shards: 5
  
  resources:
    cpu: "4"
    memory: "8Gi"
    
  storage:
    type: "SSD"
    size: "1Ti"
    
  heap:
    size: "4Gi"
    lock_memory: true
```

**ILM策略**：
```yaml
# ILM策略配置
ilm:
  hot:
    max_age: "7d"
    actions:
      rollover:
        max_size: "50Gi"
  
  warm:
    min_age: "7d"
    actions:
      shrink:
        number_of_shards: 1
  
  cold:
    min_age: "30d"
    actions:
      freeze
  
  delete:
    min_age: "90d"
    actions:
      delete
```

### 5.2 MinIO运维

**部署架构**：
```yaml
# MinIO部署
minio:
  version: "2024-05"
  replicas: 4
  tenants: 1
  
  resources:
    cpu: "2"
    memory: "4Gi"
    
  storage:
    type: "SSD"
    size: "10Ti"
    
  config:
    erasure_coding: true
    data_drives: 4
    parity_drives: 2
```

## 六、监控与告警

### 6.1 监控指标

**关键监控指标**：

| 组件 | 关键指标 | 告警阈值 |
|:----:|----------|----------|
| **MySQL** | QPS、连接数、慢查询 | 连接数>80% |
| **MongoDB** | 副本延迟、内存使用 | 延迟>1s |
| **Redis** | 内存使用、命中率 | 内存>85% |
| **Kafka** | 消费延迟、磁盘使用 | 延迟>10s |
| **ES** | 集群健康、分片未分配 | 状态!=green |

### 6.2 告警配置

**告警配置示例**：
```yaml
# 数据库告警规则
alert_rules:
  - name: "mysql_high_cpu"
    expr: "rate(mysql_global_status_questions[5m]) > 10000"
    severity: "warning"
    
  - name: "redis_high_memory"
    expr: "redis_memory_used_bytes / redis_memory_max_bytes > 0.85"
    severity: "critical"
    
  - name: "kafka_consumer_lag"
    expr: "kafka_consumer_group_lag_sum > 10000"
    severity: "warning"
```

## 七、备份与恢复

### 7.1 备份策略

**备份策略对比**：

| 组件 | 备份方式 | 频率 | 保留时间 |
|:----:|----------|------|----------|
| **MySQL** | xtrabackup | 每日全量 | 7天 |
| **MongoDB** | mongodump | 每日全量 | 7天 |
| **Redis** | RDB+AOF | 每小时 | 3天 |
| **Kafka** | 镜像备份 | 每日 | 7天 |
| **ES** | Snapshot | 每日 | 30天 |
| **MinIO** | mc mirror | 实时 | 30天 |

### 7.2 恢复演练

**恢复演练流程**：
```yaml
# 恢复演练流程
disaster_recovery_drill:
  frequency: "季度"
  
  steps:
    1. "准备测试环境"
    2. "执行数据恢复"
    3. "验证数据完整性"
    4. "验证业务功能"
    5. "记录问题"
    6. "优化恢复流程"
```

## 八、实战案例分析

### 8.1 案例1：Redis缓存优化

**场景描述**：
- Redis内存使用率过高
- 需要优化内存使用

**优化方案**：
```yaml
# Redis内存优化
optimization:
  maxmemory: "6Gi"
  maxmemory_policy: "allkeys-lru"
  
  eviction_rules:
    - " volatile-lru"
    - "allkeys-lru"
    - "noeviction"
  
  slow_log:
    max_len: 10000
    slowlog-log-slower-than: 10000
```

### 8.2 案例2：Kafka性能优化

**场景描述**：
- Kafka消费延迟过高
- 需要优化性能

**优化方案**：
```yaml
# Kafka性能优化
optimization:
  consumer:
    fetch.min.bytes: 1
    fetch.max.wait.ms: 500
    max.partition.fetch.bytes: 1048576
    
  producer:
    batch.size: 16384
    linger.ms: 10
    buffer.memory: 33554432
```

## 九、面试1分钟精简版（直接背）

**完整版**：

我们平台涉及多种数据库和中间件。关系型数据库使用MySQL主从集群和PostgreSQL，负责业务数据存储；NoSQL方面使用MongoDB存储文档数据，Redis Cluster做缓存和会话管理；消息队列使用Kafka进行异步通信和日志收集；搜索方面使用Elasticsearch存储日志和业务搜索；对象存储使用MinIO和S3兼容存储。每个组件都有明确的运维分工，SRE团队主要负责MongoDB、Redis、Kafka、ES和MinIO的运维工作，包括部署、监控、备份和故障处理。

**30秒超短版**：

MySQL做业务存储，MongoDB文档存储，Redis缓存，Kafka消息队列，ES搜索，MinIO对象存储。SRE负责MongoDB、Redis、Kafka、ES、MinIO。

## 十、总结

### 10.1 核心要点

1. **高可用部署**：多副本、自动故障转移
2. **监控完善**：关键指标全链路监控
3. **备份恢复**：定期备份、演练验证
4. **性能优化**：合理资源配置、参数调优
5. **运维分工**：明确责任、团队协作

### 10.2 运维原则

| 原则 | 说明 |
|:----:|------|
| **高可用** | 多副本、自动故障转移 |
| **可观测** | 全链路监控、指标完善 |
| **可恢复** | 定期备份、恢复演练 |
| **性能优** | 资源合理、参数调优 |
| **安全固** | 权限控制、加密传输 |

### 10.3 记忆口诀

```
关系数据库MySQL，缓存用Redis，
消息队列Kafka，搜索分析用ES，
对象存储MinIO，高可用保稳定，
监控备份不能少，性能优化要持续。
```

> **参考链接**：[SRE运维面试题全解析：从理论到实践（第二部分）]({% post_url 2026-04-15-sre-interview-questions-part2 %})