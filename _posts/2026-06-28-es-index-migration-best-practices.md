---
layout: post
title: "ES索引迁移实战指南"
subtitle: "深入理解索引迁移方案，掌握零停机迁移技巧"
date: 2026-06-28 10:00:00
author: "OpsOps"
header-img: "img/post-bg-es.jpg"
catalog: true
tags:
  - Elasticsearch
  - 索引迁移
  - 数据迁移
  - 最佳实践
---

## 一、引言

Elasticsearch索引迁移是日常运维中的常见任务，涉及索引结构变更、集群升级、数据冷热分离等场景。选择合适的迁移方案对于保证数据完整性和业务连续性至关重要。

本文将深入介绍ES索引迁移的多种方案，包括Reindex API、Logstash、Snapshot/Restore和跨集群复制(CCR)，并提供零停机迁移的完整实践指南。

---

## 二、SCQA分析框架

### 情境（Situation）
- ES集群需要定期进行索引维护和结构调整
- 数据量增长需要迁移到更大的集群
- 需要在不影响业务的前提下完成迁移

### 冲突（Complication）
- 直接迁移可能导致业务中断
- 数据一致性难以保证
- 大索引迁移耗时过长

### 问题（Question）
- 有哪些索引迁移方案？
- 如何选择合适的迁移策略？
- 如何实现零停机迁移？
- 迁移后如何验证数据一致性？

### 答案（Answer）
- 方案包括Reindex API、Logstash、Snapshot/Restore、CCR
- 根据业务需求（在线/离线、数据量、复杂度）选择方案
- 使用索引别名实现无缝切换
- 通过count对比、抽样验证确保数据一致

---

## 三、迁移方案对比与选择

### 3.1 方案对比表

| 方案 | 适用场景 | 优点 | 缺点 | 停机要求 |
|:------|:------|:------|:------|:------|
| **Reindex API** | 在线迁移、结构变更 | 配置简单、支持数据转换 | 大索引耗时长、资源消耗高 | 无需停机 |
| **Logstash** | 复杂ETL、多数据源 | 支持复杂转换、实时同步 | 配置复杂、性能开销大 | 无需停机 |
| **Snapshot/Restore** | 离线迁移、版本升级 | 速度快、数据一致性高 | 需要停机、版本兼容性要求 | 需要停机 |
| **CCR** | 跨集群同步、灾备 | 实时同步、零数据丢失 | 配置复杂、需要企业版 | 无需停机 |

### 3.2 方案选择决策树

```
                    选择迁移方案
                         │
            ┌────────────┴────────────┐
            ▼                         ▼
       需要停机？                  在线迁移？
            │                         │
       ┌────┴────┐            ┌───────┴───────┐
       ▼         ▼            ▼               ▼
   数据量小   数据量大      简单迁移        复杂ETL
       │         │            │               │
       ▼         ▼            ▼               ▼
   直接重建   Snapshot     Reindex       Logstash
   索引        Restore      API
            ┌────┴────┐
            ▼         ▼
       跨集群？     灾备需求？
            │         │
            ▼         ▼
         CCR        CCR
```

---

## 四、详细迁移方案

### 4.1 Reindex API迁移

**适用场景**：在线迁移、索引结构变更、数据转换

**完整流程**：

**1. 创建目标索引**
```bash
# 创建目标索引，配置新的mapping和settings
curl -X PUT "http://localhost:9200/new_index" -H 'Content-Type: application/json' -d '{
  "settings": {
    "number_of_shards": 5,
    "number_of_replicas": 2,
    "refresh_interval": "1s"
  },
  "mappings": {
    "properties": {
      "title": {"type": "text", "analyzer": "ik_max_word"},
      "content": {"type": "text", "analyzer": "ik_max_word"},
      "created_at": {"type": "date"},
      "tags": {"type": "keyword"},
      "status": {"type": "integer"}
    }
  }
}'
```

**2. 执行Reindex**
```bash
# 基本reindex
curl -X POST "http://localhost:9200/_reindex?wait_for_completion=false" -H 'Content-Type: application/json' -d '{
  "source": {
    "index": "old_index",
    "size": 1000  # 每批次处理1000条
  },
  "dest": {
    "index": "new_index",
    "op_type": "index"
  },
  "conflicts": "proceed",
  "script": {
    "source": """
      // 数据转换示例
      ctx._source.new_field = ctx._source.old_field;
      if (ctx._source.containsKey(\"deprecated_field\")) {
        ctx._source.remove(\"deprecated_field\");
      }
      ctx._source.migrated_at = new Date().getTime();
    """
  }
}'
```

**3. 监控迁移进度**
```bash
# 查询任务状态
curl -X GET "http://localhost:9200/_tasks/TASK_ID"

# 查看集群状态
curl -X GET "http://localhost:9200/_cluster/health?level=indices"
```

### 4.2 Logstash迁移

**适用场景**：复杂ETL处理、多数据源迁移

**配置示例**：
```bash
# logstash_migration.conf
input {
  elasticsearch {
    hosts => ["http://source-es:9200"]
    index => "old_index"
    query => '{ "query": { "range": { "created_at": { "gte": "2024-01-01" } } } }'
    scroll => "10m"
    docinfo => true
    size => 500
  }
}

filter {
  # 添加迁移时间戳
  mutate {
    add_field => { "migrated_at" => "%{@timestamp}" }
  }
  
  # 数据转换
  ruby {
    code => "
      event.set('new_field', event.get('old_field'))
      event.remove('old_field')
    "
  }
  
  # 字段重命名
  mutate {
    rename => { "old_name" => "new_name" }
  }
}

output {
  elasticsearch {
    hosts => ["http://target-es:9200"]
    index => "new_index"
    document_id => "%{[@metadata][_id]}"
    action => "index"
    retry_on_conflict => 3
  }
  
  # 可选：输出到文件记录
  file {
    path => "/var/log/logstash/migration.log"
    codec => line { format => "%{@timestamp} %{message}" }
  }
}
```

**启动命令**：
```bash
logstash -f logstash_migration.conf --path.data /tmp/logstash_data
```

### 4.3 Snapshot/Restore迁移

**适用场景**：离线大规模迁移、版本升级

**完整流程**：

**1. 注册快照仓库**
```bash
# 文件系统仓库
curl -X PUT "http://localhost:9200/_snapshot/es_backup" -H 'Content-Type: application/json' -d '{
  "type": "fs",
  "settings": {
    "location": "/backup/es_snapshots",
    "compress": true,
    "max_snapshot_bytes_per_sec": "50mb",
    "max_restore_bytes_per_sec": "50mb"
  }
}'

# AWS S3仓库
curl -X PUT "http://localhost:9200/_snapshot/s3_backup" -H 'Content-Type: application/json' -d '{
  "type": "s3",
  "settings": {
    "bucket": "es-backup-bucket",
    "region": "us-west-2",
    "compress": true
  }
}'
```

**2. 创建快照**
```bash
curl -X PUT "http://localhost:9200/_snapshot/es_backup/snapshot_20240101?wait_for_completion=false" -H 'Content-Type: application/json' -d '{
  "indices": "old_index",
  "ignore_unavailable": true,
  "include_global_state": false,
  "partial": false
}'
```

**3. 恢复快照**
```bash
# 在目标集群注册相同仓库后恢复
curl -X POST "http://target-es:9200/_snapshot/es_backup/snapshot_20240101/_restore" -H 'Content-Type: application/json' -d '{
  "indices": "old_index",
  "rename_pattern": "old_index",
  "rename_replacement": "new_index",
  "ignore_unavailable": true,
  "include_global_state": false,
  "index_settings": {
    "index.number_of_replicas": 2
  }
}'
```

### 4.4 跨集群复制(CCR)

**适用场景**：跨集群实时同步、灾备

**配置流程**：

**1. 在目标集群配置远程集群**
```bash
curl -X PUT "http://target-es:9200/_cluster/settings" -H 'Content-Type: application/json' -d '{
  "persistent": {
    "cluster": {
      "remote": {
        "source-cluster": {
          "seeds": ["source-es:9300"]
        }
      }
    }
  }
}'
```

**2. 创建跟随索引**
```bash
curl -X PUT "http://target-es:9200/follower_index" -H 'Content-Type: application/json' -d '{
  "settings": {
    "index.soft_deletes.enabled": true
  },
  "mappings": {
    "properties": {
      "title": {"type": "text"},
      "content": {"type": "text"}
    }
  },
  "follow": {
    "remote_cluster": "source-cluster",
    "leader_index": "leader_index",
    "max_read_request_operation_count": 1024,
    "max_outstanding_read_requests": 16,
    "max_read_request_size": "1024kb",
    "max_write_request_operation_count": 1024,
    "max_write_request_size": "1024kb",
    "max_outstanding_write_requests": 16,
    "max_write_buffer_count": 512,
    "max_write_buffer_size": "512mb",
    "max_retry_delay": "5m",
    "read_poll_timeout": "30s"
  }
}'
```

**3. 提升跟随索引为独立索引**
```bash
# 停止跟随关系
curl -X POST "http://target-es:9200/follower_index/_follow/unfollow"

# 提升为独立索引
curl -X POST "http://target-es:9200/follower_index/_settings" -H 'Content-Type: application/json' -d '{
  "index.soft_deletes.enabled": false
}'
```

---

## 五、零停机迁移方案

### 5.1 使用索引别名实现无缝切换

**完整流程**：

```
┌─────────────────────────────────────────────────────────────────┐
│                    零停机索引迁移流程                          │
├─────────────────────────────────────────────────────────────────┤
│                                                               │
│  阶段1: 准备阶段                                               │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ 1. 创建新索引 (new_index)                              │   │
│  │ 2. 配置mapping和settings                               │   │
│  │ 3. 创建别名指向旧索引 (my_index -> old_index)          │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                 │
│                              ▼                                 │
│  阶段2: 数据迁移                                               │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ 1. 执行Reindex (old_index -> new_index)                │   │
│  │ 2. 监控迁移进度                                         │   │
│  │ 3. 处理增量数据                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                 │
│                              ▼                                 │
│  阶段3: 切换阶段                                               │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ 1. 暂停写入 (可选)                                     │   │
│  │ 2. 更新别名指向 (my_index -> new_index)                │   │
│  │ 3. 验证业务正常                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                 │
│                              ▼                                 │
│  阶段4: 清理阶段                                               │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ 1. 删除旧索引 (old_index)                              │   │
│  │ 2. 确认数据完整性                                       │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────────┘
```

**具体操作**：

**1. 准备阶段**
```bash
# 创建新索引
curl -X PUT "http://localhost:9200/my_index_v2" -H 'Content-Type: application/json' -d '{...}'

# 创建或更新别名（假设已存在别名）
curl -X POST "http://localhost:9200/_aliases" -H 'Content-Type: application/json' -d '{
  "actions": [
    {"add": {"index": "my_index_v1", "alias": "my_index"}}
  ]
}'
```

**2. 数据迁移**
```bash
# 执行reindex（异步）
curl -X POST "http://localhost:9200/_reindex?wait_for_completion=false" -H 'Content-Type: application/json' -d '{
  "source": {"index": "my_index_v1"},
  "dest": {"index": "my_index_v2"}
}'

# 监控进度
curl -X GET "http://localhost:9200/_tasks?detailed=true&actions=*reindex"
```

**3. 切换阶段**
```bash
# 原子切换别名
curl -X POST "http://localhost:9200/_aliases" -H 'Content-Type: application/json' -d '{
  "actions": [
    {"remove": {"index": "my_index_v1", "alias": "my_index"}},
    {"add": {"index": "my_index_v2", "alias": "my_index"}}
  ]
}'
```

**4. 清理阶段**
```bash
# 删除旧索引
curl -X DELETE "http://localhost:9200/my_index_v1"

# 验证数据
curl -X GET "http://localhost:9200/my_index/_count"
```

---

## 六、迁移前准备与风险评估

### 6.1 准备工作清单

| 检查项 | 说明 | 命令 |
|:------|:------|:------|
| **集群健康** | 确保集群状态为green | `curl http://localhost:9200/_cluster/health` |
| **索引状态** | 检查源索引状态 | `curl http://localhost:9200/_cat/indices?v` |
| **数据量估算** | 计算迁移数据量 | `curl http://localhost:9200/_cat/indices?v | grep old_index` |
| **Mapping对比** | 确认目标mapping正确性 | `curl http://localhost:9200/new_index/_mapping` |
| **资源评估** | 检查节点资源使用 | `curl http://localhost:9200/_cat/nodes?v` |
| **备份验证** | 确保快照可恢复 | `curl http://localhost:9200/_snapshot/repo/snapshot/_status` |

### 6.2 风险评估

| 风险类型 | 描述 | 缓解措施 |
|:------|:------|:------|
| **数据丢失** | 迁移过程中数据损坏或丢失 | 迁移前备份、迁移后验证 |
| **业务中断** | 迁移导致服务不可用 | 使用零停机方案、选择低峰期 |
| **性能下降** | 迁移占用资源影响查询性能 | 限制reindex速度、调整线程池 |
| **网络问题** | 跨集群迁移网络不稳定 | 使用Snapshot/Restore或增加超时 |
| **版本兼容性** | 目标集群版本不兼容 | 检查版本兼容性、使用兼容API |

---

## 七、数据一致性验证

### 7.1 验证方法

**1. 文档数量对比**
```bash
# 获取源索引文档数
OLD_COUNT=$(curl -s http://localhost:9200/old_index/_count | jq -r '.count')
echo "源索引文档数: $OLD_COUNT"

# 获取目标索引文档数
NEW_COUNT=$(curl -s http://localhost:9200/new_index/_count | jq -r '.count')
echo "目标索引文档数: $NEW_COUNT"

# 对比
if [ "$OLD_COUNT" -eq "$NEW_COUNT" ]; then
  echo "文档数一致"
else
  echo "文档数不一致"
fi
```

**2. 抽样验证**
```bash
# 获取随机文档
curl -s "http://localhost:9200/old_index/_search?size=10&sort=_id:asc" > old_docs.json
curl -s "http://localhost:9200/new_index/_search?size=10&sort=_id:asc" > new_docs.json

# 对比文档内容
diff old_docs.json new_docs.json
```

**3. 数据校验和**
```bash
# ES 7.10+支持的数据校验
curl -X POST "http://localhost:9200/_data_frame/_validate" -H 'Content-Type: application/json' -d '{
  "source": {"index": "old_index"},
  "dest": {"index": "new_index"},
  "validate": {
    "field_mapping": true,
    "doc_count": true
  }
}'
```

---

## 八、生产环境最佳实践

### 8.1 性能优化建议

**1. 调整Reindex性能参数**
```bash
curl -X POST "http://localhost:9200/_reindex" -H 'Content-Type: application/json' -d '{
  "source": {
    "index": "old_index",
    "size": 2000  # 增大批次大小
  },
  "dest": {
    "index": "new_index",
    "routing": "=none"  # 禁用路由
  },
  "max_docs": 1000000,  # 限制单次迁移数量
  "requests_per_second": 1000  # 限速
}'
```

**2. 调整集群设置**
```bash
# 临时调整线程池
curl -X PUT "http://localhost:9200/_cluster/settings" -H 'Content-Type: application/json' -d '{
  "persistent": {
    "thread_pool.write.queue_size": 2000,
    "thread_pool.write.max": 32
  }
}'

# 临时关闭刷新
curl -X PUT "http://localhost:9200/new_index/_settings" -H 'Content-Type: application/json' -d '{
  "index.refresh_interval": "-1"
}'

# 迁移完成后恢复
curl -X PUT "http://localhost:9200/new_index/_settings" -H 'Content-Type: application/json' -d '{
  "index.refresh_interval": "1s"
}'
```

### 8.2 监控告警配置

**Prometheus规则**：
```yaml
groups:
- name: es-migration
  rules:
  - alert: ReindexRunningTooLong
    expr: time() - es_reindex_start_time > 3600
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Reindex任务运行超过1小时"

  - alert: ClusterHealthYellow
    expr: es_cluster_health_status == 1
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "ES集群状态为Yellow"

  - alert: ClusterHealthRed
    expr: es_cluster_health_status == 2
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "ES集群状态为Red"
```

---

## 九、常见问题排查

### 9.1 问题诊断表

| 问题现象 | 可能原因 | 排查方法 | 解决方案 |
|:------|:------|:------|:------|
| **Reindex速度慢** | batch过小、资源不足 | 查看任务状态、节点资源 | 增大batch size、调整线程池 |
| **数据不一致** | 迁移期间有写入 | 检查增量数据、使用CCR | 暂停写入或使用CCR同步增量 |
| **内存溢出** | scroll size过大 | 查看堆内存使用 | 减小scroll size |
| **索引冲突** | 目标索引已存在 | 检查索引状态 | 删除目标索引或使用conflicts:proceed |
| **网络超时** | 跨集群网络不稳定 | 检查网络连通性 | 增加timeout、使用Snapshot |
| **版本不兼容** | API版本差异 | 检查ES版本 | 使用兼容API或升级版本 |

### 9.2 排查命令速查

```bash
# 查看集群健康
curl http://localhost:9200/_cluster/health

# 查看节点状态
curl http://localhost:9200/_cat/nodes?v

# 查看索引状态
curl http://localhost:9200/_cat/indices?v

# 查看reindex任务
curl http://localhost:9200/_tasks?detailed=true&actions=*reindex

# 查看快照状态
curl http://localhost:9200/_snapshot/repo/snapshot/_status

# 查看集群日志
tail -f /var/log/elasticsearch/cluster.log

# 测试网络连通性
ping source-es
telnet source-es 9200
```

---

## 十、总结

### 核心要点

1. **方案选择**：根据业务需求选择合适的迁移方案
   - 在线迁移：Reindex API或Logstash
   - 离线迁移：Snapshot/Restore
   - 跨集群同步：CCR

2. **零停机迁移**：使用索引别名实现无缝切换
   - 创建新索引 → Reindex → 切换别名 → 删除旧索引

3. **数据一致性**：迁移前后必须验证
   - 文档数量对比、抽样验证、数据校验和

4. **性能优化**：合理调整参数提升迁移速度
   - batch size、线程池、刷新间隔

### 最佳实践清单

- ✅ 选择低峰期进行迁移
- ✅ 迁移前备份数据
- ✅ 使用异步Reindex避免超时
- ✅ 监控迁移进度和集群状态
- ✅ 迁移后验证数据一致性
- ✅ 使用索引别名实现零停机切换
- ✅ 清理旧索引释放资源

> 本文对应的面试题：[ES索引迁移怎么做？]({% post_url 2026-04-15-sre-interview-questions %})

---

## 附录：迁移脚本示例

**完整迁移脚本**：
```bash
#!/bin/bash
# ES索引迁移脚本

SOURCE_INDEX="old_index"
TARGET_INDEX="new_index"
ALIAS_NAME="my_index"
ES_HOST="http://localhost:9200"

echo "=== 开始索引迁移 ==="
echo "源索引: $SOURCE_INDEX"
echo "目标索引: $TARGET_INDEX"
echo "别名: $ALIAS_NAME"

# 1. 创建目标索引
echo ""
echo "1. 创建目标索引..."
curl -X PUT "$ES_HOST/$TARGET_INDEX" -H 'Content-Type: application/json' -d '{
  "settings": {"number_of_shards": 5, "number_of_replicas": 1},
  "mappings": {"properties": {"title": {"type": "text"}, "content": {"type": "text"}}}
}'

# 2. 执行Reindex
echo ""
echo "2. 执行Reindex..."
RESPONSE=$(curl -s -X POST "$ES_HOST/_reindex?wait_for_completion=false" -H 'Content-Type: application/json' -d '{
  "source": {"index": "'$SOURCE_INDEX'"},
  "dest": {"index": "'$TARGET_INDEX'"}
}')
TASK_ID=$(echo "$RESPONSE" | jq -r '.task')
echo "任务ID: $TASK_ID"

# 3. 等待完成
echo ""
echo "3. 等待迁移完成..."
while true; do
  STATUS=$(curl -s "$ES_HOST/_tasks/$TASK_ID" | jq -r '.completed')
  if [ "$STATUS" = "true" ]; then
    echo "迁移完成!"
    break
  fi
  echo "迁移中... $(date)"
  sleep 30
done

# 4. 切换别名
echo ""
echo "4. 切换别名..."
curl -X POST "$ES_HOST/_aliases" -H 'Content-Type: application/json' -d '{
  "actions": [
    {"remove": {"index": "'$SOURCE_INDEX'", "alias": "'$ALIAS_NAME'"}},
    {"add": {"index": "'$TARGET_INDEX'", "alias": "'$ALIAS_NAME'"}}
  ]
}'

# 5. 验证
echo ""
echo "5. 验证数据..."
OLD_COUNT=$(curl -s "$ES_HOST/$SOURCE_INDEX/_count" | jq -r '.count')
NEW_COUNT=$(curl -s "$ES_HOST/$TARGET_INDEX/_count" | jq -r '.count')
echo "源索引文档数: $OLD_COUNT"
echo "目标索引文档数: $NEW_COUNT"

if [ "$OLD_COUNT" -eq "$NEW_COUNT" ]; then
  echo "✅ 数据验证通过!"
else
  echo "❌ 数据不一致!"
  exit 1
fi

echo ""
echo "=== 迁移完成 ==="
```
