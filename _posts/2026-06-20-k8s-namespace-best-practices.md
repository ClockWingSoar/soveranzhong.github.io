---
layout: post
title: "K8s命名空间详解与多租户最佳实践"
subtitle: "深入理解Namespace的隔离机制、权限控制与资源管理"
date: 2026-06-20 10:00:00
author: "OpsOps"
header-img: "img/post-bg-namespace.jpg"
catalog: true
tags:
  - Kubernetes
  - Namespace
  - 多租户
  - RBAC
  - 资源管理
---

## 一、引言

在Kubernetes集群中，随着团队规模的扩大和应用数量的增长，如何有效地管理资源、隔离环境、控制权限成为关键挑战。Namespace（命名空间）作为K8s多租户管理的核心机制，提供了一种将单个物理集群划分为多个虚拟集群的能力。本文将深入剖析Namespace的设计原理、核心作用、隔离边界以及生产环境中的最佳实践。

---

## 二、SCQA分析框架

### 情境（Situation）
- 多个团队共享同一K8s集群，需要隔离各自的资源
- 不同环境（开发、测试、生产）需要独立运行空间
- 需要细粒度的权限控制和资源配额管理

### 冲突（Complication）
- 资源命名冲突问题
- 权限过宽导致安全风险
- 资源滥用影响集群稳定性
- 跨团队/环境的干扰问题

### 问题（Question）
- Namespace的核心作用是什么？
- 如何使用Namespace实现多租户隔离？
- 系统默认Namespace有哪些？各有什么用途？
- Namespace的隔离边界是什么？
- 如何配置资源配额和权限控制？

### 答案（Answer）
- Namespace提供名称隔离、权限控制、资源配额和环境隔离
- 通过Role/RoleBinding实现细粒度权限控制
- 通过ResourceQuota/LimitRange限制资源使用
- 默认四个系统Namespace：default、kube-system、kube-public、kube-node-lease
- Namespace是逻辑隔离，非物理隔离

---

## 三、Namespace核心作用详解

### 3.1 名称隔离

**原理**：Namespace本质上是etcd键空间中的路径前缀

```bash
# etcd存储路径结构
/registry/{resource_type}/{namespace}/{resource_name}

# 示例
/registry/pods/default/nginx-pod
/registry/pods/production/nginx-pod  # 可存在同名Pod
```

**实际应用**：
```bash
# 在不同Namespace创建同名Deployment
kubectl create deployment nginx --image=nginx -n dev
kubectl create deployment nginx --image=nginx -n prod

# 查看各自Namespace的资源
kubectl get deployments -n dev
kubectl get deployments -n prod
```

### 3.2 权限控制（RBAC）

**Role vs ClusterRole**：

| 角色类型 | 作用范围 | 适用场景 |
|:------|:------|:------|
| **Role** | 单个Namespace | 限定团队/项目权限 |
| **ClusterRole** | 整个集群 | 集群级管理权限 |

**配置示例**：
```yaml
# 创建Role（仅在dev Namespace生效）
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-developer
  namespace: dev
rules:
- apiGroups: ["", "apps"]
  resources: ["pods", "deployments", "services"]
  verbs: ["get", "list", "watch", "create", "update", "delete"]

# 创建RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev-team-binding
  namespace: dev
subjects:
- kind: Group
  name: dev-team
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: app-developer
  apiGroup: rbac.authorization.k8s.io
```

### 3.3 资源配额管理

**ResourceQuota（命名空间级）**：
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: production-quota
  namespace: prod
spec:
  hard:
    # 计算资源
    requests.cpu: "10"
    requests.memory: "20Gi"
    limits.cpu: "20"
    limits.memory: "40Gi"
    # 对象数量
    pods: "50"
    services: "20"
    configmaps: "100"
    secrets: "50"
```

**LimitRange（容器级）**：
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: container-defaults
  namespace: prod
spec:
  limits:
  - type: Container
    default:
      cpu: "1"
      memory: "1Gi"
    defaultRequest:
      cpu: "200m"
      memory: "256Mi"
    max:
      cpu: "2"
      memory: "2Gi"
    min:
      cpu: "100m"
      memory: "128Mi"
```

### 3.4 环境隔离

**按环境划分Namespace**：
```bash
# 创建环境Namespace
kubectl create namespace dev
kubectl create namespace test
kubectl create namespace prod

# 为Namespace添加标签
kubectl label namespace dev env=dev
kubectl label namespace test env=test
kubectl label namespace prod env=prod
```

---

## 四、系统默认Namespace详解

### 4.1 default

**作用**：未指定Namespace时的默认归属

**特点**：
- 集群创建时自动生成
- 不建议生产环境使用
- 应配置严格的资源配额强制用户显式指定Namespace

### 4.2 kube-system

**作用**：存放Kubernetes系统组件

**特点**：
- 包含控制平面组件（kube-apiserver、etcd、kube-scheduler等）
- 包含集群插件（CoreDNS、CNI插件等）
- 禁止随意修改或删除其中资源

**查看kube-system组件**：
```bash
kubectl get pods -n kube-system
```

### 4.3 kube-public

**作用**：存储集群级公开信息

**特点**：
- 所有用户（含未认证用户）均可访问
- 通常存储集群配置映射等公共信息
- 可用于存放公共的ConfigMap

### 4.4 kube-node-lease

**作用**：节点租约机制

**特点**：
- 用于kube-controller-manager检测节点健康状态
- 自动管理，用户无需干预
- 每个节点对应一个Lease对象

---

## 五、Namespace隔离边界

### 5.1 Namespace提供的隔离

| 隔离类型 | 说明 |
|:------|:------|
| **名称作用域隔离** | 同名资源可在不同Namespace共存 |
| **RBAC权限隔离** | Role限定在单个Namespace内 |
| **资源配额隔离** | ResourceQuota/LimitRange限制资源使用 |
| **网络策略隔离** | NetworkPolicy按Namespace筛选 |
| **Service DNS隔离** | {svc}.{ns}.svc.cluster.local |

### 5.2 Namespace不提供的隔离

| 隔离类型 | 说明 |
|:------|:------|
| **节点级隔离** | 不同Namespace的Pod可调度到同一节点 |
| **内核级隔离** | 共享宿主机内核，非虚拟化隔离 |
| **存储隔离** | PV是集群级资源，跨Namespace共享 |
| **集群级资源隔离** | Node、PV、ClusterRole等不属于任何Namespace |

### 5.3 Namespace级资源 vs 集群级资源

```bash
# 查看Namespace级资源
kubectl api-resources --namespaced=true

# 查看集群级资源
kubectl api-resources --namespaced=false
```

**资源分类表**：

| 类型 | 典型资源 |
|:------|:------|
| **Namespace级** | Pod、Deployment、Service、ConfigMap、Secret、PVC、Role、NetworkPolicy |
| **集群级** | Node、PersistentVolume、Namespace、ClusterRole、StorageClass、IngressClass |

---

## 六、跨Namespace通信

### 6.1 Service访问方式

**同一Namespace访问**：
```bash
kubectl exec -it my-pod -- curl http://my-service:8080
```

**跨Namespace访问**：
```bash
# 完整域名
kubectl exec -it my-pod -- curl http://my-service.prod.svc.cluster.local:8080

# 短域名（CoreDNS配置）
kubectl exec -it my-pod -- curl http://my-service.prod:8080
```

### 6.2 NetworkPolicy跨Namespace控制

**拒绝所有入站流量**：
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: prod
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

**允许特定Namespace访问**：
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-test
  namespace: prod
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          env: test
```

---

## 七、Namespace常用操作

### 7.1 基础操作

```bash
# 查看所有Namespace
kubectl get namespaces
kubectl get ns

# 查看Namespace详情
kubectl describe ns <namespace-name>

# 创建Namespace
kubectl create namespace <namespace-name>

# 通过YAML创建
kubectl apply -f namespace.yaml

# 删除Namespace（级联删除所有资源）
kubectl delete namespace <namespace-name>

# 设置默认Namespace
kubectl config set-context --current --namespace=<namespace-name>

# 查看所有Namespace的资源
kubectl get pods --all-namespaces
kubectl get pods -A
```

### 7.2 资源管理

```bash
# 在指定Namespace创建资源
kubectl run nginx --image=nginx -n dev

# 查看指定Namespace的资源
kubectl get deployments -n prod

# 跨Namespace复制资源
kubectl get deployment my-app -n dev -o yaml | sed 's/namespace: dev/namespace: test/' | kubectl apply -f -
```

---

## 八、生产环境最佳实践

### 8.1 Namespace规划策略

**策略一：按环境划分**
```yaml
# dev环境
apiVersion: v1
kind: Namespace
metadata:
  name: dev
  labels:
    env: dev
    tier: frontend

# test环境
apiVersion: v1
kind: Namespace
metadata:
  name: test
  labels:
    env: test
    tier: backend

# prod环境
apiVersion: v1
kind: Namespace
metadata:
  name: prod
  labels:
    env: prod
    tier: database
```

**策略二：按团队划分**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: team-a
  labels:
    team: team-a

apiVersion: v1
kind: Namespace
metadata:
  name: team-b
  labels:
    team: team-b
```

**策略三：按应用划分**
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: app-ecommerce
  labels:
    app: ecommerce

apiVersion: v1
kind: Namespace
metadata:
  name: app-payment
  labels:
    app: payment
```

### 8.2 资源配额配置

**为每个Namespace配置ResourceQuota**：
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dev-quota
  namespace: dev
spec:
  hard:
    requests.cpu: "4"
    requests.memory: "8Gi"
    limits.cpu: "8"
    limits.memory: "16Gi"
    pods: "20"
```

**配置LimitRange**：
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: dev-limits
  namespace: dev
spec:
  limits:
  - type: Container
    default:
      cpu: "500m"
      memory: "512Mi"
    defaultRequest:
      cpu: "200m"
      memory: "256Mi"
```

### 8.3 权限控制最佳实践

**最小权限原则**：
```yaml
# 只读权限
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: readonly
  namespace: prod
rules:
- apiGroups: ["", "apps"]
  resources: ["pods", "deployments", "services"]
  verbs: ["get", "list", "watch"]

# 编辑权限（不含删除）
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: editor
  namespace: dev
rules:
- apiGroups: ["", "apps"]
  resources: ["pods", "deployments", "services"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
```

### 8.4 网络策略配置

**默认拒绝策略**：
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: prod
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

**允许必要的出站流量**：
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress
  namespace: prod
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 10.0.0.0/8
        - 172.16.0.0/12
        - 192.168.0.0/16
```

### 8.5 监控与告警

**关键指标监控**：
```yaml
# Prometheus监控规则
groups:
- name: namespace.rules
  rules:
  - alert: NamespaceResourceUsageHigh
    expr: sum by (namespace) (kube_resourcequota_used{resource="memory"}) / sum by (namespace) (kube_resourcequota_hard{resource="memory"}) > 0.8
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Namespace内存使用率过高"
      description: "Namespace {{ $labels.namespace }} 内存使用率超过80%"

  - alert: NamespacePodCountHigh
    expr: sum by (namespace) (kube_pod_status_running) > 100
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Namespace Pod数量过多"
      description: "Namespace {{ $labels.namespace }} Pod数量超过100个"
```

---

## 九、常见问题与解决方案

### 问题一：资源命名冲突

**现象**：创建资源时提示名称已存在

**解决方案**：
```bash
# 检查资源是否存在于其他Namespace
kubectl get deployments --all-namespaces | grep nginx

# 使用不同的Namespace
kubectl create deployment nginx --image=nginx -n my-namespace
```

### 问题二：权限不足

**现象**：执行kubectl命令时提示权限不足

**解决方案**：
```bash
# 检查当前用户权限
kubectl auth can-i create deployments --namespace=prod

# 为用户授予相应权限
kubectl create rolebinding user-deployer --role=app-developer --user=my-user --namespace=prod
```

### 问题三：资源配额不足

**现象**：创建Pod时提示资源配额不足

**解决方案**：
```bash
# 查看当前配额使用情况
kubectl describe resourcequota -n prod

# 增加资源配额
kubectl patch resourcequota prod-quota -p '{"spec":{"hard":{"requests.cpu":"20","requests.memory":"40Gi"}}}'
```

### 问题四：跨Namespace通信失败

**现象**：Pod无法访问其他Namespace的Service

**解决方案**：
```bash
# 检查Service是否存在
kubectl get services -n target-namespace

# 检查NetworkPolicy配置
kubectl get networkpolicy -n target-namespace

# 使用完整域名访问
curl http://my-service.target-namespace.svc.cluster.local:8080
```

### 问题五：删除Namespace卡住

**现象**：Namespace删除后长时间处于Terminating状态

**解决方案**：
```bash
# 查看Namespace状态
kubectl get ns <namespace-name>

# 检查Finalizer
kubectl get ns <namespace-name> -o json | grep -A 10 finalizers

# 强制删除（谨慎使用）
kubectl delete ns <namespace-name> --grace-period=0 --force
```

---

## 十、总结

### 核心要点

1. **Namespace提供四种核心隔离**：名称隔离、权限控制、资源配额、环境隔离
2. **系统默认四个Namespace**：default、kube-system、kube-public、kube-node-lease
3. **Namespace是逻辑隔离**：不提供节点级、内核级和存储隔离
4. **配合RBAC实现细粒度权限控制**：Role用于Namespace级，ClusterRole用于集群级
5. **通过ResourceQuota和LimitRange限制资源使用**：防止资源滥用

### 生产环境建议

| 建议 | 说明 |
|:------|:------|
| **按环境/团队划分Namespace** | 清晰的资源组织结构 |
| **为每个Namespace配置资源配额** | 防止资源滥用 |
| **使用NetworkPolicy控制网络访问** | 提高安全性 |
| **遵循最小权限原则** | 降低安全风险 |
| **监控Namespace资源使用** | 及时发现异常 |

> 本文对应的面试题：[K8s命名空间（Namespace）是什么作用？]({% post_url 2026-04-15-sre-interview-questions %})

---

## 附录：常用命令

```bash
# 查看Namespace列表
kubectl get ns

# 查看Namespace详情
kubectl describe ns <namespace-name>

# 创建Namespace
kubectl create ns <namespace-name>

# 删除Namespace
kubectl delete ns <namespace-name>

# 设置默认Namespace
kubectl config set-context --current --namespace=<namespace-name>

# 查看所有Namespace的Pod
kubectl get pods -A

# 查看ResourceQuota
kubectl get resourcequota -n <namespace-name>

# 查看LimitRange
kubectl get limitrange -n <namespace-name>

# 查看NetworkPolicy
kubectl get networkpolicy -n <namespace-name>
```
