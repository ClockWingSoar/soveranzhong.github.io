---
layout: post
title: "Kubernetes核心组件架构与最佳实践"
subtitle: "深入理解K8s控制平面与节点组件"
date: 2026-06-17 10:00:00
author: "OpsOps"
header-img: "img/post-bg-k8s.jpg"
catalog: true
tags:
  - Kubernetes
  - K8s
  - 容器编排
  - DevOps
  - 云原生
---

## 一、引言

Kubernetes（简称K8s）作为云原生时代的核心编排平台，其组件架构设计是理解和运维K8s集群的基础。一个稳定高效的K8s集群依赖于各组件的协同工作，了解每个组件的职责和工作机制，对于构建、维护和故障排查都至关重要。本文将深入剖析K8s的核心组件架构，并分享生产环境中的最佳实践。

---

## 二、SCQA分析框架

### 情境（Situation）
- K8s已成为容器编排的标准，广泛应用于生产环境
- 集群规模不断扩大，组件间协作复杂度增加
- 高可用性要求越来越高，任何组件故障都可能影响业务

### 冲突（Complication）
- 组件众多，职责划分不清晰
- 控制平面组件故障可能导致整个集群不可用
- 节点组件问题影响Pod运行，但定位困难
- 缺乏系统化的组件管理和监控策略

### 问题（Question）
- K8s集群由哪些组件组成？
- 每个组件的核心功能是什么？
- 组件之间如何协作？
- 如何确保组件的高可用性？
- 生产环境中如何优化组件配置？

### 答案（Answer）
- K8s分为控制平面和节点组件两大部分
- 控制平面负责集群管理和决策，节点组件负责执行
- 通过API Server实现组件间通信
- 部署多节点高可用集群保障稳定性
- 配置资源限制、监控告警确保可靠性

---

## 三、Kubernetes架构概览

### 3.1 整体架构图

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Kubernetes 集群架构                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │              Control Plane (控制平面)                        │   │
│  │                                                             │   │
│  │  ┌──────────────┐    ┌──────────────────┐                   │   │
│  │  │ kube-apiserver│───▶│      etcd       │                   │   │
│  │  │   (API入口)   │◀───│  (状态存储)     │                   │   │
│  │  └───────┬──────┘    └──────────────────┘                   │   │
│  │          │                                                   │   │
│  │          ▼                                                   │   │
│  │  ┌──────────────┐    ┌──────────────────┐                   │   │
│  │  │kube-scheduler│    │kube-controller- │                   │   │
│  │  │   (调度器)    │    │   manager       │                   │   │
│  │  └──────────────┘    └──────────────────┘                   │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              │                                     │
│                              │ HTTPS                              │
│                              ▼                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    Worker Nodes (工作节点)                   │   │
│  │                                                             │   │
│  │  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐   │   │
│  │  │   kubelet    │    │  kube-proxy  │    │ Container    │   │   │
│  │  │  (节点代理)   │    │  (网络代理)   │    │   Runtime    │   │   │
│  │  └──────────────┘    └──────────────┘    └──────────────┘   │   │
│  │          │                  │                  │             │   │
│  │          ▼                  ▼                  ▼             │   │
│  │  ┌──────────────────────────────────────────────────────┐   │   │
│  │  │                      Pods                           │   │   │
│  │  │  ┌─────┐  ┌─────┐  ┌─────┐  ┌───────────────────┐   │   │
│  │  │  │App1 │  │App2 │  │App3 │  │   Sidecar/Init    │   │   │
│  │  │  └─────┘  └─────┘  └─────┘  └───────────────────┘   │   │
│  │  └──────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

### 3.2 组件分类

| 层级 | 组件 | 角色 | 部署位置 |
|:------|:------|:------|:------|
| **控制平面** | kube-apiserver | API入口 | Control Plane节点 |
| | etcd | 状态存储 | Control Plane节点 |
| | kube-scheduler | Pod调度 | Control Plane节点 |
| | kube-controller-manager | 状态管理 | Control Plane节点 |
| | cloud-controller-manager | 云厂商适配 | Control Plane节点（可选） |
| **节点组件** | kubelet | 节点代理 | Worker节点 |
| | kube-proxy | 网络代理 | Worker节点 |
| | Container Runtime | 容器运行时 | Worker节点 |
| **附加组件** | CoreDNS | DNS解析 | 集群内部 |
| | CNI插件 | 网络通信 | Worker节点 |
| | Ingress Controller | 外部访问 | 集群内部 |
| | Prometheus/Grafana | 监控告警 | 集群内部 |

---

## 四、控制平面组件详解

### 4.1 kube-apiserver

**核心职责**：
- 集群的唯一入口，所有操作都必须通过它
- 提供RESTful API接口（kubectl、UI、SDK）
- 认证（Authentication）：验证请求者身份
- 授权（Authorization）：验证请求权限
- 准入控制（Admission Control）：检查请求合法性
- 唯一与etcd直接交互的组件

**架构特点**：
- 无状态设计，支持水平扩展
- 提供Watch机制，支持增量更新
- 实现RBAC细粒度权限控制

**高可用部署**：
```bash
# 至少部署3个实例
# 使用负载均衡器（如HAProxy）
# 配置示例（HAProxy）
frontend k8s-api
  bind *:6443
  default_backend k8s-api-servers

backend k8s-api-servers
  balance roundrobin
  server api1 192.168.1.10:6443 check
  server api2 192.168.1.11:6443 check
  server api3 192.168.1.12:6443 check
```

### 4.2 etcd

**核心职责**：
- 分布式键值数据库，存储集群所有状态数据
- 保存Pod、Service、Node、ConfigMap、Secret等资源对象
- 通过Raft一致性算法保证数据强一致性
- 提供Watch机制，支持实时监听数据变化

**与Redis对比**：

| 特性 | etcd | Redis |
|:------|:------|:------|
| 一致性 | 强一致性（线性一致性） | 最终一致性 |
| 持久化 | 默认开启（WAL + Snapshot） | 可选（RDB/AOF） |
| Watch机制 | 原生可靠事件通知 | Pub/Sub（不保证可靠） |
| 适用场景 | 元数据存储、分布式锁 | 缓存、会话存储 |

**生产配置建议**：
```bash
# 部署3/5/7节点集群（奇数节点）
# 配置示例
etcd --name=etcd1 \
  --data-dir=/var/lib/etcd \
  --listen-peer-urls=https://192.168.1.10:2380 \
  --listen-client-urls=https://192.168.1.10:2379 \
  --initial-advertise-peer-urls=https://192.168.1.10:2380 \
  --advertise-client-urls=https://192.168.1.10:2379 \
  --initial-cluster=etcd1=https://192.168.1.10:2380,etcd2=https://192.168.1.11:2380,etcd3=https://192.168.1.12:2380 \
  --initial-cluster-token=etcd-cluster-1 \
  --initial-cluster-state=new
```

### 4.3 kube-scheduler

**核心职责**：
- 为新创建的Pod分配合适的Worker节点
- 监听API Server获取未调度的Pod
- 执行调度算法：预选策略 + 优选策略
- 只做调度决策，不负责创建Pod

**调度流程**：
```
1. 监听：Watch API Server获取未调度Pod
2. 预选：过滤不满足条件的节点（资源不足、端口冲突等）
3. 优选：对候选节点打分排序（资源利用率、亲和性等）
4. 绑定：将Pod与最优节点绑定，写入etcd
```

**调度策略示例**：
```yaml
# Pod调度约束示例
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd
  tolerations:
  - key: "key"
    operator: "Exists"
    effect: "NoSchedule"
```

### 4.4 kube-controller-manager

**核心职责**：
- 维护集群的期望状态，确保实际状态与期望状态一致
- 包含多个子控制器，每个负责一类资源

**子控制器列表**：

| 控制器 | 职责 |
|:------|:------|
| Replication Controller | 维护Pod副本数 |
| Deployment Controller | 管理Deployment对象 |
| StatefulSet Controller | 管理有状态应用 |
| DaemonSet Controller | 确保每个节点运行Pod |
| Node Controller | 监控节点状态 |
| Service Controller | 管理Service和Endpoint |
| EndpointSlice Controller | 管理Endpoint分片 |
| Namespace Controller | 管理命名空间 |
| PersistentVolume Controller | 管理存储卷 |

**工作模式（Reconcile Loop）**：
```
监听状态变化 → 对比期望状态 → 执行调谐操作 → 更新状态
```

### 4.5 cloud-controller-manager

**核心职责**：
- 对接云厂商API，管理云资源
- 实现云中立架构，使K8s可在任意环境运行
- 负责负载均衡、存储、网络等云资源的管理

**支持的云厂商**：
- AWS、Azure、GCP、阿里云、腾讯云等

---

## 五、节点组件详解

### 5.1 kubelet

**核心职责**：
- 节点代理，控制平面与容器运行时的桥梁
- Pod生命周期管理（创建/启动/停止/删除）
- 状态同步（上报Node/Pod状态到API Server）
- 卷管理（挂载/卸载PV/PVC）
- 网络配置（调用CNI插件）
- 健康检查（Liveness/Readiness/Startup Probe）
- 资源管理（QoS保障：Guaranteed/Burstable/BestEffort）

**工作流程**：
```
1. 向API Server注册节点
2. 监听Pod配置变化
3. 通过CRI调用容器运行时创建容器
4. 执行健康检查，必要时重启容器
5. 定期上报节点和Pod状态
```

**健康检查配置示例**：
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
  - name: app
    image: myapp:latest
    ports:
    - containerPort: 8080
    livenessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 30
      timeoutSeconds: 10
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 10
      periodSeconds: 5
```

### 5.2 kube-proxy

**核心职责**：
- 维护节点上的网络规则
- 实现Service的ClusterIP到后端Pod的流量转发
- 提供服务发现和负载均衡能力

**工作模式**：

| 模式 | 特点 | 适用场景 |
|:------|:------|:------|
| **iptables** | 默认模式，基于Netfilter | 中小规模集群 |
| **ipvs** | 基于IPVS内核模块 | 大规模高流量集群 |

**切换到ipvs模式**：
```bash
# 安装ipvs依赖
apt-get install ipvsadm ipset

# 修改kube-proxy配置
kubectl edit configmap kube-proxy -n kube-system
# mode: "ipvs"

# 重启kube-proxy
kubectl rollout restart daemonset kube-proxy -n kube-system
```

### 5.3 Container Runtime

**核心职责**：
- 负责创建、运行和管理容器进程
- 遵循CRI（Container Runtime Interface）规范
- 提供镜像管理、容器生命周期管理、资源隔离能力

**主流选择**：

| Runtime | 特点 | 推荐度 |
|:------|:------|:------|
| **containerd** | Docker公司捐赠，CNCF毕业项目 | 推荐 |
| **CRI-O** | Red Hat主导，轻量级 | 推荐 |
| **Docker** | 原始实现，但已将运行时分离 | 不推荐（仅作build工具） |

**containerd配置示例**：
```bash
# 配置containerd使用systemd cgroup驱动
cat > /etc/containerd/config.toml <<EOF
[plugins."io.containerd.grpc.v1.cri"]
  sandbox_image = "registry.k8s.io/pause:3.9"
  [plugins."io.containerd.grpc.v1.cri".containerd]
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
        runtime_type = "io.containerd.runc.v2"
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
          SystemdCgroup = true
EOF

systemctl restart containerd
```

---

## 六、附加组件

### 6.1 CoreDNS

**核心职责**：
- 提供集群内DNS解析服务
- Pod通过Service名称访问服务
- 支持自定义域名解析

**配置示例**：
```yaml
apiVersion: v1
kind: Service
metadata:
  name: kube-dns
  namespace: kube-system
spec:
  selector:
    k8s-app: kube-dns
  clusterIP: 10.96.0.10
  ports:
  - name: dns
    port: 53
    protocol: UDP
  - name: dns-tcp
    port: 53
    protocol: TCP
```

### 6.2 CNI插件

**核心职责**：
- 实现Pod间网络互通
- 支持跨节点Pod通信
- 提供网络策略（NetworkPolicy）

**主流CNI插件**：

| 插件 | 特点 | 适用场景 |
|:------|:------|:------|
| **Calico** | 支持网络策略，性能优异 | 大规模集群 |
| **Flannel** | 简单易用，配置简单 | 中小规模集群 |
| **Weave** | 自动配置，无需额外依赖 | 快速部署 |

**NetworkPolicy示例**：
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

### 6.3 Ingress Controller

**核心职责**：
- 管理外部访问集群服务
- 提供负载均衡、SSL终止、路径路由

**主流选择**：
- Nginx Ingress Controller
- Traefik
- HAProxy Ingress

**Ingress配置示例**：
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - example.com
    secretName: example-tls
  rules:
  - host: example.com
    http:
      paths:
      - path: /app
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 80
```

---

## 七、组件通信流程

### 7.1 典型操作流程

**用户创建Deployment**：
```bash
kubectl apply -f deployment.yaml
```

**内部执行流程**：
```
1. kubectl发送请求到kube-apiserver
2. apiserver验证请求（认证、授权、准入控制）
3. apiserver将Deployment写入etcd
4. kube-controller-manager监听到变化
5. controller-manager创建ReplicaSet和Pod
6. kube-scheduler为Pod选择节点
7. scheduler将Pod绑定信息写入etcd
8. 目标节点的kubelet监听到Pod创建事件
9. kubelet通过CRI调用containerd创建容器
10. kube-proxy配置Service网络规则
11. Pod状态上报到apiserver，最终写入etcd
```

### 7.2 网络通信安全

- 所有组件间通信使用HTTPS
- API Server提供证书颁发
- 使用ServiceAccount令牌进行认证
- RBAC控制访问权限

---

## 八、生产环境最佳实践

### 8.1 控制平面高可用

**部署架构**：
```
┌──────────────────────────────────────────────────────┐
│                   Load Balancer                      │
│                    (VIP: 6443)                      │
└───────────────────────┬──────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  Master-01  │  │  Master-02  │  │  Master-03  │
│ API Server  │  │ API Server  │  │ API Server  │
│ Scheduler   │  │ Scheduler   │  │ Scheduler   │
│ Controller  │  │ Controller  │  │ Controller  │
│ Manager     │  │ Manager     │  │ Manager     │
│ etcd        │  │ etcd        │  │ etcd        │
└─────────────┘  └─────────────┘  └─────────────┘
```

**kubeadm高可用部署**：
```bash
# 初始化第一个控制平面节点
kubeadm init \
  --control-plane-endpoint "vip.example.com:6443" \
  --upload-certs \
  --pod-network-cidr=10.244.0.0/16

# 加入额外控制平面节点
kubeadm join vip.example.com:6443 \
  --token xxx \
  --discovery-token-ca-cert-hash sha256:xxx \
  --control-plane \
  --certificate-key xxx
```

### 8.2 etcd备份与恢复

**定期备份**：
```bash
# 创建备份脚本
cat > /usr/local/bin/etcd-backup.sh <<EOF
#!/bin/bash
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR=/var/lib/etcd-backups
mkdir -p $BACKUP_DIR

ETCDCTL_API=3 etcdctl snapshot save $BACKUP_DIR/snapshot-$DATE.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# 保留最近7天的备份
find $BACKUP_DIR -name "snapshot-*.db" -mtime +7 -delete
EOF

chmod +x /usr/local/bin/etcd-backup.sh

# 添加定时任务
echo "0 2 * * * /usr/local/bin/etcd-backup.sh" >> /var/spool/cron/root
```

**恢复操作**：
```bash
# 停止etcd服务
systemctl stop etcd

# 恢复备份
ETCDCTL_API=3 etcdctl snapshot restore snapshot.db \
  --data-dir=/var/lib/etcd

# 启动etcd服务
systemctl start etcd
```

### 8.3 资源限制配置

**控制平面组件资源限制**：
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kube-apiserver
  namespace: kube-system
spec:
  containers:
  - name: kube-apiserver
    resources:
      requests:
        cpu: "2"
        memory: "4Gi"
      limits:
        cpu: "4"
        memory: "8Gi"
```

**节点资源预留**：
```yaml
apiVersion: v1
kind: Node
metadata:
  name: worker-01
spec:
  taints:
  - key: node-role.kubernetes.io/worker
    effect: NoSchedule
  allocatable:
    cpu: "32"
    memory: "62Gi"
    pods: "110"
```

### 8.4 监控与告警

**组件指标采集**：
```yaml
# Prometheus ServiceMonitor配置
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: kube-apiserver
  namespace: monitoring
spec:
  selector:
    matchLabels:
      component: apiserver
  endpoints:
  - port: https
    scheme: https
    tlsConfig:
      caFile: /etc/prometheus/secrets/kubelet-ca/ca.crt
      serverName: kubernetes
```

**关键告警规则**：
```yaml
groups:
- name: k8s-control-plane.rules
  rules:
  - alert: APIServerDown
    expr: up{job="kube-apiserver"} == 0
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "API Server不可用"
      description: "API Server {{ $labels.instance }} 已停止响应"

  - alert: EtcdClusterUnhealthy
    expr: etcd_cluster_health != 1
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "etcd集群不健康"
      description: "etcd集群健康状态异常"

  - alert: KubeletDown
    expr: kube_node_status_condition{condition="Ready",status="true"} == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Kubelet离线"
      description: "节点 {{ $labels.node }} Kubelet已离线"
```

---

## 九、常见问题与解决方案

### 问题一：API Server响应缓慢

**现象**：kubectl命令超时，API响应延迟高

**原因分析**：
- 请求量过大，API Server资源不足
- etcd性能瓶颈
- 网络带宽不足

**解决方案**：
```bash
# 增加API Server资源
# 配置etcd性能优化
# 启用API Server缓存
# 水平扩展API Server实例
```

### 问题二：Pod调度失败

**现象**：Pod长时间处于Pending状态

**原因分析**：
- 节点资源不足
- 污点容忍配置问题
- 亲和性规则冲突
- 端口冲突

**解决方案**：
```bash
# 检查节点资源
kubectl describe node <node-name>

# 检查Pod调度事件
kubectl describe pod <pod-name>

# 调整调度约束或增加节点
```

### 问题三：Service无法访问

**现象**：通过Service ClusterIP无法访问后端Pod

**原因分析**：
- kube-proxy未运行或配置错误
- 网络策略阻止流量
- Endpoint未正确配置
- CNI网络问题

**解决方案**：
```bash
# 检查kube-proxy状态
kubectl get pods -n kube-system -l k8s-app=kube-proxy

# 检查Endpoint状态
kubectl get endpoints <service-name>

# 检查网络策略
kubectl get networkpolicy
```

### 问题四：etcd数据损坏

**现象**：集群状态异常，无法正常操作

**解决方案**：
```bash
# 使用备份恢复
ETCDCTL_API=3 etcdctl snapshot restore snapshot.db

# 重建etcd集群
```

---

## 十、总结

### 核心要点

1. **架构分层**：控制平面负责决策，节点组件负责执行
2. **组件协作**：所有操作通过API Server，状态存储在etcd
3. **高可用性**：控制平面多节点部署，etcd Raft集群
4. **网络通信**：组件间使用HTTPS，kube-proxy实现Service网络
5. **监控告警**：监控关键组件状态，及时发现问题

### 实施建议

| 阶段 | 任务 | 时间 |
|:------|:------|:------|
| 第一阶段 | 部署单节点测试集群 | 1天 |
| 第二阶段 | 部署多节点高可用集群 | 2-3天 |
| 第三阶段 | 配置监控告警体系 | 1-2天 |
| 第四阶段 | 制定备份恢复策略 | 1天 |
| 第五阶段 | 性能优化和安全加固 | 持续 |

> 本文对应的面试题：[K8s里边组件都有哪些呢？然后功能是什么？]({% post_url 2026-04-15-sre-interview-questions %})

---

## 附录：常用K8s组件命令

```bash
# 查看控制平面组件状态
kubectl get pods -n kube-system -l tier=control-plane

# 查看节点状态
kubectl get nodes

# 查看etcd状态
ETCDCTL_API=3 etcdctl endpoint health --endpoints=https://127.0.0.1:2379

# 查看kubelet日志
journalctl -u kubelet -f

# 查看kube-proxy配置
kubectl get configmap kube-proxy -n kube-system -o yaml
```
