# DevOps常用服务端口速查与生产环境配置最佳实践

## 情境与背景

在DevOps运维工作中，掌握常用服务的默认端口配置是基础技能。无论是配置防火墙规则、设置网络策略，还是排查服务通信问题，都需要对常用端口有清晰的了解。本博客系统整理了DevOps生态中常用服务的端口配置和生产环境最佳实践。

## 一、ELK日志栈端口

### 1.1 Elasticsearch

**端口配置**：

| 端口 | 协议 | 用途 |
|:----:|------|------|
| **9200** | HTTP | RESTful API客户端通信 |
| **9300** | TCP | 集群节点间通信 |

**配置示例**：

```yaml
# elasticsearch.yml
network.host: 0.0.0.0
http.port: 9200
transport.port: 9300
discovery.seed_hosts: ["es-node1:9300", "es-node2:9300"]
cluster.initial_master_nodes: ["es-node1"]
```

**生产环境建议**：

```yaml
production_best_practices:
  - "绑定到内网IP，不暴露到公网"
  - "配置TLS/SSL加密通信"
  - "设置防火墙规则限制访问"
  - "使用反向代理（Nginx）暴露9200端口"
```

### 1.2 Kibana

**端口配置**：

| 端口 | 协议 | 用途 |
|:----:|------|------|
| **5601** | HTTP | Web界面访问 |

**配置示例**：

```yaml
# kibana.yml
server.host: "0.0.0.0"
server.port: 5601
elasticsearch.hosts: ["http://elasticsearch:9200"]
```

**生产环境建议**：

```yaml
production_best_practices:
  - "通过Nginx反向代理访问"
  - "启用HTTPS加密"
  - "配置身份认证"
  - "限制访问IP范围"
```

### 1.3 Logstash

**端口配置**：

| 端口 | 协议 | 用途 |
|:----:|------|------|
| **5044** | TCP | Beats数据输入 |
| **9600** | HTTP | 监控API |

**配置示例**：

```yaml
# logstash.yml
http.host: "0.0.0.0"
http.port: 9600

# logstash.conf
input {
  beats {
    port => 5044
  }
}
```

**生产环境建议**：

```yaml
production_best_practices:
  - "配置TLS加密传输"
  - "设置客户端证书认证"
  - "限制来源IP"
  - "监控数据吞吐量"
```

## 二、Kubernetes端口

### 2.1 Kubernetes核心端口

**端口配置**：

| 端口 | 协议 | 用途 |
|:----:|------|------|
| **6443** | HTTPS | API Server |
| **2379** | HTTP | etcd客户端 |
| **2380** | HTTPS | etcd集群通信 |
| **10250** | HTTPS | Kubelet API |
| **10251** | HTTP | Scheduler |
| **10252** | HTTP | Controller Manager |
| **30000-32767** | TCP | NodePort服务 |

**配置示例**：

```yaml
# API Server配置
apiVersion: v1
kind: Service
metadata:
  name: kubernetes
  namespace: default
spec:
  ports:
  - name: https
    port: 443
    protocol: TCP
    targetPort: 6443
```

**生产环境建议**：

```yaml
production_best_practices:
  - "API Server仅内网访问"
  - "配置RBAC权限控制"
  - "启用审计日志"
  - "etcd配置TLS加密"
  - "限制NodePort范围"
```

### 2.2 容器运行时端口

**端口配置**：

| 端口 | 协议 | 用途 |
|:----:|------|------|
| **2375** | HTTP | Docker API（不安全） |
| **2376** | HTTPS | Docker API（安全） |
| **10250** | HTTPS | Containerd API |

**生产环境建议**：

```yaml
production_best_practices:
  - "禁用2375端口，仅使用2376"
  - "配置TLS双向认证"
  - "限制访问来源"
  - "使用Unix Socket替代网络端口"
```

## 三、数据库端口

### 3.1 关系型数据库

**端口配置**：

| 数据库 | 端口 | 协议 |
|:------:|------|------|
| **MySQL** | 3306 | TCP |
| **PostgreSQL** | 5432 | TCP |
| **SQL Server** | 1433 | TCP |
| **Oracle** | 1521 | TCP |

**MySQL配置示例**：

```ini
# my.cnf
[mysqld]
port = 3306
bind-address = 0.0.0.0
```

**生产环境建议**：

```yaml
production_best_practices:
  - "仅绑定到内网IP"
  - "配置SSL/TLS加密"
  - "限制访问IP"
  - "配置防火墙规则"
  - "定期更新密码"
```

### 3.2 NoSQL数据库

**端口配置**：

| 数据库 | 端口 | 协议 |
|:------:|------|------|
| **Redis** | 6379 | TCP |
| **MongoDB** | 27017 | TCP |
| **Cassandra** | 9042 | TCP |
| **Elasticsearch** | 9200/9300 | HTTP/TCP |

**Redis配置示例**：

```ini
# redis.conf
port 6379
bind 0.0.0.0
requirepass yourpassword
```

**生产环境建议**：

```yaml
production_best_practices:
  - "配置密码认证"
  - "禁用危险命令"
  - "配置AOF持久化"
  - "限制访问IP"
  - "使用TLS加密"
```

## 四、监控与可视化端口

### 4.1 Prometheus

**端口配置**：

| 端口 | 协议 | 用途 |
|:----:|------|------|
| **9090** | HTTP | Web UI和API |
| **9091** | HTTP | Pushgateway（可选） |

**配置示例**：

```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
```

**生产环境建议**：

```yaml
production_best_practices:
  - "配置认证和授权"
  - "启用HTTPS"
  - "配置数据持久化"
  - "配置告警规则"
  - "限制访问IP"
```

### 4.2 Grafana

**端口配置**：

| 端口 | 协议 | 用途 |
|:----:|------|------|
| **3000** | HTTP | Web界面 |

**配置示例**：

```ini
# grafana.ini
[server]
http_port = 3000

[auth.anonymous]
enabled = false

[security]
admin_password = yourpassword
```

**生产环境建议**：

```yaml
production_best_practices:
  - "配置身份认证"
  - "启用HTTPS"
  - "配置数据源认证"
  - "配置权限管理"
  - "定期备份数据"
```

## 五、CI/CD端口

### 5.1 Jenkins

**端口配置**：

| 端口 | 协议 | 用途 |
|:----:|------|------|
| **8080** | HTTP | Web界面 |
| **50000** | TCP | Agent通信 |

**配置示例**：

```bash
# Jenkins启动命令
java -jar jenkins.war --httpPort=8080 --agentPort=50000
```

**生产环境建议**：

```yaml
production_best_practices:
  - "配置反向代理"
  - "启用HTTPS"
  - "配置安全插件"
  - "限制Agent访问"
  - "配置备份策略"
```

### 5.2 GitLab

**端口配置**：

| 端口 | 协议 | 用途 |
|:----:|------|------|
| **80** | HTTP | Web界面 |
| **443** | HTTPS | Web界面（安全） |
| **22** | SSH | Git操作 |
| **9090** | HTTP | GitLab Pages |

**生产环境建议**：

```yaml
production_best_practices:
  - "强制使用HTTPS"
  - "配置SSH密钥认证"
  - "配置备份策略"
  - "配置CI/CD Runner"
  - "限制访问权限"
```

## 六、Web服务器端口

### 6.1 Nginx

**端口配置**：

| 端口 | 协议 | 用途 |
|:----:|------|------|
| **80** | HTTP | Web服务 |
| **443** | HTTPS | Web服务（安全） |

**配置示例**：

```nginx
server {
    listen 80;
    server_name example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name example.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
}
```

### 6.2 Apache

**端口配置**：

| 端口 | 协议 | 用途 |
|:----:|------|------|
| **80** | HTTP | Web服务 |
| **443** | HTTPS | Web服务（安全） |

## 七、镜像仓库端口

### 7.1 Harbor

**端口配置**：

| 端口 | 协议 | 用途 |
|:----:|------|------|
| **80** | HTTP | Web界面（不推荐） |
| **443** | HTTPS | Web界面和镜像推送 |
| **8080** | HTTP | Notary（内容信任） |

**生产环境建议**：

```yaml
production_best_practices:
  - "强制使用HTTPS"
  - "配置镜像扫描"
  - "配置访问控制"
  - "配置高可用"
  - "定期清理镜像"
```

## 八、端口速查表

### 8.1 完整端口列表

| 服务 | 端口 | 协议 | 类别 |
|:----:|------|------|------|
| Elasticsearch | 9200/9300 | HTTP/TCP | 日志栈 |
| Kibana | 5601 | HTTP | 日志栈 |
| Logstash | 5044/9600 | TCP/HTTP | 日志栈 |
| Kubernetes API | 6443 | HTTPS | 容器编排 |
| etcd | 2379/2380 | HTTP/HTTPS | 容器编排 |
| Kubelet | 10250 | HTTPS | 容器编排 |
| Docker | 2375/2376 | HTTP/HTTPS | 容器运行时 |
| MySQL | 3306 | TCP | 数据库 |
| PostgreSQL | 5432 | TCP | 数据库 |
| Redis | 6379 | TCP | 数据库 |
| MongoDB | 27017 | TCP | 数据库 |
| Prometheus | 9090 | HTTP | 监控 |
| Grafana | 3000 | HTTP | 监控 |
| Jenkins | 8080/50000 | TCP | CI/CD |
| GitLab | 80/443/22 | HTTP/HTTPS/SSH | CI/CD |
| Nginx | 80/443 | HTTP/HTTPS | Web服务器 |
| Harbor | 80/443/8080 | HTTP/HTTPS | 镜像仓库 |

## 九、生产环境最佳实践

### 9.1 防火墙配置

**iptables示例**：

```bash
# 允许SSH
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# 允许HTTP/HTTPS
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# 允许Kubernetes API（仅内网）
iptables -A INPUT -p tcp -s 10.0.0.0/8 --dport 6443 -j ACCEPT

# 允许MySQL（仅内网）
iptables -A INPUT -p tcp -s 10.0.0.0/8 --dport 3306 -j ACCEPT

# 拒绝其他连接
iptables -A INPUT -j DROP
```

### 9.2 网络策略配置

**Kubernetes NetworkPolicy示例**：

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-elasticsearch
spec:
  podSelector:
    matchLabels:
      app: elasticsearch
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - ports:
    - port: 9200
      protocol: TCP
    - port: 9300
      protocol: TCP
    from:
    - podSelector:
        matchLabels:
          app: kibana
    - podSelector:
        matchLabels:
          app: logstash
```

### 9.3 安全建议

**安全配置清单**：

```yaml
security_checklist:
  - "禁用不安全的端口（如Docker 2375）"
  - "使用TLS/SSL加密通信"
  - "配置防火墙规则限制访问"
  - "限制端口访问的IP范围"
  - "配置身份认证和授权"
  - "定期更新服务版本"
  - "监控端口访问日志"
  - "配置端口扫描告警"
```

## 十、面试1分钟精简版（直接背）

**完整版**：

ELK栈常用端口：Elasticsearch 9200（HTTP客户端）、9300（集群通信）；Kibana 5601（Web界面）；Logstash 5044（数据输入）、9600（监控API）。其他DevOps软件：Kubernetes API 6443、etcd 2379/2380、MySQL 3306、Redis 6379、Prometheus 9090、Grafana 3000、Jenkins 8080、Nginx 80/443、Docker 2375/2376、Harbor 80/443/8080。这些端口需要配置防火墙规则和网络策略。

**30秒超短版**：

ES 9200/9300，Kibana 5601，Logstash 5044/9600，K8s 6443，MySQL 3306，Redis 6379，Prometheus 9090，Grafana 3000。

## 十一、总结

### 11.1 端口分类速查

```yaml
port_categories:
  日志栈:
    - "Elasticsearch: 9200/9300"
    - "Kibana: 5601"
    - "Logstash: 5044/9600"
    
  容器编排:
    - "Kubernetes API: 6443"
    - "etcd: 2379/2380"
    - "Docker: 2375/2376"
    
  数据库:
    - "MySQL: 3306"
    - "PostgreSQL: 5432"
    - "Redis: 6379"
    - "MongoDB: 27017"
    
  监控:
    - "Prometheus: 9090"
    - "Grafana: 3000"
    
  CI/CD:
    - "Jenkins: 8080/50000"
    - "GitLab: 80/443/22"
```

### 11.2 最佳实践清单

```yaml
best_practices:
  - "使用内网IP绑定，避免暴露到公网"
  - "启用TLS/SSL加密"
  - "配置防火墙规则限制访问"
  - "禁用不安全的端口"
  - "配置身份认证和授权"
  - "监控端口访问日志"
  - "定期更新服务版本"
```

### 11.3 记忆口诀

```
端口配置要记牢，ES九二零九三零，
Kibana五六零一，Logstash五零四四，
K8s六四四三，MySQL三三零六，
Redis六三七九，Prometheus九零九零，
Grafana三零零零，Jenkins八零八零，
安全配置不能少，防火墙规则要配好。
```

> **参考链接**：[SRE运维面试题全解析：从理论到实践（第二部分）]({% post_url 2026-04-15-sre-interview-questions-part2 %})