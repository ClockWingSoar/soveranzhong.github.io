---
layout: post
title: "K8s网络故障排查指南与最佳实践"
subtitle: "容器内部正常但外部无法访问的完整解决方案"
date: 2026-06-23 10:00:00
author: "OpsOps"
header-img: "img/post-bg-network.jpg"
catalog: true
tags:
  - Kubernetes
  - 网络故障
  - Service
  - Ingress
  - 故障排查
---

## 一、引言

在Kubernetes集群中，网络问题是最常见的故障类型之一。当容器内部服务互相调用正常但外部无法访问时，问题通常出在Service配置、Ingress配置、网络策略或防火墙规则等层面。本文将提供一套系统化的排查方法，帮助您快速定位并解决这类网络问题。

---

## 二、SCQA分析框架

### 情境（Situation）
- Pod之间可以正常通信
- 外部请求无法访问服务
- 需要快速定位网络故障点

### 冲突（Complication）
- 网络链路涉及多个组件
- 配置错误可能发生在多个层面
- 日志分散，难以快速定位

### 问题（Question）
- 为什么内部能通外部不通？
- 如何快速排查网络问题？
- Service、Ingress、NetworkPolicy各自的作用是什么？
- 常见的网络配置错误有哪些？

### 答案（Answer）
- 内部通外部不通通常是Service或Ingress配置问题
- 排查顺序：从外到内，逐步定位
- 关键检查点：Service类型、Endpoint状态、Pod就绪状态、Ingress规则、网络策略

---

## 三、网络访问链路分析

### 3.1 外部访问流程图

```
┌─────────────────────────────────────────────────────────────────┐
│                    外部访问完整链路                              │
├─────────────────────────────────────────────────────────────────┤
│                                                               │
│  外部客户端                                                     │
│      │                                                         │
│      │ HTTP/HTTPS                                              │
│      ▼                                                         │
│  ┌──────────────┐                                             │
│  │   Ingress    │  (可选，用于域名访问)                        │
│  │ Controller   │                                             │
│  └──────┬───────┘                                             │
│         │                                                      │
│         ▼                                                      │
│  ┌──────────────┐                                             │
│  │   Service    │  (ClusterIP/NodePort/LoadBalancer)          │
│  │              │                                             │
│  └──────┬───────┘                                             │
│         │                                                      │
│         ▼                                                      │
│  ┌──────────────┐                                             │
│  │  Endpoint    │  (Pod IP列表)                               │
│  └──────┬───────┘                                             │
│         │                                                      │
│         ▼                                                      │
│  ┌──────────────┐                                             │
│  │    Pod       │  (容器应用)                                  │
│  └──────────────┘                                             │
│                                                               │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 链路检查清单

| 检查点 | 检查内容 | 工具命令 |
|:------|:------|:------|
| **Ingress** | Controller状态、规则配置 | `kubectl get ingress`, `kubectl describe ingress` |
| **Service** | 类型、端口配置、selector | `kubectl get service`, `kubectl describe service` |
| **Endpoint** | Pod列表、端口状态 | `kubectl get endpoints` |
| **Pod** | 状态、就绪探针、日志 | `kubectl get pod`, `kubectl describe pod` |
| **网络策略** | 是否禁止入站流量 | `kubectl get networkpolicy` |
| **节点网络** | 防火墙、安全组 | `iptables`, `nc`, `telnet` |
| **DNS解析** | Service DNS、外部DNS | `nslookup`, `dig` |

---

## 四、排查步骤详解

### 4.1 第一步：检查Service配置

**检查Service类型**：
```bash
kubectl get service <service-name>

# 输出示例：
# NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
# web-service   ClusterIP   10.96.100.200   <none>        80/TCP         10m
```

**Service类型对比**：

| 类型 | 外部访问方式 | 适用场景 |
|:------|:------|:------|
| **ClusterIP** | 不可直接访问 | 仅内部服务调用 |
| **NodePort** | 节点IP:NodePort | 开发测试环境 |
| **LoadBalancer** | LoadBalancer IP | 生产环境 |
| **ExternalName** | 外部域名 | 访问外部服务 |

**检查Endpoint状态**：
```bash
kubectl get endpoints <service-name>

# 正常输出应包含Pod IP：
# NAME          ENDPOINTS                           AGE
# web-service   10.244.0.10:8080,10.244.1.5:8080   10m

# 如果ENDPOINTS列为空，说明Pod标签与Service selector不匹配
```

**检查标签匹配**：
```bash
# 查看Service的selector
kubectl get service <service-name> -o jsonpath='{.spec.selector}'

# 查看Pod标签
kubectl get pod <pod-name> --show-labels
```

### 4.2 第二步：检查Pod状态

**检查Pod状态**：
```bash
kubectl get pod <pod-name> -o wide

# 关注READY列：
# - 1/1：Pod就绪，可接收流量
# - 0/1：Pod未就绪，不会被加入Endpoint
```

**检查Readiness Probe**：
```bash
kubectl describe pod <pod-name> | grep -A 10 Readiness

# 查看探针配置和状态
```

**进入Pod内部测试**：
```bash
# 在Pod内部访问服务
kubectl exec -it <pod-name> -- curl localhost:8080

# 从其他Pod访问
kubectl exec -it <another-pod> -- curl <pod-ip>:8080

# 使用Service名称访问
kubectl exec -it <another-pod> -- curl http://<service-name>:<port>
```

### 4.3 第三步：检查Ingress配置（如果使用）

**检查Ingress规则**：
```bash
kubectl get ingress <ingress-name> -o yaml

# 重点检查：
# - spec.rules[].host：域名是否正确
# - spec.rules[].http.paths[].backend.service：Service名称和端口是否正确
```

**检查Ingress Controller状态**：
```bash
# 检查Ingress Controller Pod
kubectl get pods -n ingress-nginx

# 查看日志
kubectl logs -n ingress-nginx <ingress-controller-pod>
```

**测试Ingress访问**：
```bash
# 添加hosts解析
echo "<node-ip> example.com" >> /etc/hosts

# 测试访问
curl http://example.com
```

### 4.4 第四步：检查网络策略

**查看NetworkPolicy**：
```bash
kubectl get networkpolicy

# 如果存在deny-all策略，可能会阻止外部访问
```

**检查策略内容**：
```bash
kubectl describe networkpolicy <policy-name>

# 关注：
# - podSelector：策略应用的Pod
# - ingress.from：允许的来源
```

**临时禁用NetworkPolicy测试**：
```bash
# 删除NetworkPolicy测试
kubectl delete networkpolicy <policy-name>

# 如果删除后可以访问，说明策略配置有问题
```

### 4.5 第五步：检查节点网络

**检查NodePort**：
```bash
# 获取NodePort
kubectl get service <service-name> -o jsonpath='{.spec.ports[0].nodePort}'

# 测试节点端口
nc -zv <node-ip> <node-port>
telnet <node-ip> <node-port>
```

**检查防火墙规则**：
```bash
# 检查iptables规则
iptables -L -n | grep <node-port>

# 检查firewalld
firewall-cmd --list-all | grep <node-port>

# 云平台检查安全组
# AWS: EC2 Console -> Security Groups
# GCP: Cloud Console -> Firewall Rules
# Azure: Portal -> Network Security Groups
```

**检查CNI插件**：
```bash
# 检查Calico状态
kubectl get pods -n kube-system -l k8s-app=calico-node

# 检查Flannel状态
kubectl get pods -n kube-system -l app=flannel
```

### 4.6 第六步：检查DNS解析

**检查Service DNS**：
```bash
kubectl exec -it <pod-name> -- nslookup <service-name>.<namespace>.svc.cluster.local

# 正常输出应包含Service的ClusterIP
```

**检查CoreDNS状态**：
```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns

# 查看日志
kubectl logs -n kube-system <coredns-pod>
```

---

## 五、常见问题与解决方案

### 问题一：Service没有Endpoint

**现象**：
```bash
kubectl get endpoints web-service
# NAME          ENDPOINTS   AGE
# web-service   <none>      10m
```

**原因**：Pod标签与Service selector不匹配

**解决方案**：
```bash
# 检查Service selector
kubectl get service web-service -o jsonpath='{.spec.selector}'
# {"app":"web"}

# 检查Pod标签
kubectl get pod web-pod --show-labels
# NAME      READY   STATUS    LABELS
# web-pod   1/1     Running   app=nginx  # 标签不匹配！

# 修改Pod标签或Service selector
kubectl label pod web-pod app=web --overwrite
```

### 问题二：Pod未就绪

**现象**：
```bash
kubectl get pod web-pod
# NAME      READY   STATUS    RESTARTS   AGE
# web-pod   0/1     Running   0          5m
```

**原因**：Readiness Probe失败

**解决方案**：
```bash
# 查看Pod事件
kubectl describe pod web-pod | grep -A 5 "Readiness probe"

# 检查应用健康端点
kubectl exec -it web-pod -- curl localhost:8080/ready

# 调整Probe配置
kubectl patch deployment web-deployment -p '{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "web",
            "readinessProbe": {
              "httpGet": {
                "path": "/health",
                "port": 8080
              },
              "initialDelaySeconds": 10,
              "periodSeconds": 5
            }
          }
        ]
      }
    }
  }
}'
```

### 问题三：Ingress无法访问

**现象**：
```bash
curl http://example.com
# curl: (7) Failed to connect to example.com port 80: Connection refused
```

**原因**：Ingress Controller未部署或配置错误

**解决方案**：
```bash
# 检查Ingress Controller
kubectl get pods -n ingress-nginx

# 如果未部署，安装Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

# 检查Ingress规则
kubectl describe ingress web-ingress
```

### 问题四：NodePort无法访问

**现象**：
```bash
curl http://<node-ip>:<node-port>
# curl: (7) Failed to connect to <node-ip> port <node-port>: Connection refused
```

**原因**：防火墙规则阻止或安全组未开放

**解决方案**：
```bash
# 检查iptables
iptables -L -n | grep <node-port>

# 开放端口
iptables -A INPUT -p tcp --dport <node-port> -j ACCEPT

# 云平台安全组配置
# 添加入站规则：允许TCP <node-port>
```

### 问题五：网络策略阻止访问

**现象**：
```bash
# 删除NetworkPolicy前无法访问
curl http://<service-ip>
# curl: (52) Empty reply from server

# 删除NetworkPolicy后可以访问
kubectl delete networkpolicy deny-all
curl http://<service-ip>
# OK
```

**原因**：NetworkPolicy禁止入站流量

**解决方案**：
```bash
# 修改NetworkPolicy允许必要的流量
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
  - Ingress
  ingress:
  - from: []  # 允许所有入站流量
    ports:
    - protocol: TCP
      port: 80
EOF
```

---

## 六、生产环境最佳实践

### 6.1 Service配置最佳实践

**使用ClusterIP作为默认类型**：
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  type: ClusterIP  # 内部服务使用ClusterIP
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 8080
```

**对外服务使用Ingress**：
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - example.com
    secretName: example-tls
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

### 6.2 健康检查最佳实践

**配置完整的探针**：
```yaml
spec:
  containers:
  - name: app
    image: myapp:latest
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 3
      successThreshold: 2
```

### 6.3 网络策略最佳实践

**默认允许，按需限制**：
```yaml
# 默认允许所有流量
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-allow
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress: []
  egress: []
```

**针对敏感服务限制访问**：
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: restrict-db-access
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 3306
```

### 6.4 监控告警最佳实践

**关键指标监控**：
```yaml
groups:
- name: network.rules
  rules:
  - alert: ServiceNoEndpoints
    expr: kube_endpoint_address_available == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Service没有Endpoint"
      description: "Service {{ $labels.service }} 的Endpoint数量为0"

  - alert: PodNotReady
    expr: kube_pod_status_ready{condition="false"} == 1
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Pod未就绪"
      description: "Pod {{ $labels.pod }} 状态为未就绪"

  - alert: IngressNotReady
    expr: kube_ingress_status_ready == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Ingress未就绪"
      description: "Ingress {{ $labels.ingress }} 状态为未就绪"
```

---

## 七、排查工具总结

### kubectl命令

| 命令 | 用途 |
|:------|:------|
| `kubectl get service` | 查看Service配置 |
| `kubectl get endpoints` | 查看Endpoint状态 |
| `kubectl get pod` | 查看Pod状态 |
| `kubectl describe` | 查看资源详细信息 |
| `kubectl exec` | 在Pod内部执行命令 |
| `kubectl logs` | 查看Pod日志 |

### 网络测试工具

| 工具 | 用途 |
|:------|:------|
| `curl` | HTTP请求测试 |
| `nc` | TCP/UDP端口测试 |
| `telnet` | 端口连通性测试 |
| `nslookup` | DNS解析测试 |
| `dig` | DNS详细查询 |

---

## 八、总结

### 排查流程

1. **检查Service**：确认类型、Endpoint状态、标签匹配
2. **检查Pod**：确认状态、Readiness Probe、应用日志
3. **检查Ingress**：确认Controller状态、规则配置
4. **检查网络策略**：确认是否阻止流量
5. **检查节点网络**：确认防火墙、安全组、CNI状态
6. **检查DNS**：确认Service DNS解析

### 最佳实践

| 实践 | 说明 |
|:------|:------|
| **使用Ingress对外暴露服务** | 避免直接使用NodePort |
| **配置Readiness Probe** | 确保只有就绪的Pod接收流量 |
| **合理配置NetworkPolicy** | 默认允许，按需限制 |
| **监控关键指标** | 及时发现网络问题 |
| **文档化网络架构** | 便于故障排查 |

> 本文对应的面试题：[容器内部服务互相调用正常、外部无法访问，如何解决？]({% post_url 2026-04-15-sre-interview-questions %})

---

## 附录：快速排查脚本

```bash
#!/bin/bash

echo "=== K8s网络故障排查 ==="

# 1. 检查Service
echo ""
echo "1. 检查Service:"
kubectl get service "$1" -o wide

# 2. 检查Endpoint
echo ""
echo "2. 检查Endpoint:"
kubectl get endpoints "$1"

# 3. 检查Pod状态
echo ""
echo "3. 检查Pod:"
kubectl get pod -l app="$1" -o wide

# 4. 检查Pod事件
echo ""
echo "4. 检查Pod事件:"
kubectl describe pod -l app="$1" | grep -A 10 "Events"

# 5. 检查Ingress
echo ""
echo "5. 检查Ingress:"
kubectl get ingress 2>/dev/null || echo "No Ingress found"

# 6. 检查NetworkPolicy
echo ""
echo "6. 检查NetworkPolicy:"
kubectl get networkpolicy 2>/dev/null || echo "No NetworkPolicy found"

echo ""
echo "=== 排查完成 ==="
```
