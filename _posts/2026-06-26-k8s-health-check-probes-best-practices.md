---
layout: post
title: "K8s健康检查探针详解与最佳实践"
subtitle: "深入理解Liveness、Readiness和Startup探针的原理与应用"
date: 2026-06-26 10:00:00
author: "OpsOps"
header-img: "img/post-bg-probes.jpg"
catalog: true
tags:
  - Kubernetes
  - 健康检查
  - 探针配置
  - 最佳实践
---

## 一、引言

在Kubernetes中，健康检查是保障应用高可用性的核心机制。K8s提供了三种类型的探针：Liveness Probe（存活探针）、Readiness Probe（就绪探针）和Startup Probe（启动探针）。合理配置这些探针可以自动发现和恢复故障，确保只有健康的Pod接收流量。

本文将深入剖析这三种探针的原理、配置方法和最佳实践，帮助您构建更可靠的容器化应用。

---

## 二、SCQA分析框架

### 情境（Situation）
- 容器化应用需要高可用性保障
- 应用可能出现死循环、启动缓慢等问题
- 需要自动化的故障检测和恢复机制

### 冲突（Complication）
- 应用启动时间不确定，可能导致误判重启
- 未就绪的Pod可能接收流量导致服务不可用
- 探针配置不当可能加剧问题

### 问题（Question）
- 三种探针各自的作用是什么？
- 如何正确配置探针参数？
- 生产环境中有哪些最佳实践？
- 如何排查探针相关的问题？

### 答案（Answer）
- Liveness检测存活状态，Readiness检测就绪状态，Startup处理慢启动
- 根据应用特性调整initialDelaySeconds、periodSeconds等参数
- 为所有容器配置探针，慢启动应用添加Startup Probe
- 通过kubectl describe和日志排查探针问题

---

## 三、三种探针详解

### 3.1 Liveness Probe（存活探针）

**核心作用**：检测容器是否存活，失败则重启容器

**设计目标**：防止应用陷入死循环或无响应状态，自动恢复故障容器

**工作原理**：
```
容器启动 → 等待initialDelaySeconds → 每隔periodSeconds探测一次
         → 连续failureThreshold次失败 → 重启容器
         → 成功则继续运行
```

**配置示例**：
```yaml
spec:
  containers:
  - name: app
    image: myapp:latest
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
        httpHeaders:
        - name: X-Custom-Header
          value: health-check
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
      successThreshold: 1
```

**探针类型对比**：

| 类型 | 实现方式 | 适用场景 | 优点 | 缺点 |
|:------|:------|:------|:------|:------|
| **httpGet** | 发送HTTP请求 | Web应用、API服务 | 支持复杂检查逻辑 | 需要暴露健康检查端点 |
| **tcpSocket** | 尝试TCP连接 | 数据库、MQ、gRPC | 简单通用 | 只能检测端口是否监听 |
| **exec** | 执行命令 | 自定义检查逻辑 | 灵活性高 | 增加容器复杂度 |

---

### 3.2 Readiness Probe（就绪探针）

**核心作用**：检测容器是否就绪，未就绪则从Service Endpoint移除

**设计目标**：确保只有准备好处理请求的Pod才能接收流量

**工作原理**：
```
容器启动 → 等待initialDelaySeconds → 每隔periodSeconds探测一次
         → 未就绪 → Pod状态为NotReady → 从Service Endpoint移除
         → 就绪 → Pod状态为Ready → 加入Service Endpoint → 接收流量
```

**配置示例**：
```yaml
spec:
  containers:
  - name: app
    image: myapp:latest
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 3
      successThreshold: 2
```

**就绪探针的重要场景**：

| 场景 | 说明 | 示例 |
|:------|:------|:------|
| **应用初始化** | 数据库连接池建立、配置加载 | Spring Boot应用启动 |
| **依赖服务检查** | 等待数据库、MQ就绪 | 微服务依赖其他服务 |
| **滚动更新** | 新版本就绪后才切换流量 | Kubernetes滚动更新 |
| **服务降级** | 主动设置为未就绪状态 | 熔断或限流场景 |

---

### 3.3 Startup Probe（启动探针）

**核心作用**：检测应用是否启动完成，处理慢启动场景

**设计目标**：保护慢启动应用不被Liveness Probe误判重启

**工作原理**：
```
容器启动 → 每隔periodSeconds探测一次
         → 连续failureThreshold次失败 → 继续等待（不重启）
         → 成功 → 停止启动探针 → 开始Liveness/Readiness探针
```

**配置示例**：
```yaml
spec:
  containers:
  - name: slow-app
    image: slow-app:latest
    startupProbe:
      httpGet:
        path: /healthz
        port: 8080
      failureThreshold: 30
      periodSeconds: 10
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      periodSeconds: 5
```

**启动探针适用场景**：

| 应用类型 | 典型启动时间 | 是否需要Startup Probe |
|:------|:------|:------|
| **简单Web应用** | < 30秒 | 通常不需要 |
| **大型Java应用** | 1-5分钟 | **强烈建议** |
| **数据库** | 1-3分钟 | **强烈建议** |
| **缓存服务** | 30秒-2分钟 | 建议 |
| **消息队列** | 30秒-1分钟 | 建议 |

---

## 四、三种探针配合工作机制

### 4.1 工作流程

```
┌─────────────────────────────────────────────────────────────────┐
│                    探针配合工作流程                            │
├─────────────────────────────────────────────────────────────────┤
│                                                               │
│  Pod启动                                                       │
│     │                                                          │
│     ▼                                                          │
│  ┌─────────────────────────────────────────┐                   │
│  │         Startup Probe                  │                   │
│  │  (保护慢启动应用，防止误判重启)         │                   │
│  │  failureThreshold × periodSeconds     │                   │
│  │  = 最大等待时间（如30×10=300秒）       │                   │
│  └────────────────┬──────────────────────┘                   │
│                   │ 成功                                       │
│                   ▼                                            │
│  ┌─────────────────────────────────────────┐                   │
│  │  Liveness Probe + Readiness Probe      │                   │
│  │         并行执行                        │                   │
│  └───────────────┬───────────┬────────────┘                   │
│                  │           │                                │
│                  ▼           ▼                                │
│           ┌────────┐   ┌──────────┐                          │
│           │Liveness│   │ Readiness│                          │
│           │ 失败   │   │  失败    │                          │
│           ▼        │   ▼          │                          │
│      重启容器      │   移除Endpoint                          │
│                   │               │                          │
│                   ▼               ▼                          │
│              继续运行        加入Endpoint                      │
│                             接收流量                          │
│                                                               │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 探针状态组合

| Liveness | Readiness | Pod状态 | 行为 |
|:------|:------|:------|:------|
| 成功 | 成功 | Running/Ready | 正常接收流量 |
| 成功 | 失败 | Running/NotReady | 运行中但不接收流量 |
| 失败 | - | 重启中 | 容器重启 |
| 启动中 | - | Running/NotReady | Startup Probe执行中 |

---

## 五、配置参数深度解析

### 5.1 参数详解

| 参数 | 作用 | 默认值 | 推荐设置 |
|:------|:------|:------|:------|
| **initialDelaySeconds** | 容器启动后多久开始探测 | 0秒 | 根据应用启动时间设置 |
| **periodSeconds** | 探测间隔时间 | 10秒 | 生产环境建议10-30秒 |
| **timeoutSeconds** | 探测超时时间 | 1秒 | 根据网络延迟调整，建议2-5秒 |
| **failureThreshold** | 连续失败触发动作的次数 | 3次 | Liveness建议3-5次 |
| **successThreshold** | 连续成功确认健康的次数 | 1次 | Readiness建议2次以上 |

### 5.2 参数配置策略

**策略一：根据应用类型调整**

| 应用类型 | initialDelaySeconds | periodSeconds | failureThreshold |
|:------|:------|:------|:------|
| **快速启动Web应用** | 10-20秒 | 10秒 | 3 |
| **Java应用** | 30-60秒 | 10-15秒 | 3-5 |
| **数据库** | 60-120秒 | 15-30秒 | 5-10 |
| **慢启动服务** | 使用Startup Probe | 10-15秒 | 3-5 |

**策略二：平衡探测频率**

```
探测频率 = periodSeconds × failureThreshold

建议：
- Liveness探测频率：30-60秒（避免频繁重启）
- Readiness探测频率：10-30秒（快速发现未就绪状态）
- Startup探测频率：根据启动时间计算
```

---

## 六、生产环境最佳实践

### 6.1 配置模板

**标准Web应用配置**：
```yaml
spec:
  containers:
  - name: web-app
    image: web-app:latest
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 20
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
      successThreshold: 2
```

**慢启动应用配置**：
```yaml
spec:
  containers:
  - name: slow-app
    image: slow-app:latest
    startupProbe:
      httpGet:
        path: /healthz
        port: 8080
      failureThreshold: 30    # 最多等待300秒
      periodSeconds: 10
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 10
      periodSeconds: 10
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
```

**数据库配置**：
```yaml
spec:
  containers:
  - name: mysql
    image: mysql:8.0
    startupProbe:
      tcpSocket:
        port: 3306
      failureThreshold: 20    # 最多等待200秒
      periodSeconds: 10
    livenessProbe:
      tcpSocket:
        port: 3306
      periodSeconds: 15
    readinessProbe:
      tcpSocket:
        port: 3306
      periodSeconds: 5
```

### 6.2 健康检查端点设计

**最佳实践**：

1. **独立的健康检查端点**：
   - `/healthz`：用于Liveness检测，检查应用核心功能
   - `/ready`：用于Readiness检测，检查所有依赖是否就绪

2. **返回状态码**：
   - 200-399：成功
   - 400-599：失败

3. **检查内容**：
   - **Liveness**：检查应用进程是否正常运行
   - **Readiness**：检查数据库连接、缓存连接、外部依赖等

**示例实现（Spring Boot）**：
```java
@RestController
public class HealthController {
    
    @Autowired
    private DataSource dataSource;
    
    @GetMapping("/healthz")
    public ResponseEntity<String> healthz() {
        return ResponseEntity.ok("OK");
    }
    
    @GetMapping("/ready")
    public ResponseEntity<String> ready() {
        try {
            // 检查数据库连接
            Connection conn = dataSource.getConnection();
            conn.close();
            return ResponseEntity.ok("READY");
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                               .body("NOT READY: " + e.getMessage());
        }
    }
}
```

### 6.3 监控告警配置

**Prometheus规则示例**：
```yaml
groups:
- name: k8s-probes
  rules:
  - alert: LivenessProbeFailing
    expr: kube_pod_container_status_liveness_probe_failed == 1
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "Pod Liveness Probe失败"
      description: "Pod {{ $labels.pod }} 的Liveness Probe持续失败"

  - alert: ReadinessProbeFailing
    expr: kube_pod_container_status_readiness_probe_failed == 1
    for: 2m
    labels:
      severity: warning
    annotations:
      summary: "Pod Readiness Probe失败"
      description: "Pod {{ $labels.pod }} 的Readiness Probe持续失败"

  - alert: ContainerRestartingFrequent
    expr: increase(kube_pod_container_status_restarts_total[5m]) > 3
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "容器频繁重启"
      description: "Pod {{ $labels.pod }} 的容器在5分钟内重启超过3次"
```

---

## 七、常见问题与排查

### 7.1 问题诊断流程

```
探针问题排查流程：
1. 查看Pod状态 → kubectl get pod <pod-name>
2. 查看事件 → kubectl describe pod <pod-name>
3. 查看探针配置 → kubectl get pod <pod-name> -o yaml | grep -A 20 probe
4. 手动测试探针 → curl http://<pod-ip>:<port>/healthz
5. 查看应用日志 → kubectl logs <pod-name>
6. 检查网络连通性 → kubectl exec <pod-name> -- ping <host>
```

### 7.2 常见问题解决

| 问题现象 | 可能原因 | 排查方法 | 解决方案 |
|:------|:------|:------|:------|
| **Pod频繁重启** | Liveness Probe初始延迟太短 | `kubectl describe pod`查看重启原因 | 增加initialDelaySeconds |
| **Pod一直NotReady** | Readiness Probe失败 | `kubectl describe pod`查看事件 | 检查就绪端点，调整配置 |
| **应用启动被中断** | 缺少Startup Probe | `kubectl logs <pod-name> --previous` | 添加Startup Probe |
| **探针超时** | timeoutSeconds设置过小 | `kubectl describe pod`查看超时事件 | 增加timeoutSeconds |
| **探针日志过多** | periodSeconds设置过小 | 查看kubelet日志 | 增大periodSeconds |
| **TCP探针失败** | 端口未监听或被防火墙阻止 | `kubectl exec -it <pod> -- nc -zv localhost <port>` | 检查应用端口配置 |

### 7.3 排查命令速查

```bash
# 查看Pod状态
kubectl get pod <pod-name> -o wide

# 查看Pod详细信息和事件
kubectl describe pod <pod-name>

# 查看探针配置
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[0].livenessProbe}'

# 手动测试HTTP探针
kubectl exec -it <pod-name> -- curl -v http://localhost:8080/healthz

# 查看容器重启次数
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].restartCount}'

# 查看kubelet日志（节点上执行）
journalctl -u kubelet -f
```

---

## 八、总结

### 核心要点

1. **三种探针各司其职**：
   - **Liveness**：保障容器存活，失败重启
   - **Readiness**：保障服务就绪，失败移除流量
   - **Startup**：保护慢启动应用，防止误判

2. **配置原则**：
   - 为所有容器配置Liveness和Readiness探针
   - 慢启动应用必须添加Startup Probe
   - 根据应用特性调整参数

3. **监控告警**：
   - 监控探针状态变化
   - 设置合理的告警阈值

4. **排查技巧**：
   - 通过describe查看事件
   - 手动测试探针端点
   - 结合日志分析问题

### 最佳实践清单

- ✅ 为每个容器配置Liveness和Readiness探针
- ✅ 慢启动应用添加Startup Probe
- ✅ 使用独立的健康检查端点（/healthz, /ready）
- ✅ 合理设置initialDelaySeconds，避免启动中误判
- ✅ Readiness设置successThreshold≥2，避免抖动
- ✅ 配置探针相关的监控告警
- ✅ 定期审查探针配置，根据应用变化调整

> 本文对应的面试题：[存活探针、启动探针、就绪探针，这些是什么作用？]({% post_url 2026-04-15-sre-interview-questions %})

---

## 附录：配置示例汇总

### HTTP探针完整配置
```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
    scheme: HTTP
    httpHeaders:
    - name: X-Health-Check
      value: kubernetes
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
  successThreshold: 1
```

### TCP探针完整配置
```yaml
livenessProbe:
  tcpSocket:
    port: 3306
  initialDelaySeconds: 60
  periodSeconds: 15
  timeoutSeconds: 3
  failureThreshold: 5
```

### Exec探针完整配置
```yaml
livenessProbe:
  exec:
    command:
    - /bin/sh
    - -c
    - |
      # 检查应用进程是否正常
      if ps aux | grep -q "[m]yapp"; then
        exit 0
      else
        exit 1
      fi
  initialDelaySeconds: 15
  periodSeconds: 5
```
