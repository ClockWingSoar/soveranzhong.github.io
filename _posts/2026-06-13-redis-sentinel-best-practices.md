---
layout: post
title: "Redis主从切换与哨兵监控最佳实践"
subtitle: "深入理解哨兵机制，保障Redis高可用性"
date: 2026-06-13 10:00:00
author: "OpsOps"
header-img: "img/post-bg-redis.jpg"
catalog: true
tags:
  - Redis
  - 哨兵
  - 主从复制
  - 故障转移
  - 高可用
---

## 一、引言

在分布式系统中，Redis作为核心缓存和数据存储组件，其高可用性直接决定了业务的稳定性。主从复制是Redis实现高可用的基础，而哨兵（Sentinel）机制则提供了自动故障转移能力。本文将深入探讨Redis主从切换的原理、哨兵机制的工作流程以及生产环境的监控最佳实践。

---

## 二、SCQA分析框架

### 情境（Situation）
- Redis作为核心缓存，单点故障会导致业务中断
- 主从复制实现数据冗余，但需要手动切换
- 大规模分布式系统需要自动化故障转移能力

### 冲突（Complication）
- 主节点故障时如何快速切换到从节点？
- 如何保证切换过程中的数据一致性？
- 如何监控主从状态和切换过程？
- 脑裂问题如何解决？

### 问题（Question）
- Redis主从切换有哪些方式？
- 哨兵机制是如何工作的？
- 故障转移的完整流程是什么？
- 如何监控主从状态和哨兵健康？
- 生产环境有哪些最佳实践？

### 答案（Answer）
- 主从切换分为手动切换和自动切换（哨兵模式）
- 哨兵通过主观下线和客观下线检测故障
- 故障转移包括检测、选举、升级三个阶段
- 需要监控复制状态、延迟、哨兵状态等指标
- 生产环境需部署多哨兵节点，定期演练

---

## 三、主从复制原理

### 3.1 复制架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Redis主从复制架构                       │
├─────────────────────────────────────────────────────────────┤
│                                                           │
│     主节点 (Master)                    从节点 (Slave)      │
│     ┌──────────────┐                  ┌──────────────┐     │
│     │  写操作      │                  │  读操作      │     │
│     │  复制偏移量   │─────同步───────▶│  复制偏移量   │     │
│     │  master_repl │                  │  slave_repl  │     │
│     │  _offset     │                  │  _offset     │     │
│     └──────────────┘                  └──────────────┘     │
│          │                                    │            │
│          │ 1. SYNC命令                         │            │
│          │ 2. BGSAVE生成RDB                    │            │
│          │ 3. 发送RDB文件                      │            │
│          │ 4. 发送增量命令                      │            │
│          └─────────────────────────────────────┘            │
│                                                           │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 复制过程

**同步阶段（全量复制）**：
```bash
1. 从节点发送 SYNC 命令
2. 主节点执行 BGSAVE 生成RDB文件
3. 主节点将RDB文件发送给从节点
4. 从节点加载RDB文件恢复数据
5. 主节点发送增量命令（写命令缓存）
```

**命令传播阶段（增量复制）**：
```bash
1. 主节点执行写命令
2. 主节点将命令写入复制缓冲区
3. 从节点通过REPLCONF ACK获取偏移量
4. 主节点发送缓冲区中的命令
5. 从节点执行命令保持数据一致
```

### 3.3 复制偏移量

```bash
# 主节点维护
master_repl_offset：主节点累计写入字节数

# 从节点维护
slave_repl_offset：从节点已接收字节数

# 延迟计算
lag = master_repl_offset - slave_repl_offset
```

---

## 四、哨兵机制详解

### 4.1 哨兵架构

```
┌─────────────────────────────────────────────────────────────┐
│                      哨兵集群架构                          │
├─────────────────────────────────────────────────────────────┤
│                                                           │
│   ┌─────────┐    ┌─────────┐    ┌─────────┐              │
│   │Sentinel │    │Sentinel │    │Sentinel │              │
│   │   S1    │    │   S2    │    │   S3    │              │
│   └────┬────┘    └────┬────┘    └────┬────┘              │
│        │              │              │                    │
│        └──────────────┼──────────────┘                    │
│                       ▼                                   │
│            ┌─────────────────┐                            │
│            │   Master (M1)   │                            │
│            └────────┬────────┘                            │
│                     │                                     │
│        ┌────────────┼────────────┐                        │
│        ▼            ▼            ▼                        │
│   ┌─────────┐  ┌─────────┐  ┌─────────┐                  │
│   │ Slave1  │  │ Slave2  │  │ Slave3  │                  │
│   │  (R1)   │  │  (R2)   │  │  (R3)   │                  │
│   └─────────┘  └─────────┘  └─────────┘                  │
│                                                           │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 哨兵核心功能

| 功能 | 说明 |
|:------|:------|
| **监控** | 持续检查主从节点是否正常运行 |
| **通知** | 节点故障时发送告警通知 |
| **故障转移** | 主节点故障时自动选举新主 |
| **配置提供** | 客户端通过哨兵获取主节点地址 |

### 4.3 哨兵配置示例

```yaml
# sentinel.conf
port 26379
daemonize yes
pidfile /var/run/redis-sentinel.pid
logfile /var/log/redis/sentinel.log
dir /tmp

# 监控主节点
sentinel monitor mymaster 192.168.1.100 6379 2
sentinel down-after-milliseconds mymaster 30000
sentinel failover-timeout mymaster 180000
sentinel parallel-syncs mymaster 1
sentinel notification-script mymaster /usr/local/bin/notify.sh
```

**配置参数说明**：
| 参数 | 说明 |
|:------|:------|
| `monitor` | 监控的主节点名称、IP、端口、quorum数 |
| `down-after-milliseconds` | 判定节点不可达的超时时间 |
| `failover-timeout` | 故障转移超时时间 |
| `parallel-syncs` | 并行同步的从节点数 |
| `notification-script` | 告警通知脚本 |

---

## 五、故障转移流程

### 5.1 阶段一：故障检测

**主观下线（SDOWN）**：
```bash
# 单个哨兵认为主节点不可达
1. 哨兵每隔1秒向主节点发送PING命令
2. 如果在down-after-milliseconds（默认30秒）内没有响应
3. 哨兵标记主节点为SDOWN（Subjectively Down）
```

**客观下线（ODOWN）**：
```bash
# 多数哨兵认为主节点不可达
1. 哨兵向其他哨兵发送 SENTINEL is-master-down-by-addr 命令
2. 超过quorum数量的哨兵返回主节点下线
3. 哨兵标记主节点为ODOWN（Objectively Down）
```

### 5.2 阶段二：领头哨兵选举

**Raft选举机制**：
```bash
1. 发现ODOWN的哨兵向其他哨兵发送选举请求
2. 哨兵使用epoch和runid标识选举轮次
3. 收到请求的哨兵如果还未投票，就投票给该哨兵
4. 获得超过半数选票的哨兵成为领头哨兵
5. 如果没有哨兵获得多数票，等待下一轮选举
```

**选举规则**：
- 每个哨兵在一个epoch内只能投一票
- 投票给第一个请求的哨兵
- 需要超过半数哨兵同意才能当选

### 5.3 阶段三：新主节点选举

**候选从节点筛选**：
```bash
# 筛选条件：
1. 在线状态：sentinel_slave_status = online
2. 复制状态：最后一次交互时间 < down-after-milliseconds * 10
3. 优先级：slave-priority != 0
4. 复制偏移量：与主节点差距在合理范围
```

**选举优先级**：
```bash
1. slave-priority最小优先（默认100，0表示不参与选举）
2. 复制偏移量最大优先（数据最新）
3. runid字典序最小优先（打破平局）
```

### 5.4 阶段四：执行故障转移

```bash
1. 领头哨兵向新主节点发送 SLAVEOF NO ONE
2. 新主节点升级为主节点
3. 领头哨兵向其他从节点发送 SLAVEOF 新主节点IP 端口
4. 等待从节点同步完成（根据parallel-syncs控制并行数）
5. 更新哨兵配置（sentinel.conf）
6. 原主节点恢复后作为从节点加入集群
```

---

## 六、数据一致性保障

### 6.1 脑裂问题

**现象**：
```bash
# 网络分区导致多个主节点
- 主节点与哨兵网络断开，但主节点仍正常运行
- 哨兵选举新主节点，导致两个主节点同时存在
- 客户端可能写入到不同的主节点，数据不一致
```

**解决方案**：
```yaml
# redis.conf
min-slaves-to-write 1
min-slaves-max-lag 10
```

**作用**：
- `min-slaves-to-write`：至少需要1个从节点才能写入
- `min-slaves-max-lag`：从节点最大延迟不能超过10秒
- 当条件不满足时，主节点拒绝写入，防止脑裂

### 6.2 数据丢失场景

**场景分析**：
```bash
1. 主节点写入数据，但未同步到从节点
2. 主节点立即故障
3. 从节点升级为主节点，丢失未同步的数据
```

**解决方案**：
```bash
# 减少数据丢失的配置
- 配置合理的min-slaves-to-write
- 使用AOF持久化（appendfsync always）
- 定期备份RDB文件
- 监控复制延迟，及时发现问题
```

---

## 七、监控指标与告警

### 7.1 核心监控指标

**复制状态指标**：
| 指标 | 说明 | 获取方式 |
|:------|:------|:------|
| `connected_slaves` | 从节点数量 | INFO replication |
| `master_repl_offset` | 主节点复制偏移量 | INFO replication |
| `slave_repl_offset` | 从节点复制偏移量 | INFO replication |
| `lag` | 复制延迟 | INFO replication |
| `role` | 节点角色 | INFO replication |

**哨兵状态指标**：
| 指标 | 说明 | 获取方式 |
|:------|:------|:------|
| `sentinel_masters` | 监控的主节点数 | INFO sentinel |
| `sentinel_tilt` | Tilt模式状态 | INFO sentinel |
| `sentinel_running_scripts` | 运行中的脚本数 | INFO sentinel |
| `sentinel_scripts_queue_length` | 脚本队列长度 | INFO sentinel |

### 7.2 Prometheus监控

**redis_exporter指标**：
```promql
# 复制指标
redis_connected_slaves
redis_master_repl_offset
redis_slave_repl_offset
redis_slave_lag_seconds

# 哨兵指标
redis_sentinel_tilt
redis_sentinel_masters
redis_sentinel_slaves
redis_sentinel_down_since_seconds
redis_sentinel_failover_in_progress
```

**监控仪表盘示例**：
```json
{
  "panels": [
    {
      "type": "gauge",
      "title": "从节点数量",
      "targets": ["redis_connected_slaves"],
      "thresholds": [2, 1]
    },
    {
      "type": "graph",
      "title": "复制延迟趋势",
      "targets": ["redis_slave_lag_seconds"]
    },
    {
      "type": "stat",
      "title": "哨兵Tilt模式",
      "targets": ["redis_sentinel_tilt"]
    }
  ]
}
```

### 7.3 告警规则配置

```yaml
groups:
- name: redis-sentinel.rules
  rules:
  - alert: RedisMasterDown
    expr: redis_sentinel_down_since_seconds > 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Redis主节点 {{ $labels.instance }} 已下线"
      description: "主节点已离线 {{ $value }} 秒，哨兵正在进行故障转移"

  - alert: RedisSlaveLagHigh
    expr: redis_slave_lag_seconds > 10
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Redis从节点延迟过高"
      description: "从节点延迟达到 {{ $value }} 秒"

  - alert: RedisSlaveDisconnected
    expr: redis_connected_slaves < 2
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Redis从节点数量不足"
      description: "当前从节点数量为 {{ $value }}，期望至少2个"

  - alert: RedisSentinelTilt
    expr: redis_sentinel_tilt == 1
    for: 1m
    labels:
      severity: warning
    annotations:
      summary: "Redis哨兵进入Tilt模式"
      description: "哨兵 {{ $labels.instance }} 进入Tilt模式，可能存在网络问题"

  - alert: RedisFailoverInProgress
    expr: redis_sentinel_failover_in_progress == 1
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Redis故障转移超时"
      description: "故障转移已持续 {{ $value }} 秒，需要人工介入"
```

---

## 八、生产环境最佳实践

### 8.1 哨兵部署建议

**节点数量**：
```bash
# 建议至少3个哨兵节点
- 奇数个节点（防止脑裂）
- 分布在不同物理机/可用区
- 避免单点故障
```

**部署架构**：
```
可用区A          可用区B          可用区C
┌─────────┐      ┌─────────┐      ┌─────────┐
│Sentinel │      │Sentinel │      │Sentinel │
│   S1    │      │   S2    │      │   S3    │
└─────────┘      └─────────┘      └─────────┘
    │                │                │
┌─────────┐      ┌─────────┐      ┌─────────┐
│ Master  │      │ Slave1  │      │ Slave2  │
└─────────┘      └─────────┘      └─────────┘
```

### 8.2 配置优化

**主节点配置**：
```yaml
# redis.conf (master)
maxmemory 16gb
maxmemory-policy allkeys-lru
appendonly yes
appendfsync everysec
min-slaves-to-write 1
min-slaves-max-lag 10
```

**从节点配置**：
```yaml
# redis.conf (slave)
slaveof 192.168.1.100 6379
slave-priority 100
slave-read-only yes
repl-diskless-sync no
repl-diskless-sync-delay 5
```

### 8.3 切换演练

**演练计划**：
```bash
# 频率：每季度一次
# 目标：验证故障转移流程
# 步骤：
1. 停止主节点Redis服务
2. 观察哨兵日志确认故障检测
3. 验证新主节点选举
4. 检查从节点同步状态
5. 验证客户端自动重连
6. 恢复原主节点作为从节点
7. 检查数据一致性
```

**演练检查清单**：
| 检查项 | 预期结果 |
|:------|:------|
| 故障检测时间 | < 30秒 |
| 故障转移时间 | < 60秒 |
| 数据一致性 | 无数据丢失 |
| 客户端重连 | 自动重连成功 |

### 8.4 客户端配置

**Java客户端（Jedis）**：
```java
Set<String> sentinels = new HashSet<>();
sentinels.add("sentinel1:26379");
sentinels.add("sentinel2:26379");
sentinels.add("sentinel3:26379");

JedisPoolConfig poolConfig = new JedisPoolConfig();
poolConfig.setMaxTotal(100);
poolConfig.setMaxIdle(20);
poolConfig.setMinIdle(5);
poolConfig.setTestOnBorrow(true);

JedisSentinelPool pool = new JedisSentinelPool("mymaster", sentinels, poolConfig);
```

**Python客户端（redis-py）**：
```python
from redis.sentinel import Sentinel

sentinel = Sentinel([
    ('sentinel1', 26379),
    ('sentinel2', 26379),
    ('sentinel3', 26379)
], socket_timeout=0.1)

master = sentinel.master_for('mymaster', socket_timeout=0.1)
slave = sentinel.slave_for('mymaster', socket_timeout=0.1)
```

---

## 九、常见问题与解决方案

### 问题一：哨兵选举失败

**现象**：
```bash
# 无法选出领头哨兵
- 哨兵日志显示多次选举失败
- 故障转移无法启动
```

**原因**：
- 哨兵节点数量为偶数，无法形成多数派
- 哨兵之间网络不通
- 哨兵配置不一致

**解决方案**：
```bash
1. 确保哨兵节点数量为奇数（3、5、7...）
2. 检查哨兵之间的网络连通性
3. 统一哨兵配置（特别是quorum值）
4. 重启故障的哨兵节点
```

### 问题二：从节点同步延迟过高

**现象**：
```bash
# INFO replication显示lag持续增加
- 从节点复制偏移量远落后于主节点
- 业务查询可能获取到过期数据
```

**原因**：
- 主节点写入速度过快
- 从节点资源不足（CPU/内存/网络）
- 网络带宽不足
- 从节点执行了慢查询

**解决方案**：
```bash
1. 增加从节点资源配置
2. 优化网络带宽
3. 限制主节点写入速度
4. 避免在从节点执行慢查询
5. 考虑使用Redis Cluster分担压力
```

### 问题三：故障转移时间过长

**现象**：
```bash
# 故障转移耗时超过预期
- 客户端长时间无法写入
- 业务受到影响
```

**原因**：
- parallel-syncs设置过大，从节点同步耗时
- 从节点数据量过大，RDB加载时间长
- 网络延迟高

**解决方案**：
```bash
1. 设置parallel-syncs为1（串行同步）
2. 控制Redis数据量大小
3. 使用SSD存储加速RDB加载
4. 优化网络环境
```

### 问题四：脑裂导致数据丢失

**现象**：
```bash
# 网络分区恢复后数据不一致
- 原主节点有部分数据未同步到新主节点
- 两个主节点都有写入
```

**解决方案**：
```bash
1. 配置min-slaves-to-write和min-slaves-max-lag
2. 故障转移完成后检查数据一致性
3. 使用Redis Cluster替代主从模式
4. 定期备份和校验数据
```

---

## 十、总结

### 核心要点

1. **主从切换方式**：手动切换适用于计划性维护，自动切换依赖哨兵机制
2. **哨兵机制**：通过主观下线和客观下线检测故障，Raft选举领头哨兵
3. **故障转移流程**：故障检测 → 领头选举 → 新主选举 → 执行切换
4. **数据一致性**：通过min-slaves配置防止脑裂，减少数据丢失
5. **监控重点**：复制状态、延迟、哨兵状态、故障转移进度

### 实施建议

| 阶段 | 任务 | 时间 |
|:------|:------|:------|
| 第一阶段 | 部署主从复制 | 1天 |
| 第二阶段 | 配置哨兵集群 | 1天 |
| 第三阶段 | 配置监控告警 | 1天 |
| 第四阶段 | 故障切换演练 | 持续 |

> 本文对应的面试题：[Redis主从切换怎么做？怎么监控？]({% post_url 2026-04-15-sre-interview-questions %})

---

## 附录：常用命令

```bash
# 查看主从状态
redis-cli INFO replication

# 查看哨兵状态
redis-cli -p 26379 INFO sentinel

# 查看哨兵监控的主节点
redis-cli -p 26379 SENTINEL masters

# 查看主节点的从节点列表
redis-cli -p 26379 SENTINEL slaves mymaster

# 手动触发故障转移
redis-cli -p 26379 SENTINEL failover mymaster

# 检查从节点同步状态
redis-cli INFO replication | grep offset
```
