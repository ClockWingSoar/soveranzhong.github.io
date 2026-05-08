# Harbor镜像仓库高可用部署：从单机到企业级架构

## 情境与背景

Harbor是企业级容器镜像仓库的首选方案，提供了镜像存储、安全扫描、访问控制等企业级功能。作为高级DevOps/SRE工程师，需要掌握Harbor的版本选择、部署模式和协议配置。本文从DevOps/SRE视角，详细讲解Harbor高可用部署的最佳实践。

## 一、Harbor版本选择

### 1.1 版本对比

**版本特性对比**：

| 版本 | 发布时间 | 关键特性 | 稳定性 |
|:----:|----------|----------|:------:|
| **v2.10.x** | 2024年 | 支持OCI镜像、增强安全扫描 | 稳定 |
| **v2.9.x** | 2023年 | 增强多租户支持 | 稳定 |
| **v2.8.x** | 2023年 | 支持S3存储后端 | 稳定 |
| **v2.7.x** | 2022年 | 支持Notary V2 | 稳定 |

### 1.2 版本选择建议

**选择原则**：
```yaml
# 版本选择建议
version_selection:
  production: "v2.10.x"    # 生产环境使用最新稳定版
  staging: "v2.10.x"       # 预发环境与生产保持一致
  development: "v2.9.x"    # 开发环境可使用上一稳定版
  
  upgrade_strategy:
    frequency: "quarterly"  # 每季度升级一次
    testing: "staging环境验证"
    rollback_plan: "保留旧版本镜像"
```

## 二、Harbor部署模式

### 2.1 单机部署

**适用场景**：
- 开发环境
- 小型团队
- 资源受限环境

**部署配置**：
```yaml
# 单机部署配置
standalone:
  hosts:
    - "harbor-dev.example.com"
  
  resources:
    cpu: "4"
    memory: "8Gi"
    storage: "100Gi"
  
  components:
    - core
    - registry
    - database
    - redis
    - jobservice
```

### 2.2 高可用部署

**适用场景**：
- 生产环境
- 大规模镜像存储
- 高并发访问需求

**架构设计**：
```yaml
# 高可用架构配置
ha_deployment:
  nodes: 3
  
  load_balancer:
    type: "nginx"
    health_check: "/api/v2.0/health"
  
  components:
    core:
      replicas: 3
      resources:
        cpu: "2"
        memory: "4Gi"
    
    registry:
      replicas: 3
      resources:
        cpu: "4"
        memory: "8Gi"
    
    database:
      type: "PostgreSQL"
      replicas: 3
      replication: "multi-master"
    
    redis:
      type: "Redis Cluster"
      replicas: 6
    
    storage:
      type: "S3"
      provider: "MinIO"
      replicas: 4
```

### 2.3 高可用架构图

**架构示意**：

```mermaid
flowchart TB
    A["客户端"] --> B["Nginx LB"]
    
    B --> C["Harbor Core 1"]
    B --> D["Harbor Core 2"]
    B --> E["Harbor Core 3"]
    
    C --> F["PostgreSQL Cluster"]
    D --> F
    E --> F
    
    C --> G["Redis Cluster"]
    D --> G
    E --> G
    
    C --> H["S3 Storage"]
    D --> H
    E --> H
    
    style B fill:#ffcdd2
    style F fill:#c8e6c9
    style G fill:#fff3e0
    style H fill:#e3f2fd
```

## 三、协议配置

### 3.1 HTTPS配置

**SSL证书配置**：
```yaml
# HTTPS配置
https:
  enabled: true
  
  certificate:
    issuer: "Let's Encrypt"
    domain: "harbor.example.com"
    renewal: "auto"
  
  cipher_suites:
    - "TLS_AES_256_GCM_SHA384"
    - "TLS_CHACHA20_POLY1305_SHA256"
    - "TLS_AES_128_GCM_SHA256"
  
  tls_version: "TLSv1.3"
```

**Nginx配置**：
```nginx
server {
    listen 443 ssl http2;
    server_name harbor.example.com;
    
    ssl_certificate /etc/nginx/certs/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/privkey.pem;
    
    ssl_protocols TLSv1.3 TLSv1.2;
    ssl_ciphers TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256;
    
    location / {
        proxy_pass http://harbor-core;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 3.2 HTTP配置

**HTTP配置（不推荐）**：
```yaml
# HTTP配置（仅用于内部网络）
http:
  enabled: false
  port: 80
  
  # 仅在内部网络使用
  allowed_ips:
    - "10.0.0.0/8"
    - "172.16.0.0/12"
    - "192.168.0.0/16"
```

## 四、存储配置

### 4.1 存储后端选择

**存储后端对比**：

| 存储类型 | 优点 | 缺点 | 适用场景 |
|:--------:|------|------|----------|
| **本地存储** | 简单、性能好 | 不支持HA | 开发环境 |
| **NFS** | 共享存储 | 单点故障 | 中小型部署 |
| **S3兼容** | 高可用、可扩展 | 配置复杂 | 生产环境 |
| **Ceph RBD** | 高性能、高可用 | 运维复杂 | 大型企业 |

### 4.2 S3存储配置

**MinIO配置**：
```yaml
# MinIO配置
minio:
  mode: "distributed"
  nodes: 4
  drives_per_node: 4
  
  resources:
    cpu: "2"
    memory: "4Gi"
    storage: "10Ti"
  
  security:
    tls: true
    access_key: "minioadmin"
    secret_key: "minioadmin"
  
  buckets:
    - name: "harbor-registry"
      versioning: true
      retention: "90d"
```

**Harbor存储配置**：
```yaml
# Harbor存储配置
storage:
  type: "s3"
  
  s3:
    endpoint: "https://minio.example.com"
    bucket: "harbor-registry"
    access_key: "AKIAIOSFODNN7EXAMPLE"
    secret_key: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
    region: "us-east-1"
    secure: true
```

## 五、数据库配置

### 5.1 PostgreSQL配置

**高可用配置**：
```yaml
# PostgreSQL配置
postgresql:
  version: "15"
  replicas: 3
  
  resources:
    cpu: "2"
    memory: "4Gi"
    storage: "100Gi"
  
  replication:
    type: "patroni"
    mode: "multi-master"
  
  backup:
    schedule: "0 2 * * *"
    retention: "7 days"
    destination: "s3://postgresql-backup"
```

### 5.2 Redis配置

**Cluster配置**：
```yaml
# Redis配置
redis:
  version: "7.0"
  replicas: 6
  shards: 3
  
  resources:
    cpu: "1"
    memory: "2Gi"
  
  persistence:
    enabled: true
    type: "rdb"
    backup_schedule: "every 1 hour"
```

## 六、安全配置

### 6.1 漏洞扫描配置

**Trivy配置**：
```yaml
# Trivy扫描配置
scanning:
  enabled: true
  provider: "trivy"
  
  policies:
    - name: "block_high_critical"
      severity: ["HIGH", "CRITICAL"]
      action: "block"
    
    - name: "warn_medium"
      severity: ["MEDIUM"]
      action: "warn"
  
  schedule:
    scan_on_push: true
    daily_scan: true
```

### 6.2 镜像签名配置

**Notary配置**：
```yaml
# Notary配置
notary:
  enabled: true
  version: "v2"
  
  sign_policy:
    require_signature: true
    trust_key_type: "ecdsa"
  
  rotation:
    enabled: true
    frequency: "monthly"
```

### 6.3 访问控制配置

**RBAC配置**：
```yaml
# RBAC配置
rbac:
  enabled: true
  
  roles:
    - name: "admin"
      permissions: ["*"]
      
    - name: "project-admin"
      permissions: ["project:*"]
      
    - name: "developer"
      permissions: ["project:pull", "project:push"]
      
    - name: "viewer"
      permissions: ["project:pull"]
```

## 七、监控与告警

### 7.1 监控指标

**关键指标**：

| 指标类型 | 指标名称 | 告警阈值 |
|:--------:|----------|----------|
| **可用性** | 服务健康状态 | != healthy |
| **性能** | 请求延迟 | > 500ms |
| **存储** | 存储空间使用率 | > 85% |
| **数据库** | 连接数 | > 80% |
| **Redis** | 内存使用率 | > 85% |

### 7.2 告警配置

**告警规则**：
```yaml
# 告警规则
alerts:
  - name: "harbor_unhealthy"
    expr: "harbor_core_health != 1"
    severity: "critical"
    notification: ["pagerduty", "slack"]
  
  - name: "storage_usage_high"
    expr: "harbor_storage_usage > 85"
    severity: "warning"
    notification: ["slack", "email"]
```

## 八、备份与恢复

### 8.1 备份策略

**备份配置**：
```yaml
# 备份配置
backup:
  schedule: "0 2 * * *"
  retention:
    daily: 7
    weekly: 4
    monthly: 12
  
  components:
    - database
    - registry
    - config
  
  destination:
    type: "s3"
    bucket: "harbor-backup"
    encryption: true
```

### 8.2 恢复流程

**恢复步骤**：
```bash
#!/bin/bash
# Harbor恢复脚本

# 1. 停止Harbor服务
docker-compose down

# 2. 恢复数据库
pg_restore -d harbor -U postgres /backup/harbor_db.sql

# 3. 恢复存储
aws s3 sync s3://harbor-backup/registry /data/registry

# 4. 启动Harbor服务
docker-compose up -d

# 5. 验证恢复
curl -I https://harbor.example.com/api/v2.0/health
```

## 九、实战案例分析

### 9.1 案例1：Harbor升级

**场景描述**：
- 需要从v2.9.x升级到v2.10.x
- 零停机升级

**升级流程**：
```bash
# 升级步骤
# 1. 备份数据
harbor backup

# 2. 停止旧版本
docker-compose down

# 3. 升级Harbor
./install.sh --with-notary --with-clair

# 4. 启动新版本
docker-compose up -d

# 5. 验证升级
curl https://harbor.example.com/api/v2.0/systeminfo
```

### 9.2 案例2：存储迁移

**场景描述**：
- 从本地存储迁移到S3
- 在线迁移

**迁移流程**：
```bash
# 迁移步骤
# 1. 配置S3存储后端
harbor configure --storage=s3

# 2. 同步镜像
harbor sync --from=local --to=s3

# 3. 切换存储后端
harbor switch --storage=s3

# 4. 验证迁移
harbor check --storage=s3
```

## 十、面试1分钟精简版（直接背）

**完整版**：

我们当前使用的Harbor版本是v2.10.0，采用高可用部署模式，通过Nginx负载均衡实现多节点集群。协议方面，我们配置了HTTPS，使用SSL证书加密传输。存储后端采用S3兼容存储（MinIO），支持数据冗余备份。数据库使用PostgreSQL多主复制，确保数据高可用。这种架构能够支撑大规模镜像存储和高并发访问需求。

**30秒超短版**：

Harbor版本v2.10.0，高可用部署，HTTPS协议，S3存储，PostgreSQL多主复制。

## 十一、总结

### 11.1 核心要点

1. **版本选择**：生产环境使用最新稳定版
2. **部署模式**：高可用架构支撑生产环境
3. **协议配置**：HTTPS加密传输
4. **存储后端**：S3兼容存储保证高可用
5. **数据库**：PostgreSQL多主复制

### 11.2 部署原则

| 原则 | 说明 |
|:----:|------|
| **高可用** | 多节点集群部署 |
| **安全** | HTTPS + 漏洞扫描 + 镜像签名 |
| **可扩展** | S3兼容存储 |
| **可恢复** | 定期备份 + 恢复演练 |

### 11.3 记忆口诀

```
Harbor版本看官方，高可用用多节点，
协议首选HTTPS，存储后端用S3，
数据库用PostgreSQL，安全扫描Trivy。
```

> **参考链接**：[SRE运维面试题全解析：从理论到实践（第二部分）]({% post_url 2026-04-15-sre-interview-questions-part2 %})