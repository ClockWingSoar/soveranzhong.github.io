---
layout: post
title: "K8s应用高可用架构详解与最佳实践"
subtitle: "深入理解Kubernetes保障应用高可用的核心机制"
date: 2026-06-22 10:00:00
author: "OpsOps"
header-img: "img/post-bg-ha.jpg"
catalog: true
tags:
  - Kubernetes
  - 高可用
  - Deployment
  - Service
  - Probe
---

## 一、引言

在生产环境中，应用高可用性是至关重要的指标。Kubernetes作为容器编排平台，提供了多层次的高可用保障机制，从Pod副本管理到控制平面冗余，从健康检查到自动故障转移，构建了一套完整的高可用体系。本文将深入剖析K8s保障应用高可用的核心机制，并结合生产环境实践给出最佳配置建议。

---

## 二、SCQA分析框架

### 情境（Situation）
- 企业级应用需要7x24小时不间断运行
- 单节点故障、网络抖动、应用崩溃等问题时有发生
- 业务连续性直接影响用户体验和企业收益

### 冲突（Complication）
- 单点故障导致服务中断
- Pod分布不均引发级联故障
- 健康检查配置不当导致误判
- 控制平面单点故障影响整个集群

### 问题（Question）
- K8s如何保证应用高可用？
- 副本管理机制是如何工作的？
- 健康检查的三种探针有什么区别？
- 服务发现和负载均衡如何实现故障转移？
- 生产环境中如何配置高可用？

### 答案（Answer）
- 通过Deployment/StatefulSet保证副本数量
- 使用Liveness/Readiness/Startup探针检测Pod状态
- Service自动发现Pod并实现负载均衡
- Pod反亲和性和拓扑分布约束确保高可用分布
- 多Master节点和etcd集群保证控制平面高可用

---

## 三、副本管理机制

### 3.1 Deployment（无状态应用）

**核心功能**：
- 管理Pod副本数量
- 支持滚动更新和回滚
- 自动重建失败的Pod

**配置示例**：
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3  # 确保3个副本运行
  selector:
    matchLabels:
      app: web
  strategy:
    rollingUpdate:
      maxSurge: 25%        # 滚动更新时最多额外创建25%的Pod
      maxUnavailable: 0    # 更新期间不允许任何Pod不可用
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: nginx:latest
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "200m"
            memory: "256Mi"
```

**更新策略对比**：

| 更新策略 | 特点 | 适用场景 |
|:------|:------|:------|
| **RollingUpdate** | 渐进式更新，无停机 | 生产环境 |
| **Recreate** | 先删除再创建，有停机时间 | 测试环境 |

### 3.2 StatefulSet（有状态应用）

**核心功能**：
- 稳定的网络标识
- 持久化存储
- 有序部署和缩放
- 有序滚动更新

**配置示例**：
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql-cluster
spec:
  serviceName: mysql-headless
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: root-password
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

### 3.3 ReplicaSet

**核心功能**：
- 维护指定数量的Pod副本
- 是Deployment的底层控制器
- 自动替换失败的Pod

**配置示例**：
```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: web-rs
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: nginx:latest
```

---

## 四、健康检查机制

### 4.1 Liveness Probe（存活探针）

**作用**：检测容器是否存活，失败则重启容器

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
      initialDelaySeconds: 15  # 启动后15秒开始探测
      periodSeconds: 5         # 每5秒探测一次
      timeoutSeconds: 2        # 超时时间2秒
      failureThreshold: 3      # 连续失败3次触发重启
      successThreshold: 1      # 成功1次即认为健康
```

**探针类型**：

| 类型 | 说明 | 适用场景 |
|:------|:------|:------|
| **httpGet** | HTTP请求检查 | Web应用 |
| **tcpSocket** | TCP连接检查 | 数据库、MQ |
| **exec** | 执行命令检查 | 自定义检查逻辑 |

### 4.2 Readiness Probe（就绪探针）

**作用**：检测容器是否就绪，未就绪则从Service端点移除

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
      successThreshold: 2      # 连续成功2次才认为就绪
```

### 4.3 Startup Probe（启动探针）

**作用**：处理慢启动应用，延迟Liveness检查

**配置示例**：
```yaml
spec:
  containers:
  - name: slow-app
    image: slow-app:latest
    startupProbe:
      httpGet:
        path: /health
        port: 8080
      failureThreshold: 30     # 最多探测30次
      periodSeconds: 10        # 每10秒探测一次
    livenessProbe:
      httpGet:
        path: /health
        port: 8080
      periodSeconds: 5
```

### 4.4 三种探针的配合使用

```
┌─────────────────────────────────────────────────────────────┐
│                    探针配合工作流程                          │
├─────────────────────────────────────────────────────────────┤
│                                                           │
│  Pod启动                                                   │
│     │                                                      │
│     ▼                                                      │
│  ┌────────────────┐                                        │
│  │ Startup Probe  │ → 成功后开始Liveness/Readiness检查     │
│  │  (慢启动保护)  │                                        │
│  └────────────────┘                                        │
│         │                                                  │
│         ▼                                                  │
│  ┌────────────────┐     ┌────────────────┐                 │
│  │ Liveness Probe │     │ Readiness Probe│                 │
│  │  (存活检测)    │     │  (就绪检测)    │                 │
│  └──────┬─────────┘     └──────┬─────────┘                 │
│         │                      │                            │
│         ▼                      ▼                            │
│   失败→重启容器          失败→从Service移除                  │
│   成功→继续运行          成功→接收流量                      │
│                                                           │
└─────────────────────────────────────────────────────────────┘
```

---

## 五、服务发现与负载均衡

### 5.1 Service类型

**ClusterIP（默认）**：
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  type: ClusterIP
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 8080
```

**NodePort**：
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-nodeport
spec:
  type: NodePort
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080  # 可选，不指定则自动分配
```

**LoadBalancer**：
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-lb
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 8080
  loadBalancerIP: 10.0.0.100  # 可选，预留IP
```

**Headless Service（无头服务）**：
```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-headless
spec:
  clusterIP: None
  selector:
    app: mysql
  ports:
  - port: 3306
```

### 5.2 Endpoint自动更新

**工作原理**：
```bash
# Service通过标签选择器匹配Pod
# 当Pod状态变化时，Endpoint自动更新

# 查看Endpoint
kubectl get endpoints web-service

# 手动触发Endpoint更新
kubectl apply -f web-service.yaml
```

### 5.3 Ingress

**配置示例**：
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
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

---

## 六、故障自愈机制

### 6.1 Pod自动重建

**场景一：容器崩溃**
```bash
# 查看Pod重启次数
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].restartCount}'

# 查看重启原因
kubectl describe pod <pod-name> | grep -A 5 "Last State"
```

**场景二：节点故障**
```bash
# 模拟节点故障
kubectl drain node-01 --ignore-daemonsets

# 查看Pod重新调度情况
kubectl get pod -o wide -w
```

### 6.2 Pod反亲和性

**配置示例**：
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

### 6.3 拓扑分布约束

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

---

## 七、控制平面高可用

### 7.1 多Master节点部署

**kubeadm部署**：
```bash
# 初始化第一个Master
kubeadm init \
  --control-plane-endpoint "lb.example.com:6443" \
  --upload-certs

# 加入其他Master节点
kubeadm join lb.example.com:6443 \
  --token xxx \
  --discovery-token-ca-cert-hash sha256:xxx \
  --control-plane \
  --certificate-key xxx
```

### 7.2 etcd高可用集群

**etcd集群配置**：
```bash
# 创建etcd集群
etcdctl member add master-02 --peer-urls=http://master-02:2380
etcdctl member add master-03 --peer-urls=http://master-03:2380

# 查看集群状态
etcdctl cluster-health
etcdctl member list
```

### 7.3 外部负载均衡器

**HAProxy配置示例**：
```
frontend kubernetes
  bind *:6443
  mode tcp
  option tcplog
  default_backend kubernetes-master

backend kubernetes-master
  mode tcp
  balance roundrobin
  server master-01 master-01:6443 check
  server master-02 master-02:6443 check
  server master-03 master-03:6443 check
```

---

## 八、生产环境最佳实践

### 8.1 副本配置

**推荐配置**：
- **生产环境**：至少3个副本
- **关键业务**：5-7个副本
- **跨可用区部署**：每个可用区至少1个副本

### 8.2 健康检查配置

**最佳实践**：
```yaml
spec:
  containers:
  - name: app
    image: myapp:latest
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 30  # 预留足够启动时间
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 10
      periodSeconds: 5
      successThreshold: 2
```

### 8.3 Pod分布策略

**配置示例**：
```yaml
spec:
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels:
            app: web
        topologyKey: kubernetes.io/hostname
  topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        app: web
```

### 8.4 滚动更新配置

**推荐配置**：
```yaml
spec:
  strategy:
    rollingUpdate:
      maxSurge: 1           # 最多额外创建1个Pod
      maxUnavailable: 0     # 更新期间不允许任何Pod不可用
    type: RollingUpdate
```

### 8.5 监控告警

**关键指标**：
```yaml
groups:
- name: ha.rules
  rules:
  - alert: DeploymentReplicasMismatch
    expr: kube_deployment_replicas_ready != kube_deployment_replicas_desired
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Deployment副本数不匹配"
      description: "Deployment {{ $labels.deployment }} 的就绪副本数与期望副本数不一致"

  - alert: PodCrashLooping
    expr: increase(kube_pod_container_status_restarts_total[10m]) > 5
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Pod频繁重启"
      description: "Pod {{ $labels.pod }} 在过去10分钟内重启超过5次"

  - alert: NodeUnavailable
    expr: kube_node_status_condition{condition="Ready", status="false"} == 1
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "节点不可用"
      description: "节点 {{ $labels.node }} 状态为NotReady"
```

---

## 九、常见问题与解决方案

### 问题一：Pod无法启动

**现象**：Pod一直处于Pending或ContainerCreating状态

**解决方案**：
```bash
# 查看Pod事件
kubectl describe pod <pod-name>

# 常见原因：
# 1. 镜像拉取失败 → 检查镜像地址和凭证
kubectl get events | grep -i "Failed to pull image"

# 2. 资源不足 → 检查节点资源
kubectl top nodes

# 3. Volume挂载失败 → 检查PVC状态
kubectl get pvc

# 4. 网络问题 → 检查CNI配置
kubectl get pods -n kube-system -l k8s-app=calico
```

### 问题二：服务不可访问

**现象**：Service无法访问后端Pod

**解决方案**：
```bash
# 检查Service配置
kubectl get service <service-name> -o yaml

# 检查Endpoint状态
kubectl get endpoints <service-name>

# 检查Pod标签是否匹配
kubectl get pod <pod-name> --show-labels

# 检查Pod是否就绪
kubectl get pod <pod-name> -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}'

# 检查网络策略
kubectl get networkpolicy
```

### 问题三：Pod频繁重启

**现象**：Pod重启次数不断增加

**解决方案**：
```bash
# 查看Pod日志
kubectl logs <pod-name> --previous

# 检查Liveness Probe配置
kubectl get pod <pod-name> -o yaml | grep -A 10 livenessProbe

# 检查资源限制
kubectl get pod <pod-name> -o yaml | grep -A 10 resources

# 检查容器退出码
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode}'
```

### 问题四：流量不均

**现象**：部分Pod流量过大，部分Pod流量很小

**解决方案**：
```bash
# 检查Pod分布
kubectl get pod -o wide

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

### 问题五：节点故障导致服务中断

**现象**：节点故障后，服务不可用

**解决方案**：
```bash
# 检查节点状态
kubectl get nodes

# 配置Pod反亲和性和拓扑分布约束
kubectl patch deployment <deployment-name> -p '{
  "spec": {
    "template": {
      "spec": {
        "topologySpreadConstraints": [
          {
            "maxSkew": 1,
            "topologyKey": "kubernetes.io/hostname",
            "whenUnsatisfiable": "DoNotSchedule",
            "labelSelector": {
              "matchLabels": {
                "app": "web"
              }
            }
          }
        ]
      }
    }
  }
}'
```

---

## 十、总结

### 核心要点

1. **副本管理**：Deployment/StatefulSet确保指定数量的Pod运行
2. **健康检查**：Liveness检测存活、Readiness检测就绪、Startup处理慢启动
3. **服务发现**：Service自动发现Pod并实现负载均衡
4. **故障自愈**：Pod失败自动重建，节点故障自动漂移
5. **控制平面高可用**：多Master节点+etcd集群

### 生产环境建议

| 建议 | 说明 |
|:------|:------|
| **合理设置副本数** | 至少3个副本，关键业务5-7个 |
| **配置完整的健康检查** | Liveness+Readiness+Startup探针 |
| **使用Pod反亲和性** | 避免Pod集中在同一节点 |
| **配置拓扑分布约束** | 确保跨节点、跨可用区分布 |
| **配置滚动更新策略** | 保证更新过程中服务可用性 |
| **监控告警** | 及时发现和处理异常 |

> 本文对应的面试题：[K8s怎么保证应用高可用？]({% post_url 2026-04-15-sre-interview-questions %})

---

## 附录：常用命令

```bash
# 查看Deployment状态
kubectl get deployment
kubectl describe deployment <deployment-name>

# 查看Pod状态和节点分布
kubectl get pod -o wide

# 查看Service和Endpoint
kubectl get service
kubectl get endpoints

# 查看节点状态
kubectl get nodes

# 查看Pod事件
kubectl describe pod <pod-name>
kubectl get events --sort-by='.metadata.creationTimestamp'

# 查看容器日志
kubectl logs <pod-name>
kubectl logs <pod-name> --previous

# 滚动更新Deployment
kubectl set image deployment/<deployment-name> <container-name>=<image>:<tag>

# 回滚Deployment
kubectl rollout undo deployment/<deployment-name>
```
