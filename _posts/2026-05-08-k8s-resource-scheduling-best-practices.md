# K8S扩容后资源分配与调度策略调整：生产环境优化指南

## 情境与背景

节点扩容后，合理的资源分配和调度策略调整是确保集群高效运行的关键。作为高级DevOps/SRE工程师，需要掌握扩容后的优化策略。本文从DevOps/SRE视角，深入讲解K8S扩容后的资源分配和调度策略调整。

## 一、资源分配优化

### 1.1 ResourceQuota配置

**配置示例**：
```yaml
# ResourceQuota配置
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-a-quota
  namespace: team-a
spec:
  hard:
    requests.cpu: "10"
    requests.memory: "20Gi"
    limits.cpu: "20"
    limits.memory: "40Gi"
    pods: "100"
    services: "10"
```

**调整策略**：
- 根据新节点资源总量调整Quota
- 按团队业务需求分配资源
- 预留20%资源作为缓冲

### 1.2 LimitRange配置

**配置示例**：
```yaml
# LimitRange配置
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: default
spec:
  limits:
    - default:
        cpu: "500m"
        memory: "512Mi"
      defaultRequest:
        cpu: "250m"
        memory: "256Mi"
      type: Container
```

**调整策略**：
- 限制单个Pod的资源上限
- 设置默认资源请求
- 防止资源滥用

### 1.3 资源分配原则

| 原则 | 说明 |
|:----:|------|
| **公平性** | 各团队公平分配资源 |
| **弹性** | 根据业务需求动态调整 |
| **预留缓冲** | 预留20%资源应对突发 |
| **优先级** | 核心服务优先分配 |

## 二、调度策略调整

### 2.1 节点亲和性配置

**配置示例**：
```yaml
# 节点亲和性配置
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: topology.kubernetes.io/zone
                operator: In
                values:
                  - zone-a
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          preference:
            matchExpressions:
              - key: node-role.kubernetes.io/worker
                operator: Exists
```

**调整策略**：
- 按可用区分布Pod
- 按节点角色调度
- 避免单点故障

### 2.2 Pod优先级配置

**配置示例**：
```yaml
# PriorityClass配置
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: critical
value: 1000000
globalDefault: false
description: "Critical priority for core services."
```

**Pod使用优先级**：
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: critical-app
spec:
  priorityClassName: critical
  containers:
    - name: app
      image: my-app:latest
```

**优先级分类**：

| 优先级 | 名称 | 适用场景 |
|:------:|------|----------|
| 1000000 | critical | 核心服务 |
| 500000 | high | 重要服务 |
| 100000 | medium | 普通服务 |
| 10000 | low | 测试服务 |

### 2.3 污点与容忍配置

**节点污点配置**：
```yaml
# 节点污点
kubectl taint nodes node-1 dedicated=production:NoSchedule
```

**Pod容忍配置**：
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: production-app
spec:
  tolerations:
    - key: "dedicated"
      operator: "Equal"
      value: "production"
      effect: "NoSchedule"
```

## 三、调度器配置优化

### 3.1 调度器策略配置

```yaml
# 调度器配置
apiVersion: kubescheduler.config.k8s.io/v1beta3
kind: KubeSchedulerConfiguration
profiles:
  - schedulerName: default-scheduler
    pluginConfig:
      - name: NodeResourcesFit
        args:
          scoringStrategy:
            type: LeastAllocated
```

### 3.2 调度器插件配置

**启用的插件**：

| 插件 | 功能 | 启用状态 |
|:----:|------|:--------:|
| NodeResourcesFit | 节点资源匹配 | ✅ |
| NodeAffinity | 节点亲和性 | ✅ |
| PodTopologySpread | Pod拓扑分布 | ✅ |
| PrioritySort | 优先级排序 | ✅ |
| DefaultPreemption | 默认抢占 | ✅ |

### 3.3 调度策略选择

**策略对比**：

| 策略 | 说明 | 适用场景 |
|:----:|------|----------|
| **LeastAllocated** | 优先调度到资源最少的节点 | 均衡负载 |
| **MostAllocated** | 优先调度到资源最多的节点 | 资源密集型 |
| **BalancedAllocation** | 平衡资源使用 | 通用场景 |

## 四、负载均衡优化

### 4.1 Pod分布策略

```yaml
# Pod拓扑分布约束
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  topologySpreadConstraints:
    - maxSkew: 1
      topologyKey: topology.kubernetes.io/zone
      whenUnsatisfiable: DoNotSchedule
      labelSelector:
        matchLabels:
          app: my-app
```

**分布目标**：
- 跨可用区均匀分布
- 跨节点均匀分布
- 避免单点故障

### 4.2 反亲和性配置

```yaml
# Pod反亲和性
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchExpressions:
              - key: app
                operator: In
                values:
                  - my-app
          topologyKey: kubernetes.io/hostname
```

**作用**：
- 避免同类型Pod集中在同一节点
- 提高可用性
- 均衡负载

## 五、监控与调整

### 5.1 资源使用监控

**监控指标**：

| 指标 | 说明 | 目标值 |
|:----:|------|--------|
| CPU使用率 | 节点CPU使用比例 | <70% |
| 内存使用率 | 节点内存使用比例 | <75% |
| Pod分布 | Pod在节点上的分布 | 均匀 |
| Pending Pods | 等待调度的Pod数 | 0 |

### 5.2 自动调整机制

```yaml
# 自动调整配置
auto_scaling:
  enabled: true
  
  resource_thresholds:
    cpu: 80
    memory: 85
  
  actions:
    - type: "scale_up"
      condition: "cpu > 80% for 5m"
    - type: "scale_down"
      condition: "cpu < 30% for 10m"
```

## 六、实战案例分析

### 6.1 案例1：扩容后的资源重新分配

**场景描述**：
- 原有3个节点，扩容到10个节点
- 需要重新分配资源配额

**调整步骤**：
1. 计算新的资源总量
2. 按比例调整各团队Quota
3. 更新LimitRange配置
4. 验证资源分配

**配置示例**：
```yaml
# 调整后的ResourceQuota
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-a-quota
spec:
  hard:
    requests.cpu: "30"    # 从10调整到30
    requests.memory: "60Gi" # 从20Gi调整到60Gi
```

### 6.2 案例2：Pod重新分布

**场景描述**：
- 新节点加入后Pod分布不均
- 需要优化Pod分布

**调整步骤**：
1. 配置Pod拓扑分布约束
2. 设置反亲和性规则
3. 触发Pod重新调度
4. 验证分布效果

**配置示例**：
```yaml
# Pod拓扑分布配置
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: DoNotSchedule
```

## 七、面试1分钟精简版（直接背）

**完整版**：

扩容后我们会做以下几方面调整。首先是资源分配优化，调整Namespace的ResourceQuota，确保各团队公平使用资源，同时配置LimitRange防止单个Pod占用过多资源。其次是调度策略调整，通过节点亲和性和污点容忍配置，让Pod合理分布到新节点，避免热点。还会根据业务重要性设置Pod优先级类，保障核心服务的资源优先。最后优化调度器配置，调整调度算法参数，提高调度效率和负载均衡。这些调整确保集群在扩容后仍能高效稳定运行。

**30秒超短版**：

扩容后调整资源配额和LimitRange确保公平分配，配置节点亲和性和Pod优先级优化调度，调整调度器策略实现负载均衡。

## 八、总结

### 8.1 核心要点

1. **资源分配**：调整ResourceQuota和LimitRange
2. **调度策略**：配置节点亲和性、Pod优先级、污点容忍
3. **负载均衡**：使用拓扑分布约束和反亲和性
4. **持续优化**：监控资源使用，动态调整

### 8.2 调整原则

| 原则 | 说明 |
|:----:|------|
| **公平性** | 各团队公平分配资源 |
| **高效性** | 资源利用率最大化 |
| **可用性** | 避免单点故障 |
| **可观测性** | 持续监控调整效果 |

### 8.3 记忆口诀

```
资源配额要调整，节点亲和要配置，
Pod优先级要设置，调度策略要优化，
负载均衡要实现，监控调整要持续。
```

> **参考链接**：[SRE运维面试题全解析：从理论到实践（第二部分）]({% post_url 2026-04-15-sre-interview-questions-part2 %})