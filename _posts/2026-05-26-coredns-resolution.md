---
layout: post
title: "CoreDNS域名解析深度解析：从原理到故障排查"
date: 2026-05-26 10:00:00 +0800
categories: [SRE, Kubernetes, 网络]
tags: [CoreDNS, 域名解析, 网络, 故障排查, 性能优化]
---

# CoreDNS域名解析深度解析：从原理到故障排查

## 情境(Situation)

CoreDNS是Kubernetes集群中的默认DNS服务，负责将服务名解析为IP地址，是服务发现的核心组件。在现代容器化架构中，DNS解析的可靠性和性能直接影响整个集群的运行状态。

作为SRE工程师，我们需要深入理解CoreDNS的域名解析流程，掌握其配置、优化和故障排查方法，确保集群网络的稳定运行。

## 冲突(Conflict)

在实际应用中，SRE工程师经常面临以下挑战：

- **DNS解析失败**：导致服务无法正常通信
- **解析延迟**：影响应用性能
- **CoreDNS负载过高**：导致解析服务不可用
- **配置复杂**：不同场景需要不同的DNS策略
- **故障排查困难**：DNS问题可能由多种原因引起

## 问题(Question)

如何理解CoreDNS的域名解析流程，优化其性能，确保DNS服务的可靠性，并快速排查DNS相关问题？

## 答案(Answer)

本文将从SRE视角出发，详细分析CoreDNS的域名解析流程，包括解析原理、配置方法、性能优化、故障排查和最佳实践，帮助SRE工程师掌握CoreDNS的核心技术，确保集群网络的稳定运行。核心方法论基于 [SRE面试题解析：coreDNS的域名解析流程是啥？]({% post_url 2026-04-15-sre-interview-questions %}#79-coreDNS的域名解析流程是啥)。

---

## 一、CoreDNS概述

### 1.1 什么是CoreDNS

**CoreDNS**：
- Kubernetes集群中的默认DNS服务
- 负责将服务名解析为IP地址
- 基于插件架构，可扩展
- 支持多种DNS记录类型

### 1.2 CoreDNS的作用

**CoreDNS的作用**：
- 服务发现：解析服务名到ClusterIP
- Pod解析：解析Pod名到Pod IP
- 外部DNS：转发外部域名查询
- 健康检查：提供自身健康状态
- 监控：暴露Prometheus指标

---

## 二、域名解析流程

### 2.1 解析流程详解

**CoreDNS域名解析流程**：

1. **Pod发起DNS查询**
   - Pod的`/etc/resolv.conf`由kubelet自动配置，指向kube-dns Service
   - 应用程序通过系统调用发起DNS查询
   - 查询请求格式：`service-name.namespace.svc.cluster.local`

2. **请求到达kube-dns Service**
   - 请求发送到kube-dns Service的ClusterIP（默认10.96.0.10）
   - kube-proxy将请求转发到后端CoreDNS Pod
   - 负载均衡到多个CoreDNS副本

3. **CoreDNS处理查询**
   - **内部服务**：从Kubernetes API获取Service和Pod信息，直接返回ClusterIP或Pod IP
   - **外部服务**：根据配置的上游DNS服务器进行递归查询
   - **缓存查询**：检查本地缓存，提高性能

4. **响应返回**
   - CoreDNS将解析结果返回给Pod
   - 应用程序获取IP地址，建立网络连接
   - 结果被缓存，减少后续查询延迟

**流程图**：

```mermaid
flowchart TD
    A[Pod] --> B[/etc/resolv.conf]
    B --> C[kube-dns Service]
    C --> D[CoreDNS Pod]
    D --> E{查询类型}
    E -->|内部服务| F[Kubernetes API]
    E -->|外部服务| G[上游DNS]
    E -->|缓存查询| H[本地缓存]
    F --> I[返回解析结果]
    G --> I
    H --> I
    I --> D
    D --> C
    C --> A
```

### 2.2 DNS查询示例

**内部服务解析**：
- 服务名：`my-service.default.svc.cluster.local`
- 解析过程：CoreDNS从Kubernetes API获取Service信息，返回ClusterIP
- 结果：`10.96.1.1`

**外部服务解析**：
- 域名：`www.example.com`
- 解析过程：CoreDNS转发到上游DNS服务器
- 结果：`93.184.216.34`

---

## 三、CoreDNS配置

### 3.1 Corefile配置

**CoreDNS配置（Corefile）**：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        prometheus :9153
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }
```

**配置解析**：

| 指令 | 作用 |
|:------|:------|
| `errors` | 记录错误信息 |
| `health` | 健康检查端点 |
| `ready` | 就绪检查端点 |
| `kubernetes` | Kubernetes服务发现插件 |
| `prometheus` | 暴露Prometheus指标 |
| `forward` | 转发外部DNS查询 |
| `cache` | DNS缓存，默认30秒 |
| `loop` | 检测DNS循环 |
| `reload` | 自动重载配置 |
| `loadbalance` | 负载均衡查询 |

### 3.2 Pod DNS配置

**Pod DNS配置**：

```bash
# 查看Pod的DNS配置
kubectl exec -it <pod-name> -- cat /etc/resolv.conf

# 输出示例
nameserver 10.96.0.10
search default.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
```

**配置解析**：

| 配置 | 作用 |
|:------|:------|
| `nameserver` | DNS服务器地址（kube-dns Service的ClusterIP） |
| `search` | 搜索域，用于简化服务名解析 |
| `options ndots:5` | 控制DNS查询行为，当域名包含的点少于5个时，会尝试添加搜索域 |

### 3.3 DNS策略

**DNS策略**：

| 策略 | 说明 | 适用场景 |
|:------|:------|:------|
| **ClusterFirst** | 优先使用集群DNS | 大多数场景 |
| **Default** | 使用宿主机DNS | 不需要集群内部服务发现 |
| **ClusterFirstWithHostNet** | 适用于hostNetwork Pod | 使用hostNetwork的Pod |
| **None** | 完全自定义 | 需要配合dnsConfig使用 |

**DNS策略配置**：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dns-example
spec:
  containers:
  - name: dns-example
    image: nginx
  dnsPolicy: ClusterFirst
  dnsConfig:
    nameservers:
    - 10.96.0.10
    searches:
    - default.svc.cluster.local
    - svc.cluster.local
    options:
    - name: ndots
      value: "5"
```

---

## 四、性能优化

### 4.1 NodeLocal DNSCache

**NodeLocal DNSCache**：
- 在每个节点上运行本地DNS缓存
- 减少CoreDNS负载
- 降低DNS解析延迟
- 提高解析成功率

**部署NodeLocal DNSCache**：

```bash
# 下载部署文件
wget https://github.com/kubernetes/kubernetes/blob/master/cluster/addons/dns/nodelocaldns/nodelocaldns.yaml

# 修改配置中的clusterDNS和imageRepository
# 部署
kubectl apply -f nodelocaldns.yaml
```

**配置示例**：

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-local-dns
  namespace: kube-system
spec:
  selector:
    matchLabels:
      k8s-app: node-local-dns
  template:
    metadata:
      labels:
        k8s-app: node-local-dns
    spec:
      containers:
      - name: node-cache
        image: k8s.gcr.io/dns/k8s-dns-node-cache:1.17.0
        args:
        - -localip=169.254.20.10
        - -conf=/etc/Corefile
        - -upstreamsvc=kube-dns
        volumeMounts:
        - name: config
          mountPath: /etc
      volumes:
      - name: config
        configMap:
          name: node-local-dns
```

### 4.2 缓存优化

**缓存优化**：
- 调整缓存时间：`cache 60`（默认30秒）
- 增加缓存大小：`cache {size 10000}`
- 启用预取：`cache {prefetch 5}`

**配置示例**：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        # ...
        cache {
            success 60
            denial 10
            prefetch 5
            ttl 30
            size 10000
        }
        # ...
    }
```

### 4.3 资源配置

**资源配置**：
- 为CoreDNS Pod配置合理的资源限制
- 根据集群规模调整副本数
- 使用Horizontal Pod Autoscaler

**配置示例**：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: coredns
  namespace: kube-system
spec:
  replicas: 2
  selector:
    matchLabels:
      k8s-app: kube-dns
  template:
    metadata:
      labels:
        k8s-app: kube-dns
    spec:
      containers:
      - name: coredns
        image: k8s.gcr.io/coredns:1.8.0
        resources:
          requests:
            cpu: 100m
            memory: 70Mi
          limits:
            cpu: 500m
            memory: 512Mi
```

### 4.4 ndots参数优化

**ndots参数优化**：
- 调整Pod的ndots参数，平衡搜索域和直接查询
- 对于内部服务，建议使用ndots:5
- 对于外部服务，建议使用ndots:1

**配置示例**：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: external-app
spec:
  containers:
  - name: external-app
    image: nginx
  dnsConfig:
    options:
    - name: ndots
      value: "1"
```

---

## 五、故障排查

### 5.1 常见问题

**常见DNS问题**：

- **解析失败**：服务名不存在或配置错误
- **解析延迟**：CoreDNS负载过高或缓存未命中
- **CoreDNS不可用**：Pod崩溃或资源不足
- **网络问题**：Pod无法访问CoreDNS
- **配置错误**：Corefile配置不当

### 5.2 排查步骤

**DNS故障排查步骤**：

1. **检查CoreDNS状态**：
   ```bash
   kubectl get pods -n kube-system -l k8s-app=kube-dns
   kubectl describe pods -n kube-system -l k8s-app=kube-dns
   ```

2. **测试DNS解析**：
   ```bash
   # 在Pod中测试
   kubectl exec -it <pod-name> -- nslookup kubernetes.default
   
   # 直接测试CoreDNS
   kubectl run -it --rm --image=busybox:1.28 busybox -- nslookup kubernetes.default
   ```

3. **查看CoreDNS日志**：
   ```bash
   kubectl logs -n kube-system -l k8s-app=kube-dns
   ```

4. **检查网络连接**：
   ```bash
   # 测试Pod到CoreDNS的连接
   kubectl exec -it <pod-name> -- ping 10.96.0.10
   kubectl exec -it <pod-name> -- telnet 10.96.0.10 53
   ```

5. **检查CoreDNS配置**：
   ```bash
   kubectl get configmap coredns -n kube-system -o yaml
   ```

6. **检查NodeLocal DNSCache**：
   ```bash
   kubectl get pods -n kube-system -l k8s-app=node-local-dns
   kubectl logs -n kube-system -l k8s-app=node-local-dns
   ```

### 5.3 故障案例

**案例一：CoreDNS Pod崩溃**

**症状**：DNS解析失败，Pod无法解析服务名

**排查**：
1. 检查CoreDNS Pod状态：`kubectl get pods -n kube-system -l k8s-app=kube-dns`
2. 查看Pod日志：`kubectl logs -n kube-system <coredns-pod>`
3. 检查资源使用：`kubectl top pods -n kube-system -l k8s-app=kube-dns`

**解决方案**：
- 增加CoreDNS Pod的资源限制
- 启用Horizontal Pod Autoscaler
- 检查是否有内存泄漏

**案例二：解析延迟高**

**症状**：DNS解析时间长，影响应用性能

**排查**：
1. 测试解析时间：`kubectl exec -it <pod-name> -- time nslookup kubernetes.default`
2. 查看CoreDNS缓存命中率：`kubectl exec -it <coredns-pod> -n kube-system -- curl http://localhost:9153/metrics | grep cache_hit_ratio`
3. 检查CoreDNS负载：`kubectl top pods -n kube-system -l k8s-app=kube-dns`

**解决方案**：
- 启用NodeLocal DNSCache
- 调整缓存时间和大小
- 增加CoreDNS副本数

**案例三：外部域名解析失败**

**症状**：内部服务解析正常，外部域名解析失败

**排查**：
1. 测试外部域名解析：`kubectl exec -it <pod-name> -- nslookup www.example.com`
2. 检查CoreDNS配置：`kubectl get configmap coredns -n kube-system -o yaml`
3. 检查上游DNS服务器：`kubectl exec -it <coredns-pod> -n kube-system -- cat /etc/resolv.conf`

**解决方案**：
- 配置正确的上游DNS服务器
- 检查网络连接到上游DNS
- 调整forward插件配置

---

## 六、监控与告警

### 6.1 监控指标

**CoreDNS监控指标**：

- **请求指标**：
  - `coredns_dns_requests_total`：总请求数
  - `coredns_dns_requests_duration_seconds`：请求延迟
  - `coredns_dns_cache_hit_ratio`：缓存命中率
  - `coredns_dns_response_rcode_total`：响应状态码

- **健康指标**：
  - `coredns_health_requests_total`：健康检查请求数
  - `coredns_health_status`：健康状态

- **资源指标**：
  - `container_cpu_usage_seconds_total`：CPU使用
  - `container_memory_usage_bytes`：内存使用

### 6.2 告警规则

**告警规则**：

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: coredns-alerts
  namespace: monitoring
spec:
  groups:
  - name: coredns
    rules:
    - alert: CoreDNSDown
      expr: kube_deployment_status_replicas_available{deployment="coredns", namespace="kube-system"} < 1
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "CoreDNS down"
        description: "CoreDNS deployment in namespace kube-system has no available replicas."

    - alert: CoreDNSHighRequestRate
      expr: rate(coredns_dns_requests_total[5m]) > 1000
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "CoreDNS high request rate"
        description: "CoreDNS is receiving more than 1000 requests per second."

    - alert: CoreDNSHighLatency
      expr: histogram_quantile(0.99, sum(rate(coredns_dns_requests_duration_seconds_bucket[5m])) by (le)) > 0.1
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "CoreDNS high latency"
        description: "CoreDNS 99th percentile latency is above 100ms."

    - alert: CoreDNSCacheMissHigh
      expr: 1 - (sum(rate(coredns_dns_cache_hits_total[5m])) / sum(rate(coredns_dns_requests_total[5m]))) > 0.5
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "CoreDNS high cache miss rate"
        description: "CoreDNS cache miss rate is above 50%."

    - alert: CoreDNSErrorHigh
      expr: sum(rate(coredns_dns_response_rcode_total{rcode=~"SERVFAIL|NXDOMAIN"}[5m])) / sum(rate(coredns_dns_requests_total[5m])) > 0.1
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "CoreDNS high error rate"
        description: "CoreDNS error rate is above 10%."
```

### 6.3 监控Dashboard

**Grafana Dashboard**：
- **DNS请求面板**：显示请求总数、延迟分布、缓存命中率
- **CoreDNS状态面板**：显示Pod状态、资源使用
- **错误率面板**：显示解析错误率、错误类型分布
- **NodeLocal DNSCache面板**：显示本地缓存状态、命中率

**Dashboard配置**：
- 数据源：Prometheus
- 时间范围：过去24小时
- 自动刷新：30秒
- 告警通知：Slack、Email

---

## 七、最佳实践

### 7.1 部署最佳实践

**部署最佳实践**：

- [ ] **多副本部署**：
  - 至少2个CoreDNS副本确保高可用
  - 分布在不同节点上
  - 使用Pod反亲和性

- [ ] **资源配置**：
  - 合理设置CPU和内存请求与限制
  - 根据集群规模调整
  - 使用Horizontal Pod Autoscaler

- [ ] **NodeLocal DNSCache**：
  - 在所有节点上部署
  - 配置正确的本地IP
  - 监控缓存命中率

### 7.2 配置最佳实践

**配置最佳实践**：

- [ ] **Corefile配置**：
  - 启用必要的插件
  - 调整缓存时间和大小
  - 配置合适的上游DNS服务器

- [ ] **Pod DNS配置**：
  - 根据应用需求选择合适的DNS策略
  - 调整ndots参数
  - 配置适当的搜索域

- [ ] **安全配置**：
  - 限制CoreDNS的网络访问
  - 使用网络策略
  - 定期更新CoreDNS版本

### 7.3 维护最佳实践

**维护最佳实践**：

- [ ] **定期检查**：
  - 检查CoreDNS Pod状态
  - 监控解析成功率和延迟
  - 查看日志中的错误信息

- [ ] **备份配置**：
  - 备份CoreDNS ConfigMap
  - 记录DNS策略配置
  - 保存告警规则

- [ ] **升级策略**：
  - 定期升级CoreDNS版本
  - 测试新版本兼容性
  - 滚动升级避免服务中断

---

## 八、案例分析

### 8.1 案例一：大规模集群DNS优化

**需求**：
- 大规模Kubernetes集群（1000+节点）
- DNS解析延迟高
- CoreDNS负载过重

**解决方案**：
- 部署NodeLocal DNSCache
- 调整CoreDNS缓存配置
- 增加CoreDNS副本数
- 优化ndots参数

**配置**：

```yaml
# NodeLocal DNSCache配置
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-local-dns
  namespace: kube-system
spec:
  # ...

# CoreDNS配置
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        prometheus :9153
        forward . /etc/resolv.conf
        cache {
            success 60
            denial 10
            prefetch 5
            ttl 30
            size 10000
        }
        loop
        reload
        loadbalance
    }
```

**效果**：
- DNS解析延迟从50ms降低到5ms
- CoreDNS负载减少80%
- 解析成功率达到99.99%

### 8.2 案例二：DNS故障排查

**问题**：
- Pod无法解析服务名
- 应用启动失败

**排查过程**：
1. 检查CoreDNS状态：`kubectl get pods -n kube-system -l k8s-app=kube-dns`
   - 发现CoreDNS Pod处于CrashLoopBackOff状态
2. 查看Pod日志：`kubectl logs -n kube-system <coredns-pod>`
   - 错误信息：`failed to list *v1.Endpoints: Get "https://10.96.0.1:443/api/v1/endpoints?limit=500&resourceVersion=0": dial tcp 10.96.0.1:443: i/o timeout`
3. 检查网络连接：`kubectl exec -it <coredns-pod> -n kube-system -- ping 10.96.0.1`
   - 网络连接正常
4. 检查RBAC权限：`kubectl get clusterrolebinding | grep coredns`
   - 发现CoreDNS的ClusterRoleBinding缺失

**解决方案**：
- 重新创建CoreDNS的RBAC权限
- 重启CoreDNS Pod
- 验证DNS解析：`kubectl exec -it <test-pod> -- nslookup kubernetes.default`

**效果**：
- CoreDNS Pod恢复正常
- DNS解析成功
- 应用启动正常

### 8.3 案例三：外部DNS配置

**需求**：
- 集群需要访问外部服务
- 外部DNS解析速度慢

**解决方案**：
- 配置多个上游DNS服务器
- 启用缓存优化
- 监控外部DNS解析性能

**配置**：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        prometheus :9153
        forward . 8.8.8.8 8.8.4.4 1.1.1.1 {
            health_check 5s
            max_concurrent 1000
        }
        cache {
            success 120
            denial 30
            prefetch 5
            ttl 60
            size 20000
        }
        loop
        reload
        loadbalance
    }
```

**效果**：
- 外部DNS解析速度提高50%
- 解析成功率达到99.9%
- 减少对单一DNS服务器的依赖

---

## 九、最佳实践总结

### 9.1 性能优化

**性能优化最佳实践**：

- [ ] **启用NodeLocal DNSCache**：减少CoreDNS负载，降低延迟
- [ ] **调整缓存配置**：增加缓存时间和大小，提高命中率
- [ ] **合理配置资源**：根据集群规模调整CoreDNS资源限制
- [ ] **优化ndots参数**：平衡搜索域和直接查询
- [ ] **多副本部署**：确保高可用，分散负载

### 9.2 故障排查

**故障排查最佳实践**：

- [ ] **系统性排查**：从CoreDNS状态到网络连接，逐步定位问题
- [ ] **测试解析**：使用nslookup命令测试DNS解析
- [ ] **查看日志**：分析CoreDNS日志中的错误信息
- [ ] **检查配置**：验证Corefile配置和Pod DNS设置
- [ ] **监控指标**：关注解析成功率、延迟和错误率

### 9.3 监控与告警

**监控与告警最佳实践**：

- [ ] **设置关键指标监控**：请求数、延迟、缓存命中率、错误率
- [ ] **配置告警规则**：CoreDNS不可用、高请求率、高延迟、高错误率
- [ ] **实现可视化监控**：Grafana Dashboard展示DNS性能
- [ ] **定期检查**：定期检查CoreDNS状态和性能

### 9.4 配置管理

**配置管理最佳实践**：

- [ ] **版本控制**：使用Git管理CoreDNS配置
- [ ] **备份配置**：定期备份CoreDNS ConfigMap
- [ ] **配置测试**：在测试环境验证配置变更
- [ ] **文档化**：记录DNS策略和配置变更

---

## 总结

CoreDNS是Kubernetes集群中服务发现的核心组件，其域名解析的可靠性和性能直接影响整个集群的运行状态。通过本文的详细介绍，我们可以掌握CoreDNS的域名解析流程、配置方法、性能优化和故障排查技巧，确保集群网络的稳定运行。

**核心要点**：

1. **解析流程**：Pod发起查询 → kube-dns转发 → CoreDNS处理 → 返回结果
2. **性能优化**：启用NodeLocal DNSCache、调整缓存配置、合理配置资源
3. **故障排查**：系统性排查，从CoreDNS状态到网络连接，逐步定位问题
4. **监控与告警**：设置关键指标监控，配置告警规则，实现可视化监控
5. **最佳实践**：多副本部署、合理配置资源、定期检查、备份配置

通过遵循这些最佳实践，我们可以确保CoreDNS的稳定运行，提高DNS解析性能，减少故障发生，为集群应用提供可靠的服务发现能力。

> **延伸学习**：更多面试相关的CoreDNS知识，请参考 [SRE面试题解析：coreDNS的域名解析流程是啥？]({% post_url 2026-04-15-sre-interview-questions %}#79-coreDNS的域名解析流程是啥)。

---

## 参考资料

- [CoreDNS官方文档](https://coredns.io/)
- [Kubernetes DNS文档](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [NodeLocal DNSCache文档](https://kubernetes.io/docs/tasks/administer-cluster/nodelocaldns/)
- [CoreDNS插件文档](https://coredns.io/plugins/)
- [Kubernetes网络故障排查](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-service/)
- [DNS性能优化](https://www.dnsperf.com/)
- [Prometheus监控](https://prometheus.io/docs/introduction/overview/)
- [Grafana监控](https://grafana.com/docs/grafana/latest/)
- [Kubernetes最佳实践](https://kubernetes.io/docs/concepts/configuration/overview/)
- [Kubernetes网络最佳实践](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Kubernetes安全最佳实践](https://kubernetes.io/docs/concepts/security/)
- [Kubernetes性能调优](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Kubernetes集群管理](https://kubernetes.io/docs/concepts/cluster-administration/)
- [Kubernetes网络](https://kubernetes.io/docs/concepts/cluster-administration/networking/)
- [DNS原理](https://en.wikipedia.org/wiki/Domain_Name_System)
- [DNS缓存](https://en.wikipedia.org/wiki/DNS_cache)
- [DNSSEC](https://en.wikipedia.org/wiki/DNSSEC)
- [EDNS0](https://en.wikipedia.org/wiki/Extension_Mechanisms_for_DNS)
- [DNS over HTTPS](https://en.wikipedia.org/wiki/DNS_over_HTTPS)
- [DNS over TLS](https://en.wikipedia.org/wiki/DNS_over_TLS)
- [Service discovery](https://en.wikipedia.org/wiki/Service_discovery)
- [Kubernetes service](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Kubernetes pod](https://kubernetes.io/docs/concepts/workloads/pods/)
- [Kubernetes namespace](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
- [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Kubernetes ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Kubernetes DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)
- [Kubernetes Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Kubernetes Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Kubernetes network policy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)