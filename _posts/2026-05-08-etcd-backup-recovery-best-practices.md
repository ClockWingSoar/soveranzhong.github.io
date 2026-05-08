# etcd备份与恢复策略：K8S数据安全保障指南

## 情境与背景

etcd是Kubernetes集群的核心组件，存储着所有集群状态数据。作为高级DevOps/SRE工程师，掌握etcd备份与恢复策略是确保集群数据安全的关键。本文从DevOps/SRE视角，深入讲解etcd备份与恢复的最佳实践。

## 一、etcd备份机制

### 1.1 备份工具

**etcdctl工具**：
```yaml
# etcdctl配置
etcdctl:
  api_version: "3"
  endpoints: "https://127.0.0.1:2379"
  cacert: "/etc/kubernetes/pki/etcd/ca.crt"
  cert: "/etc/kubernetes/pki/etcd/server.crt"
  key: "/etc/kubernetes/pki/etcd/server.key"
```

### 1.2 备份类型

**备份类型对比**：

| 类型 | 说明 | 优点 | 缺点 |
|:----:|------|:----:|:----:|
| **全量备份** | 完整快照 | 恢复简单 | 占用空间大 |
| **增量备份** | 基于wal日志 | 空间占用小 | 恢复复杂 |
| **混合备份** | 全量+增量 | 兼顾优点 | 管理复杂 |

### 1.3 备份命令

**全量备份**：
```bash
# 执行全量备份
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd/snapshot-$(date +%Y%m%d).db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

**备份验证**：
```bash
# 验证备份文件
ETCDCTL_API=3 etcdctl snapshot status /backup/etcd/snapshot-20260508.db
```

## 二、备份存储策略

### 2.1 本地存储

**本地存储配置**：
```yaml
# 本地存储配置
local_storage:
  path: "/backup/etcd/"
  retention:
    full_backups: 7  # 保留7天全量备份
    incremental_backups: 30  # 保留30天增量备份
  compression:
    enabled: true
    algorithm: "gzip"
```

### 2.2 远程存储

**对象存储配置**：
```yaml
# 对象存储配置
remote_storage:
  type: "s3"
  bucket: "k8s-etcd-backup"
  region: "us-west-2"
  credentials:
    access_key: "AKIAIOSFODNN7EXAMPLE"
    secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
  encryption:
    enabled: true
    kms_key: "arn:aws:kms:us-west-2:123456789012:key/1234abcd-12ab-34cd-56ef-1234567890ab"
```

### 2.3 存储分层策略

**分层存储架构**：
```yaml
# 存储分层
storage_tier:
  tier1:
    type: "local"
    retention: "24h"
    purpose: "快速恢复"
  
  tier2:
    type: "nfs"
    retention: "7d"
    purpose: "短期备份"
  
  tier3:
    type: "s3"
    retention: "30d"
    purpose: "长期归档"
```

## 三、备份自动化

### 3.1 定时备份脚本

**备份脚本**：
```bash
#!/bin/bash
# etcd定时备份脚本

BACKUP_DIR="/backup/etcd"
SNAPSHOT_NAME="snapshot-$(date +%Y%m%d_%H%M%S).db"
RETENTION_DAYS=7

# 创建备份目录
mkdir -p ${BACKUP_DIR}

# 执行备份
ETCDCTL_API=3 etcdctl snapshot save ${BACKUP_DIR}/${SNAPSHOT_NAME} \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# 验证备份
ETCDCTL_API=3 etcdctl snapshot status ${BACKUP_DIR}/${SNAPSHOT_NAME}

# 压缩备份文件
gzip ${BACKUP_DIR}/${SNAPSHOT_NAME}

# 上传到S3
aws s3 cp ${BACKUP_DIR}/${SNAPSHOT_NAME}.gz s3://k8s-etcd-backup/

# 清理过期备份
find ${BACKUP_DIR} -name "*.db.gz" -type f -mtime +${RETENTION_DAYS} -delete
```

### 3.2 Cron配置

**Cron定时任务**：
```yaml
# Cron配置
cron:
  schedule: "0 2 * * *"  # 每天凌晨2点执行
  command: "/usr/local/bin/etcd-backup.sh"
  log_file: "/var/log/etcd-backup.log"
```

### 3.3 备份监控

**监控配置**：
```yaml
# 备份监控
monitoring:
  alerts:
    - name: "EtcdBackupFailed"
      condition: "backup_success == 0"
      severity: "critical"
      notification: ["slack", "pagerduty"]
    
    - name: "EtcdBackupRetention"
      condition: "backup_age > 24h"
      severity: "warning"
      notification: ["slack"]
```

## 四、恢复流程

### 4.1 恢复准备

**恢复前检查**：
```yaml
# 恢复检查清单
pre_restore_check:
  - "确认备份文件完整性"
  - "停止kube-apiserver服务"
  - "确认etcd集群状态"
  - "备份当前etcd数据"
```

### 4.2 单节点恢复

**恢复命令**：
```bash
# 停止kube-apiserver
systemctl stop kube-apiserver

# 恢复etcd数据
ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd/snapshot-20260508.db \
  --data-dir=/var/lib/etcd \
  --name=etcd-0 \
  --initial-cluster=etcd-0=https://192.168.1.10:2380 \
  --initial-advertise-peer-urls=https://192.168.1.10:2380

# 重启etcd
systemctl restart etcd

# 等待etcd启动
sleep 30

# 重启kube-apiserver
systemctl start kube-apiserver
```

### 4.3 集群恢复

**集群恢复配置**：
```yaml
# 集群恢复配置
cluster_restore:
  steps:
    1. "在所有节点停止kube-apiserver"
    2. "在第一个节点恢复etcd数据"
    3. "启动第一个节点的etcd"
    4. "在其他节点加入集群"
    5. "验证集群状态"
    6. "启动所有kube-apiserver"
```

## 五、备份验证

### 5.1 备份文件验证

**验证命令**：
```bash
# 验证备份文件
ETCDCTL_API=3 etcdctl snapshot status /backup/etcd/snapshot-20260508.db

# 输出示例
# +----------+----------+------------+------------+
# |  HASH    | REVISION | TOTAL KEYS | TOTAL SIZE |
# +----------+----------+------------+------------+
# | abc123   | 123456   | 10000      | 50MB       |
# +----------+----------+------------+------------+
```

### 5.2 恢复测试

**测试流程**：
```yaml
# 恢复测试流程
restore_test:
  steps:
    1. "创建测试Pod"
    2. "执行备份"
    3. "删除测试Pod"
    4. "从备份恢复"
    5. "验证测试Pod恢复"
    6. "清理测试环境"
```

## 六、安全考虑

### 6.1 加密存储

**加密配置**：
```yaml
# 加密配置
encryption:
  at_rest:
    enabled: true
    algorithm: "AES-256-GCM"
  
  in_transit:
    enabled: true
    tls_version: "1.3"
```

### 6.2 访问控制

**权限配置**：
```yaml
# 访问控制
access_control:
  backup_dir:
    owner: "root"
    group: "etcd"
    permissions: "700"
  
  s3_bucket:
    policy: "private"
    access_logging: true
```

## 七、实战案例分析

### 7.1 案例1：日常备份配置

**场景描述**：
- 需要配置每日自动备份
- 备份文件存储到S3

**配置方案**：
```yaml
# 备份配置
backup:
  schedule: "0 2 * * *"
  retention:
    local: 7 days
    s3: 30 days
  storage:
    local: "/backup/etcd"
    s3: "s3://k8s-etcd-backup"
```

### 7.2 案例2：灾难恢复

**场景描述**：
- etcd数据损坏
- 需要从备份恢复

**恢复步骤**：
1. 停止kube-apiserver
2. 验证备份文件
3. 执行恢复命令
4. 重启etcd
5. 重启kube-apiserver
6. 验证集群状态

## 八、面试1分钟精简版（直接背）

**完整版**：

我们使用etcd官方工具etcdctl进行快照备份。备份策略采用每日全量备份加增量备份的方式。备份文件首先保存在节点本地的/backup/etcd/目录作为临时存储，然后同步到对象存储如S3进行持久化保存。备份保留策略为保留最近7天的全量备份和30天的增量备份，确保数据安全和灾难恢复能力。

**30秒超短版**：

使用etcdctl进行快照备份，每日全量备份加增量备份，本地临时存储，远程对象存储持久化，保留7天全量和30天增量。

## 九、总结

### 9.1 核心要点

1. **备份工具**：使用etcd官方工具etcdctl
2. **备份策略**：全量+增量混合备份
3. **存储策略**：本地临时+远程持久化
4. **恢复流程**：停止API Server→恢复etcd→重启服务
5. **安全保障**：加密存储+访问控制

### 9.2 备份原则

| 原则 | 说明 |
|:----:|------|
| **定期执行** | 每日定时备份 |
| **多重存储** | 本地+远程存储 |
| **验证完整性** | 备份后验证 |
| **测试恢复** | 定期测试恢复流程 |
| **加密保护** | 数据加密存储 |

### 9.3 记忆口诀

```
etcd备份用etcdctl，全量增量相结合，
本地临时存一份，远程持久要安全，
每日定时自动做，验证恢复不能少。
```

> **参考链接**：[SRE运维面试题全解析：从理论到实践（第二部分）]({% post_url 2026-04-15-sre-interview-questions-part2 %})