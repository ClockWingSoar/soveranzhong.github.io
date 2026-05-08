# Elasticsearch数据保存与存储优化指南

## 情境与背景

在大规模日志和时序数据场景下，ES的数据保存策略直接影响存储成本、查询性能和数据安全性。本文从DevOps/SRE视角，深入讲解冷热分离、ILM生命周期管理、快照备份等核心策略，帮助读者构建高效、可靠的数据存储方案。

## 一、冷热分离架构

### 1.1 数据分层策略

| 数据类型 | 存储介质 | 节点类型 | 查询频率 | 保留周期 |
|:--------:|----------|----------|----------|----------|
| **热数据** | SSD | Hot节点 | 高 | 0-7天 |
| **温数据** | HDD | Warm节点 | 中 | 7-30天 |
| **冷数据** | 归档存储 | Cold节点 | 低 | 30天+ |

### 1.2 冷热分离架构图

```mermaid
flowchart TB
    subgraph 数据写入
        A["Filebeat"] --> B["Hot节点(SSD)"]
    end
    
    subgraph 数据分层
        B --> C["Warm节点(HDD)"]
        C --> D["Cold节点(归档)"]
    end
    
    subgraph 查询层
        E["Coordinate节点"]
        E --> B
        E --> C
        E --> D
    end
    
    style B fill:#c8e6c9
    style C fill:#fff3e0
    style D fill:#bbdefb
```

### 1.3 节点配置

**Hot节点配置**：

```yaml
# elasticsearch.yml
node.attr.data_hot: true
node.data: true
node.master: false

# 存储配置
path.data: /ssd/data
```

**Warm节点配置**：

```yaml
# elasticsearch.yml
node.attr.data_warm: true
node.data: true
node.master: false

# 存储配置
path.data: /hdd/data
```

**Cold节点配置**：

```yaml
# elasticsearch.yml
node.attr.data_cold: true
node.data: true
node.master: false

# 存储配置（可使用对象存储）
path.data: /cold/data
```

### 1.4 分片分配策略

```yaml
# elasticsearch.yml
cluster.routing.allocation.include._name: "hot-*"
cluster.routing.allocation.include.data_hot: true
```

## 二、索引生命周期管理（ILM）

### 2.1 ILM阶段配置

```json
PUT _ilm/policy/data-retention-policy
{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "rollover": {
            "max_size": "50GB",
            "max_age": "7d"
          },
          "set_priority": { "priority": 100 }
        }
      },
      "warm": {
        "min_age": "7d",
        "actions": {
          "forcemerge": { "max_num_segments": 1 },
          "shrink": { "number_of_shards": 1 },
          "allocate": {
            "require": { "data_warm": "true" },
            "number_of_replicas": 1
          },
          "set_priority": { "priority": 50 }
        }
      },
      "cold": {
        "min_age": "30d",
        "actions": {
          "allocate": {
            "require": { "data_cold": "true" },
            "number_of_replicas": 0
          },
          "freeze": {},
          "set_priority": { "priority": 10 }
        }
      },
      "delete": {
        "min_age": "90d",
        "actions": {
          "delete": {
            "delete_searchable_snapshot": true
          }
        }
      }
    }
  }
}
```

### 2.2 索引模板配置

```json
PUT _index_template/data-template
{
  "index_patterns": ["logs-*", "metrics-*"],
  "template": {
    "settings": {
      "number_of_shards": 3,
      "number_of_replicas": 2,
      "index.lifecycle.name": "data-retention-policy",
      "index.lifecycle.rollover_alias": "data-alias"
    },
    "mappings": {
      "properties": {
        "@timestamp": { "type": "date" },
        "message": { "type": "text" },
        "level": { "type": "keyword" },
        "service": { "type": "keyword" }
      }
    }
  }
}
```

### 2.3 创建可滚动索引

```json
PUT data-000001
{
  "aliases": {
    "data-alias": {
      "is_write_index": true
    }
  }
}
```

## 三、副本与分片策略

### 3.1 副本配置

```json
PUT /my_index/_settings
{
  "number_of_replicas": 2
}
```

### 3.2 分片配置

| 数据量 | 分片数 | 说明 |
|:------:|:------:|------|
| <10GB | 1-3 | 小型索引 |
| 10-50GB | 3-5 | 中型索引 |
| >50GB | 5-10+ | 大型索引 |

### 3.3 分片分配过滤

```yaml
# elasticsearch.yml
cluster.routing.allocation.awareness.attributes: zone
cluster.routing.allocation.awareness.force.zone.values: zone1,zone2,zone3
```

## 四、快照备份策略

### 4.1 注册备份仓库

```json
PUT _snapshot/s3_backup
{
  "type": "s3",
  "settings": {
    "bucket": "es-backup-bucket",
    "region": "us-east-1",
    "base_path": "backups",
    "access_key": "AKIAIOSFODNN7EXAMPLE",
    "secret_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
  }
}
```

### 4.2 创建快照

```json
PUT _snapshot/s3_backup/daily_backup_20240508?wait_for_completion=true
{
  "indices": "logs-*,metrics-*",
  "ignore_unavailable": true,
  "include_global_state": false
}
```

### 4.3 定时备份（使用curator）

```yaml
# curator.yml
client:
  hosts:
    - es-01:9200
  url_prefix:
  use_ssl: False
  certificate:
  client_cert:
  client_key:
  ssl_no_validate: False
  http_auth:
  timeout: 30
  master_only: False

logging:
  loglevel: INFO
  logfile:
  logformat: default
  blacklist: ['elasticsearch', 'urllib3']
```

```yaml
# action.yml
actions:
  1:
    action: snapshot
    description: "Snapshot indices"
    options:
      repository: s3_backup
      name: daily_backup_{now:%Y%m%d}
      ignore_unavailable: true
      include_global_state: false
    filters:
    - filtertype: pattern
      kind: prefix
      value: logs-
```

### 4.4 恢复快照

```json
POST _snapshot/s3_backup/daily_backup_20240508/_restore
{
  "indices": "logs-2024.05.08",
  "rename_pattern": "logs-(.+)",
  "rename_replacement": "restored-logs-$1",
  "include_global_state": false
}
```

## 五、写入优化策略

### 5.1 批量写入

```bash
# 批量写入示例
curl -XPOST 'http://es:9200/_bulk' -H 'Content-Type: application/json' -d '
{"index":{"_index":"logs-2024.05.08"}}
{"timestamp":"2024-05-08T10:00:00","message":"log message","level":"INFO"}
{"index":{"_index":"logs-2024.05.08"}}
{"timestamp":"2024-05-08T10:00:01","message":"log message 2","level":"ERROR"}
'
```

### 5.2 刷新间隔优化

```json
PUT /my_index/_settings
{
  "refresh_interval": "30s"
}
```

### 5.3 禁用副本写入（临时）

```json
PUT /my_index/_settings
{
  "number_of_replicas": 0
}

# 写入完成后恢复
PUT /my_index/_settings
{
  "number_of_replicas": 2
}
```

### 5.4 索引缓冲区优化

```yaml
# elasticsearch.yml
indices.memory.index_buffer_size: 30%
```

## 六、数据安全与合规

### 6.1 数据加密

```yaml
# elasticsearch.yml
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.keystore.path: certs/elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: certs/elastic-certificates.p12
```

### 6.2 访问控制

```json
PUT _security/role/read_only
{
  "indices": [
    {
      "names": ["logs-*"],
      "privileges": ["read"]
    }
  ]
}
```

### 6.3 审计日志

```yaml
# elasticsearch.yml
xpack.security.audit.enabled: true
xpack.security.audit.outputs: [ "file", "elasticsearch" ]
```

## 七、监控与告警

### 7.1 存储监控指标

| 指标 | 关注值 |
|:----:|--------|
| 磁盘使用率 | <80% |
| 分片数 | 预期值 |
| 副本状态 | 全部active |
| ILM阶段 | 正常流转 |

### 7.2 告警规则

```json
{
  "rules": [
    {
      "name": "磁盘使用率过高",
      "condition": {
        "type": "compare",
        "query": {
          "range": { "disk.used_percent": { "gte": 80 } }
        },
        "time_window": "5m"
      },
      "priority": "P1",
      "actions": [
        {
          "type": "slack",
          "channel": "#es-alerts"
        }
      ]
    },
    {
      "name": "ILM执行失败",
      "condition": {
        "type": "compare",
        "query": {
          "term": { "ilm.execution_status": "failed" }
        },
        "time_window": "1m"
      },
      "priority": "P2",
      "actions": [
        {
          "type": "email",
          "to": ["devops@example.com"]
        }
      ]
    }
  ]
}
```

## 八、面试1分钟精简版（直接背）

**完整版**：

ES保存数据主要策略有：冷热分离，热数据放SSD节点保证查询性能，冷数据放HDD或归档降低成本；配置ILM索引生命周期管理，自动滚动更新、合并分片、删除过期数据；设置合理副本数保证高可用，生产环境建议2个副本；定期做快照备份到外部存储用于灾难恢复；写入时批量写入、调大刷新间隔提升性能。另外还需要注意数据加密、访问控制和审计日志，确保数据安全合规。

**30秒超短版**：

ES保存策略：冷热分离省成本，ILM自动管周期，副本冗余保可用，快照备份防丢失，写入优化提性能。

## 九、总结

### 9.1 关键策略

| 策略 | 目的 | 实现方式 |
|:----:|------|----------|
| **冷热分离** | 平衡性能与成本 | 节点属性+分片分配 |
| **ILM** | 自动化管理 | 索引生命周期策略 |
| **副本冗余** | 高可用 | number_of_replicas |
| **快照备份** | 灾难恢复 | S3/本地仓库 |
| **写入优化** | 提升性能 | 批量+刷新间隔 |

### 9.2 生产环境检查清单

- [ ] 冷热分离架构已配置
- [ ] ILM策略已部署
- [ ] 副本数≥2
- [ ] 快照备份已配置
- [ ] 写入优化已启用
- [ ] 监控告警已配置
- [ ] 数据加密已启用

### 9.3 记忆口诀

```
冷热分离省成本，ILM自动管周期，
副本冗余保可用，快照备份防丢失，
写入优化提性能，数据安全要保证。
```

> **参考链接**：[SRE运维面试题全解析：从理论到实践（第二部分）]({% post_url 2026-04-15-sre-interview-questions-part2 %})