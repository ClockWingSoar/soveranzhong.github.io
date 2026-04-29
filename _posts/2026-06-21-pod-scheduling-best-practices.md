---
layout: post
title: "Pod调度机制详解与最佳实践"
subtitle: "深入理解kube-scheduler的两阶段调度流程"
date: 2026-06-21 10:00:00
author: "OpsOps"
header-img: "img/post-bg-pod-scheduling.jpg"
catalog: true
tags:
  - Kubernetes
  - Pod调度
  - Scheduler
  - 亲和性
  - 污点容忍
---

## 一、引言

Pod调度是Kubernetes集群资源管理的核心环节，直接影响集群的资源利用率、业务可用性和性能表现。kube-scheduler作为K8s默认调度器，通过精巧的两阶段调度算法，为每个Pod找到最合适的运行节点。本文将深入剖析Pod调度的完整流程，包括预选过滤、优选打分、节点绑定等关键环节，并介绍亲和性、污点容忍等高级调度特性。

---

## 二、SCQA分析框架

### 情境（Situation）
- Pod需要被合理分配到集群节点上运行
- 调度器需要考虑资源需求、策略约束、业务需求等多方面因素
- 大规模集群中调度效率至关重要

### 冲突（Complication）
- 节点资源有限，Pod需求多样
- 调度策略复杂，需要兼顾公平性和效率
- 特殊节点需要保护，避免被普通Pod占用
- Pod分布不均会影响可用性

### 问题（Question）
- Pod是如何被调度到节点的？
- 调度器的工作流程是怎样的？
- 如何控制Pod调度到特定节点？
- 污点和容忍的作用是什么？
- 生产环境中如何优化调度策略？

### 答案（Answer）
- kube-scheduler通过两阶段调度（预选+优选）完成Pod调度
- 预选阶段过滤不符合条件的节点
- 优选阶段为节点打分，选择得分最高的节点
- 通过nodeSelector、Affinity、Taints/Tolerations控制调度
- 生产环境需要配置亲和性、反亲和性和拓扑分布约束

---

## 三、Pod调度流程详解

### 3.1 调度器工作原理

kube-scheduler的核心职责是为未绑定节点的Pod分配合适的Node。调度流程分为两个阶段：

```
┌─────────────────────────────────────────────────────────────┐
│                    kube-scheduler工作流程                   │
├─────────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐│
│  │  监听未调度  │ →→→ │  预选过滤    │ →→→ │  优选打分    ││
│  │    Pod      │     │  (Filtering) │     │  (Scoring)   ││
│  └──────────────┘     └──────┬───────┘     └──────┬───────┘│
│                              │                    │        │
│                              ▼                    ▼        │
│                    ┌──────────────┐     ┌──────────────┐  │
│                    │  可行节点列表  │     │  选择最高分  │  │
│                    └──────────────┘     └──────┬───────┘  │
│                                                │          │
│                                                ▼          │
│                                      ┌──────────────┐    │
│                                      │   绑定节点   │    │
│                                      └──────────────┘    │
│                                                           │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 第一阶段：预选（Filtering）

**核心任务**：排除不满足条件的节点

**常见过滤规则**：

| 过滤规则 | 作用 | 示例 |
|:------|:------|:------|
| **PodFitsResources** | 检查节点资源是否满足Pod需求 | CPU、内存requests |
| **PodFitsHostPorts** | 检查主机端口是否被占用 | hostPort配置 |
| **PodFitsHost** | 检查节点名称是否匹配 | nodeName配置 |
| **NodeSelector** | 检查节点标签是否匹配 | disktype=ssd |
| **NodeAffinity** | 检查节点亲和性规则 | zone=zone-a |
| **TaintToleration** | 检查污点容忍 | dedicated=special |
| **VolumeBinding** | 检查存储卷绑定 | PVC匹配 |

**过滤流程示例**：
```bash
# 调度器遍历所有节点
# 节点1：资源不足 → 排除
# 节点2：有污点，Pod不容忍 → 排除
# 节点3：端口被占用 → 排除
# 节点4：满足所有条件 → 进入可行节点列表
```

### 3.3 第二阶段：优选（Scoring）

**核心任务**：为可行节点打分（0-100分）

**常见打分规则**：

| 打分规则 | 作用 | 权重 |
|:------|:------|:------|
| **LeastRequestedPriority** | 资源使用率低的节点得分高 | 1 |
| **BalancedResourceAllocation** | 资源使用均衡的节点得分高 | 1 |
| **NodeAffinityPriority** | 满足软亲和性的节点加分 | 可配置 |
| **ImageLocalityPriority** | 已有镜像的节点得分高 | 1 |
| **SelectorSpreadPriority** | Pod分散到不同节点 | 1 |
| **TopologySpreadPriority** | 拓扑分布均衡 | 可配置 |

**打分计算公式**：
```bash
# LeastRequestedPriority
score = (cpu((capacity - requested) / capacity) + memory((capacity - requested) / capacity)) / 2 * 100

# BalancedResourceAllocation
# 计算CPU和内存使用率的差值，差值越小得分越高
```

### 3.4 节点绑定

**调度结果**：选择得分最高的节点

**绑定流程**：
```bash
# 1. 创建Binding对象
kubectl create binding my-pod --namespace=default --binding-target=node-01

# 2. API Server更新Pod状态
# spec.nodeName = node-01

# 3. kubelet监听并启动容器
# kubelet发现绑定到本节点的Pod，调用容器运行时启动
```

---

## 四、调度机制详解

### 4.1 nodeName（直接指定节点）

**特点**：跳过调度器，直接绑定到指定节点

**适用场景**：
- 测试环境快速定位节点
- 特殊硬件绑定（GPU、FPGA）
- 临时应急操作

**配置示例**：
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-pod
spec:
  nodeName: gpu-node-01  # 强制调度到GPU节点
  containers:
  - name: tensorflow
    image: tensorflow/tensorflow:latest-gpu
    resources:
      limits:
        nvidia.com/gpu: 1
```

### 4.2 nodeSelector（节点标签匹配）

**特点**：通过节点标签选择符合条件的节点

**配置步骤**：
```bash
# 1. 为节点打标签
kubectl label nodes node-01 region=us-west
kubectl label nodes node-01 disktype=ssd

# 2. 配置Pod的nodeSelector
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ssd-pod
spec:
  nodeSelector:
    region: us-west
    disktype: ssd
  containers:
  - name: nginx
    image: nginx
EOF
```

### 4.3 NodeAffinity（节点亲和性）

**特点**：比nodeSelector更灵活，支持硬亲和性和软亲和性

**硬亲和性（必须满足）**：
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: required-affinity
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/os
            operator: In
            values: ["linux"]
          - key: zone
            operator: NotIn
            values: ["zone-c"]
  containers:
  - name: app
    image: myapp:latest
```

**软亲和性（优先满足）**：
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: preferred-affinity
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 80
        preference:
          matchExpressions:
          - key: node-type
            operator: In
            values: ["high-performance"]
      - weight: 20
        preference:
          matchExpressions:
          - key: zone
            operator: In
            values: ["zone-a"]
  containers:
  - name: app
    image: myapp:latest
```

**操作符说明**：
| 操作符 | 说明 |
|:------|:------|
| **In** | 值在列表中 |
| **NotIn** | 值不在列表中 |
| **Exists** | 键存在 |
| **DoesNotExist** | 键不存在 |
| **Gt** | 大于（数值） |
| **Lt** | 小于（数值） |

### 4.4 PodAffinity/PodAntiAffinity（Pod间亲和性）

**PodAffinity（Pod亲和性）**：
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cache-affinity
spec:
  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels:
            app: redis-cache
        topologyKey: kubernetes.io/hostname
  containers:
  - name: app
    image: myapp:latest
```

**PodAntiAffinity（Pod反亲和性）**：
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-anti-affinity
spec:
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels:
            app: web
        topologyKey: kubernetes.io/hostname
  containers:
  - name: web
    image: nginx:latest
```

### 4.5 Taints & Tolerations（污点与容忍）

**Taint（污点）**：
```bash
# 添加污点
kubectl taint nodes node-01 key=value:effect

# effect类型：
# - NoSchedule: 不容忍的Pod不能调度
# - PreferNoSchedule: 尽量不调度
# - NoExecute: 已运行的Pod会被驱逐

# 示例：标记节点为专用节点
kubectl taint nodes gpu-node-01 dedicated=gpu:NoSchedule

# 示例：标记节点内存压力
kubectl taint nodes node-01 node.kubernetes.io/memory-pressure:NoSchedule

# 移除污点
kubectl taint nodes node-01 dedicated-
```

**Toleration（容忍）**：
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-workload
spec:
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "gpu"
    effect: "NoSchedule"
  - key: "node.kubernetes.io/memory-pressure"
    operator: "Exists"
  containers:
  - name: gpu-app
    image: gpu-app:latest
```

---

## 五、调度策略配置

### 5.1 Scheduler配置文件

```yaml
apiVersion: kubescheduler.config.k8s.io/v1beta3
kind: KubeSchedulerConfiguration
profiles:
- schedulerName: default-scheduler
  plugins:
    filter:
      enabled:
      - name: PodFitsResources
      - name: PodFitsHostPorts
      - name: NodeAffinity
      - name: TaintToleration
      disabled:
      - name: NodeName
    score:
      enabled:
      - name: LeastRequestedPriority
        weight: 1
      - name: BalancedResourceAllocation
        weight: 1
      - name: NodeAffinityPriority
        weight: 2
      - name: ImageLocalityPriority
        weight: 1
      - name: SelectorSpreadPriority
        weight: 1
```

### 5.2 多调度器配置

```yaml
# 部署自定义调度器
apiVersion: apps/v1
kind: Deployment
metadata:
  name: custom-scheduler
spec:
  replicas: 1
  selector:
    matchLabels:
      app: custom-scheduler
  template:
    metadata:
      labels:
        app: custom-scheduler
    spec:
      containers:
      - name: scheduler
        image: k8s.gcr.io/kube-scheduler:v1.28.0
        command:
        - kube-scheduler
        - --config=/etc/kubernetes/scheduler-config.yaml
        - --scheduler-name=custom-scheduler
        volumeMounts:
        - name: config
          mountPath: /etc/kubernetes
      volumes:
      - name: config
        configMap:
          name: scheduler-config
```

**使用自定义调度器**：
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: custom-scheduler-pod
spec:
  schedulerName: custom-scheduler  # 指定调度器
  containers:
  - name: app
    image: myapp:latest
```

---

## 六、生产环境最佳实践

### 6.1 使用节点亲和性控制调度

**按区域调度**：
```yaml
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: topology.kubernetes.io/zone
            operator: In
            values: ["us-west-1a", "us-west-1b"]
```

### 6.2 配置Pod反亲和性提高可用性

**多副本分散部署**：
```yaml
spec:
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels:
            app: web
        topologyKey: kubernetes.io/hostname
```

### 6.3 使用污点保护特殊节点

**GPU节点保护**：
```bash
# 添加污点
kubectl taint nodes gpu-node-01 nvidia.com/gpu:NoSchedule

# Pod配置容忍
spec:
  tolerations:
  - key: "nvidia.com/gpu"
    operator: "Exists"
  containers:
  - name: gpu-app
    image: gpu-app:latest
    resources:
      limits:
        nvidia.com/gpu: 1
```

### 6.4 配置Pod拓扑分布约束

**跨节点分布**：
```yaml
spec:
  topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        app: web
```

**跨可用区分布**：
```yaml
spec:
  topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        app: web
```

### 6.5 监控调度性能

**关键指标**：
```yaml
# Prometheus监控规则
groups:
- name: scheduler.rules
  rules:
  - alert: SchedulerHighPendingPods
    expr: sum by (namespace) (kube_pod_status_phase{phase="Pending"}) > 10
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Pending Pod数量过多"
      description: "命名空间 {{ $labels.namespace }} 有超过10个Pending状态的Pod"

  - alert: SchedulerFailedScheduling
    expr: increase(kube_scheduler_scheduling_attempts_total{result="failed"}[5m]) > 5
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "调度失败次数过多"
      description: "最近5分钟调度失败次数超过5次"
```

---

## 七、常见问题与解决方案

### 问题一：Pod一直Pending

**现象**：Pod长时间处于Pending状态

**解决方案**：
```bash
# 查看Pod事件
kubectl describe pod <pod-name>

# 常见原因：
# 1. 资源不足 → 检查节点资源
kubectl top nodes

# 2. 污点限制 → 检查节点污点
kubectl describe node <node-name> | grep Taints

# 3. 亲和性配置错误 → 检查nodeSelector/nodeAffinity
kubectl get pod <pod-name> -o yaml | grep -A 20 affinity
```

### 问题二：Pod调度到错误节点

**现象**：Pod没有调度到预期的节点

**解决方案**：
```bash
# 检查节点标签
kubectl get nodes --show-labels

# 检查Pod的nodeSelector配置
kubectl get pod <pod-name> -o yaml | grep nodeSelector

# 检查亲和性配置
kubectl get pod <pod-name> -o yaml | grep -A 20 affinity
```

### 问题三：节点资源浪费

**现象**：部分节点资源使用率低，部分节点过载

**解决方案**：
```bash
# 检查节点资源使用
kubectl top nodes

# 调整调度策略权重
# 修改Scheduler配置文件，增加BalancedResourceAllocation权重
```

### 问题四：Pod被驱逐

**现象**：Pod运行一段时间后被驱逐

**解决方案**：
```bash
# 查看节点污点
kubectl describe node <node-name> | grep Taints

# 查看Pod容忍配置
kubectl get pod <pod-name> -o yaml | grep -A 10 tolerations

# 添加相应的容忍
kubectl patch pod <pod-name> -p '{"spec":{"tolerations":[{"key":"node.kubernetes.io/memory-pressure","operator":"Exists"}]}}'
```

### 问题五：Pod分布不均

**现象**：同一Deployment的Pod集中在少数节点

**解决方案**：
```bash
# 配置Pod反亲和性
kubectl patch deployment <deployment-name> -p '{
  "spec": {
    "template": {
      "spec": {
        "affinity": {
          "podAntiAffinity": {
            "requiredDuringSchedulingIgnoredDuringExecution": [
              {
                "labelSelector": {
                  "matchLabels": {
                    "app": "web"
                  }
                },
                "topologyKey": "kubernetes.io/hostname"
              }
            ]
          }
        }
      }
    }
  }
}'
```

---

## 八、总结

### 核心要点

1. **调度流程分为两阶段**：预选过滤不符合条件的节点，优选为节点打分
2. **调度机制丰富**：nodeName、nodeSelector、Affinity、Taints/Tolerations
3. **亲和性分为硬亲和性和软亲和性**：硬亲和性必须满足，软亲和性优先满足
4. **污点用于保护节点**：不容忍污点的Pod无法调度到该节点
5. **拓扑分布约束确保Pod均匀分布**：提高可用性

### 生产环境建议

| 建议 | 说明 |
|:------|:------|
| **使用节点亲和性** | 按区域、硬件类型等维度控制调度 |
| **配置Pod反亲和性** | 避免同一应用的Pod集中在同一节点 |
| **使用污点保护特殊节点** | GPU、SSD等专用节点只允许特定Pod调度 |
| **配置拓扑分布约束** | 确保Pod跨节点、跨可用区分布 |
| **监控调度性能** | 及时发现调度异常 |

> 本文对应的面试题：[Pod怎么调度到节点？]({% post_url 2026-04-15-sre-interview-questions %})

---

## 附录：常用命令

```bash
# 查看Pod调度的节点
kubectl get pod <pod-name> -o jsonpath='{.spec.nodeName}'

# 查看节点标签
kubectl get nodes --show-labels

# 为节点打标签
kubectl label nodes <node-name> <key>=<value>

# 查看节点污点
kubectl describe node <node-name> | grep Taints

# 添加污点
kubectl taint nodes <node-name> <key>=<value>:<effect>

# 查看调度事件
kubectl get events --sort-by='.metadata.creationTimestamp'

# 查看Scheduler日志
kubectl logs -n kube-system <scheduler-pod-name>
```
