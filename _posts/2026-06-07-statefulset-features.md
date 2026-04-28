---
layout: post
title: "StatefulSet四大特性深度解析：有状态应用管理最佳实践"
subtitle: "从网络标识到持久化存储，全面掌握StatefulSet核心机制"
date: 2026-06-07 10:00:00
author: "OpsOps"
header-img: "img/post-bg-k8s.jpg"
catalog: true
tags:
  - Kubernetes
  - StatefulSet
  - 有状态应用
  - 存储管理
---

## 一、引言

Kubernetes从诞生之初就围绕"无状态优先"的设计理念，Pod随时可能死亡、节点随时可能宕机、调度是随机的。这套理念与需要持久化数据、固定身份和可控恢复顺序的数据库、消息队列等有状态应用天然冲突。StatefulSet的引入标志着Kubernetes向有状态应用管理迈出的关键一步，为管理有状态应用程序提供了基础功能。本文将深入剖析StatefulSet的四大核心特性，并提供生产环境最佳实践。

---

## 二、SCQA分析框架

### 情境（Situation）
- Kubernetes已成为容器编排的事实标准
- 企业越来越多地将有状态应用迁移到Kubernetes
- 数据库、消息队列等有状态应用需要特殊的管理机制

### 冲突（Complication）
- Deployment管理的Pod名称随机、IP地址可变，不适合有状态应用
- 有状态应用需要稳定的网络标识和持久化存储
- 需要有序的部署、扩缩容和更新机制

### 问题（Question）
- StatefulSet的四大核心特性是什么？
- 如何实现稳定的网络标识？
- 有序操作的具体机制是什么？
- 如何实现稳定的持久化存储？
- 生产环境中如何优化StatefulSet配置？

### 答案（Answer）
- StatefulSet四大特性：稳定网络标识、有序部署扩缩容、有序滚动更新、稳定持久化存储
- 通过Headless Service和固定Pod名称实现稳定网络标识
- 通过序号控制实现有序操作
- 通过volumeClaimTemplates实现稳定存储绑定
- 合理配置Pod管理策略、更新策略和存储类

---

## 三、StatefulSet核心概念

### 什么是StatefulSet？

StatefulSet是Kubernetes用于管理有状态应用的工作负载API对象，它管理一组Pod的部署和扩缩，并为这些Pod提供持久存储和持久标识符。

### 与Deployment的区别

| 特性 | Deployment | StatefulSet |
|:------|:------|:------|
| **Pod名称** | 随机生成（如mysql-5d4f7b8c9-xk2mh） | 固定格式（如mysql-0、mysql-1） |
| **网络标识** | 随机IP，DNS不稳定 | 固定DNS记录 |
| **存储绑定** | 无固定绑定或共享 | 每个Pod独立PVC |
| **部署顺序** | 并行创建 | 顺序创建（0→1→2） |
| **更新顺序** | 随机或并行 | 逆序更新（2→1→0） |
| **适用场景** | 无状态应用 | 有状态应用 |

### 适用场景

- **数据库**：MySQL、PostgreSQL、MongoDB、Cassandra
- **消息队列**：Kafka、RabbitMQ、ActiveMQ
- **分布式存储**：Redis Cluster、Elasticsearch、Ceph
- **需要固定网络标识的应用**：任何需要稳定身份的服务

---

## 四、特性一：稳定的网络标识（Stable Network Identity）

### 核心机制

StatefulSet为每个Pod分配一个固定且可预测的名称，格式为`<statefulset-name>-<序号>`，序号从0开始递增。

### Pod名称示例

```
StatefulSet名称：mysql
副本数：3

生成的Pod：
mysql-0
mysql-1
mysql-2
```

这些名称在Pod的生命周期内保持不变。即使Pod被重新调度到另一个节点，其名称和DNS地址也不会改变。

### Headless Service配合

StatefulSet需要配合Headless Service（clusterIP: None）来提供稳定的网络标识。

#### Headless Service配置

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-svc
  labels:
    app: mysql
spec:
  clusterIP: None  # 关键：设置为None
  selector:
    app: mysql
  ports:
  - port: 3306
    name: mysql
    targetPort: 3306
```

#### DNS记录格式

每个Pod都会获得一个唯一的DNS记录：

```
<pod-name>.<service-name>.<namespace>.svc.cluster.local

示例：
mysql-0.mysql-svc.default.svc.cluster.local
mysql-1.mysql-svc.default.svc.cluster.local
mysql-2.mysql-svc.default.svc.cluster.local
```

### DNS解析验证

```bash
# 启动临时Pod进行DNS查询
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup mysql-0.mysql-svc

# 输出示例：
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      mysql-0.mysql-svc
Address 1: 10.244.1.5 mysql-0.mysql-svc.default.svc.cluster.local
```

### 网络标识的重要性

对于有主从架构的数据库，稳定的网络标识至关重要：

```bash
# MySQL主从复制配置示例
CHANGE MASTER TO
  MASTER_HOST='mysql-0.mysql-svc.default.svc.cluster.local',
  MASTER_USER='repl',
  MASTER_PASSWORD='password',
  MASTER_LOG_FILE='mysql-bin.000001',
  MASTER_LOG_POS=154;
```

即使mysql-0 Pod重建，其DNS名称不变，从库无需重新配置主库地址。

---

## 五、特性二：有序的部署和扩缩容（Ordered Deployment & Scaling）

### 部署顺序

StatefulSet的Pod按序号顺序进行部署：

```
部署顺序：mysql-0 → mysql-1 → mysql-2
规则：前一个Pod处于Running和Ready状态后，才创建下一个Pod
```

#### 部署流程图

```
开始
  ↓
创建 mysql-0
  ↓
等待 mysql-0 Ready
  ↓
创建 mysql-1
  ↓
等待 mysql-1 Ready
  ↓
创建 mysql-2
  ↓
等待 mysql-2 Ready
  ↓
部署完成
```

#### 观察部署过程

```bash
# 实时观察Pod创建过程
kubectl get pods -w -l app=mysql

# 输出示例：
NAME      READY   STATUS    RESTARTS   AGE
mysql-0   0/1     Pending   0          0s
mysql-0   0/1     ContainerCreating   0          2s
mysql-0   1/1     Running   0          5s
mysql-0   1/1     Ready     0          10s
mysql-1   0/1     Pending   0          0s
mysql-1   0/1     ContainerCreating   0          2s
mysql-1   1/1     Running   0          5s
mysql-1   1/1     Ready     0          10s
mysql-2   0/1     Pending   0          0s
...
```

### 扩容顺序

扩容时，StatefulSet会按照序号顺序创建新的Pod：

```bash
# 从3个副本扩容到5个
kubectl scale statefulset mysql --replicas=5

# 创建顺序：mysql-3 → mysql-4
```

#### 扩容流程

```
当前副本数：3（mysql-0, mysql-1, mysql-2）
目标副本数：5

执行顺序：
1. 创建 mysql-3
2. 等待 mysql-3 Ready
3. 创建 mysql-4
4. 等待 mysql-4 Ready
5. 扩容完成
```

### 缩容顺序

缩容时，StatefulSet会逆序删除Pod：

```
删除顺序：mysql-4 → mysql-3 → mysql-2 → mysql-1 → mysql-0
规则：先删除序号最大的Pod，确保数据安全
```

#### 缩容流程

```bash
# 从5个副本缩容到3个
kubectl scale statefulset mysql --replicas=3

# 删除顺序：
# 1. 删除 mysql-4
# 2. 等待 mysql-4 完全终止
# 3. 删除 mysql-3
# 4. 等待 mysql-3 完全终止
# 5. 缩容完成
```

### 有序操作的意义

对于主从架构的数据库，有序操作至关重要：

1. **主从关系建立**：mysql-0作为主库，mysql-1、mysql-2作为从库
2. **数据一致性**：确保从库在主库就绪后才启动，避免复制失败
3. **故障恢复**：缩容时先删除从库，保护主库数据

### Pod管理策略

StatefulSet提供了`podManagementPolicy`字段来控制Pod的创建和删除行为：

#### OrderedReady（默认）

```yaml
spec:
  podManagementPolicy: OrderedReady
```

**特点**：
- 严格的顺序操作
- 每个Pod必须处于Ready状态才能进行下一个
- 适合主从架构、需要严格顺序的应用

#### Parallel

```yaml
spec:
  podManagementPolicy: Parallel
```

**特点**：
- 并行创建/删除所有Pod
- 不等待每个Pod就绪
- 适合可独立启动的有状态应用
- 可以加快部署速度

#### 策略对比

| 策略 | 创建顺序 | 删除顺序 | 适用场景 |
|:------|:------|:------|:------|
| OrderedReady | 顺序（0→1→2） | 逆序（2→1→0） | 主从架构、严格顺序要求 |
| Parallel | 并行 | 并行 | 独立启动、快速部署 |

---

## 六、特性三：有序的滚动更新（Ordered Rolling Update）

### 更新顺序

StatefulSet的滚动更新默认采用逆序进行：

```
更新顺序：mysql-2 → mysql-1 → mysql-0
规则：从最大序号开始逐个更新
```

### 更新策略配置

#### RollingUpdate（默认）

```yaml
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 0  # 默认值，更新所有Pod
```

**更新流程**：

```
1. 更新 mysql-2
2. 等待 mysql-2 Ready
3. 更新 mysql-1
4. 等待 mysql-1 Ready
5. 更新 mysql-0
6. 等待 mysql-0 Ready
7. 更新完成
```

#### OnDelete

```yaml
spec:
  updateStrategy:
    type: OnDelete
```

**特点**：
- 只有Pod被手动删除后才会用新镜像重建
- 适用于需要严格人工控制的场景
- 更新完全由运维人员控制

### Partition控制

Partition是StatefulSet滚动更新的核心机制，用于控制更新范围。

#### Partition工作原理

Partition参数指定一个序号阈值，只有序号大于等于该值的Pod才会被更新。

```
partition = 0：更新所有Pod（mysql-0, mysql-1, mysql-2）
partition = 1：更新序号 >= 1 的Pod（mysql-1, mysql-2）
partition = 2：更新序号 >= 2 的Pod（mysql-2）
partition = 3：不更新任何Pod
```

#### 金丝雀发布实战

```bash
# 场景：将MySQL从5.7升级到8.0

# 第一步：更新镜像
kubectl set image statefulset mysql mysql=mysql:8.0

# 第二步：只更新最后一个Pod（partition=2）
kubectl patch statefulset mysql -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":2}}}}'

# 此时只有mysql-2会更新到8.0版本
# mysql-0和mysql-1仍运行5.7版本

# 第三步：验证mysql-2运行正常
kubectl exec -it mysql-2 -- mysql -V
# 输出：mysql  Ver 8.0.35

# 第四步：扩大更新范围（partition=1）
kubectl patch statefulset mysql -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":1}}}}'

# 此时mysql-1和mysql-2运行8.0版本
# mysql-0仍运行5.7版本

# 第五步：全量更新（partition=0）
kubectl patch statefulset mysql -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":0}}}}'

# 所有Pod都更新到8.0版本
```

#### Partition状态示意图

```
初始状态（5.7版本）：
mysql-0: 5.7  mysql-1: 5.7  mysql-2: 5.7

partition=2：
mysql-0: 5.7  mysql-1: 5.7  mysql-2: 8.0

partition=1：
mysql-0: 5.7  mysql-1: 8.0  mysql-2: 8.0

partition=0：
mysql-0: 8.0  mysql-1: 8.0  mysql-2: 8.0
```

### 更新失败处理

如果某个Pod更新失败，StatefulSet会停止更新流程：

```bash
# 查看更新状态
kubectl rollout status statefulset/mysql

# 如果更新卡住，可以手动回滚
kubectl rollout undo statefulset/mysql

# 或者删除失败的Pod，让它重建
kubectl delete pod mysql-2
```

---

## 七、特性四：稳定的持久化存储（Stable Persistent Storage）

### 核心机制

StatefulSet通过`volumeClaimTemplates`为每个Pod自动创建独立的PersistentVolumeClaim（PVC）。

### volumeClaimTemplates配置

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql-svc
  replicas: 3
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: fast-ssd
      resources:
        requests:
          storage: 10Gi
  template:
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
```

### PVC命名规则

StatefulSet会为每个Pod自动创建PVC，命名规则为：

```
<volumeClaimTemplate-name>-<statefulset-name>-<序号>

示例：
data-mysql-0
data-mysql-1
data-mysql-2
```

### PVC绑定关系

```
mysql-0 → data-mysql-0 → PV-1 → /dev/sdb
mysql-1 → data-mysql-1 → PV-2 → /dev/sdc
mysql-2 → data-mysql-2 → PV-3 → /dev/sdd
```

### 存储行为详解

#### 扩容行为

```bash
# 从3个副本扩容到5个
kubectl scale statefulset mysql --replicas=5

# 自动创建新的PVC：
# - data-mysql-3
# - data-mysql-4
```

#### 缩容行为

```bash
# 从5个副本缩容到3个
kubectl scale statefulset mysql --replicas=3

# 删除Pod：mysql-4, mysql-3
# PVC不会自动删除（保护数据安全）
# 需要手动清理：
kubectl delete pvc data-mysql-3 data-mysql-4
```

#### 重建行为

```bash
# 删除Pod
kubectl delete pod mysql-1

# Pod重建后：
# - 新的mysql-1 Pod会重新绑定到data-mysql-1
# - 数据不会丢失
# - 应用可以继续使用原有数据
```

### 存储类选择

#### ReadWriteOnce（传统模式）

```yaml
accessModes: ["ReadWriteOnce"]
```

**特点**：
- 单节点读写
- 适用于单副本应用
- 兼容性好

#### ReadWriteOncePod（推荐生产使用）

```yaml
accessModes: ["ReadWriteOncePod"]
```

**特点**：
- 单Pod读写
- 更好的隔离性
- 防止多Pod同时挂载导致数据损坏
- Kubernetes 1.22+支持

#### ReadOnlyMany

```yaml
accessModes: ["ReadOnlyMany"]
```

**特点**：
- 多节点只读
- 适用于需要多副本读取的场景

### 存储安全配置

```yaml
volumeClaimTemplates:
- metadata:
      name: data
      annotations:
        # 设置PVC保护，防止误删除
        pv.kubernetes.io/protection: "true"
    spec:
      accessModes: ["ReadWriteOncePod"]
      storageClassName: fast-ssd
      resources:
        requests:
          storage: 10Gi
        limits:
          storage: 20Gi
```

---

## 八、完整示例：MySQL主从集群

### Headless Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-svc
  labels:
    app: mysql
spec:
  clusterIP: None
  selector:
    app: mysql
  ports:
  - port: 3306
    name: mysql
    targetPort: 3306
```

### ConfigMap（配置文件）

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql-config
data:
  my.cnf: |
    [mysqld]
    log-bin=mysql-bin
    server-id=1
    binlog-format=ROW
    max_connections=500
    innodb_buffer_pool_size=1G
```

### Secret（密码）

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mysql-secret
type: Opaque
data:
  root-password: cGFzc3dvcmQxMjM=
```

### StatefulSet

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql-svc
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  podManagementPolicy: OrderedReady
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 0
  template:
    metadata:
      labels:
        app: mysql
    spec:
      terminationGracePeriodSeconds: 30
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
          name: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: root-password
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
        - name: config
          mountPath: /etc/mysql/conf.d
        livenessProbe:
          exec:
            command:
            - mysqladmin
            - ping
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command:
            - mysql
            - -h
            - 127.0.0.1
            - -e
            - SELECT 1
          initialDelaySeconds: 5
          periodSeconds: 2
      volumes:
      - name: config
        configMap:
          name: mysql-config
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOncePod"]
      storageClassName: fast-ssd
      resources:
        requests:
          storage: 20Gi
```

### 部署和验证

```bash
# 1. 创建资源
kubectl apply -f mysql-svc.yaml
kubectl apply -f mysql-config.yaml
kubectl apply -f mysql-secret.yaml
kubectl apply -f mysql-statefulset.yaml

# 2. 观察Pod创建过程
kubectl get pods -w -l app=mysql

# 3. 查看PVC
kubectl get pvc

# 4. 验证DNS解析
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup mysql-0.mysql-svc

# 5. 连接数据库测试
kubectl exec -it mysql-0 -- mysql -uroot -ppassword123

# 6. 查看Pod状态
kubectl get statefulset mysql
kubectl describe statefulset mysql
```

---

## 九、生产环境最佳实践

### 1. Pod管理策略选择

#### 主从架构数据库

```yaml
spec:
  podManagementPolicy: OrderedReady  # 严格顺序
```

**原因**：
- 确保主库先启动
- 从库在主库就绪后启动
- 避免复制关系混乱

#### 独立启动的应用

```yaml
spec:
  podManagementPolicy: Parallel  # 并行启动
```

**适用场景**：
- Elasticsearch集群
- Redis Cluster
- 无主从关系的应用

### 2. 更新策略优化

#### 金丝雀发布

```bash
# 分阶段更新
kubectl patch statefulset mysql -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":2}}}}'
# 验证后
kubectl patch statefulset mysql -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":1}}}}'
# 验证后
kubectl patch statefulset mysql -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":0}}}}'
```

#### 手动控制更新

```yaml
spec:
  updateStrategy:
    type: OnDelete
```

**适用场景**：
- 需要人工验证每个Pod
- 复杂的数据库升级
- 需要数据迁移的场景

### 3. 存储安全配置

#### 使用ReadWriteOncePod

```yaml
accessModes: ["ReadWriteOncePod"]
```

**优势**：
- 防止多Pod同时挂载
- 避免数据损坏
- 更好的隔离性

#### 设置存储限制

```yaml
resources:
  requests:
    storage: 10Gi
  limits:
    storage: 20Gi
```

**作用**：
- 防止Pod占用过多存储
- 提前规划存储容量
- 避免存储耗尽

#### PVC保护

```yaml
metadata:
  annotations:
    pv.kubernetes.io/protection: "true"
```

**作用**：
- 防止误删除PVC
- 保护数据安全

### 4. 健康检查配置

```yaml
livenessProbe:
  exec:
    command:
    - mysqladmin
    - ping
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3

readinessProbe:
  exec:
    command:
    - mysql
    - -h
    - 127.0.0.1
    - -e
    - SELECT 1
  initialDelaySeconds: 5
  periodSeconds: 2
  timeoutSeconds: 1
  failureThreshold: 3
```

### 5. 资源限制配置

```yaml
resources:
  requests:
    cpu: "500m"
    memory: "1Gi"
  limits:
    cpu: "2000m"
    memory: "4Gi"
```

### 6. 优雅终止配置

```yaml
spec:
  terminationGracePeriodSeconds: 60  # 增加终止宽限期
  template:
    spec:
      containers:
      - name: mysql
        lifecycle:
          preStop:
            exec:
              command:
              - /bin/sh
              - -c
              - mysqladmin shutdown -uroot -p${MYSQL_ROOT_PASSWORD}
```

### 7. 监控与告警

#### 关键监控指标

```yaml
# Prometheus监控规则
groups:
- name: statefulset
  rules:
  - alert: StatefulSetPodNotReady
    expr: kube_statefulset_status_replicas_ready < kube_statefulset_replicas
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "StatefulSet {{ $labels.statefulset }} has unready pods"
      
  - alert: StatefulSetUpdateStuck
    expr: kube_statefulset_status_current_revision != kube_statefulset_status_update_revision
    for: 30m
    labels:
      severity: critical
    annotations:
      summary: "StatefulSet {{ $labels.statefulset }} update is stuck"
```

#### 日志收集

```yaml
# 使用Fluentd收集日志
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
data:
  fluent.conf: |
    <source>
      @type tail
      path /var/log/mysql/*.log
      pos_file /var/log/fluentd-mysql.pos
      tag mysql.*
      <parse>
        @type json
      </parse>
    </source>
```

---

## 十、常见问题与解决方案

### 问题一：Pod卡在Pending状态

**现象**：
```bash
kubectl get pods
NAME      READY   STATUS    RESTARTS   AGE
mysql-0   0/1     Pending   0          5m
```

**原因**：
- PVC无法创建
- StorageClass配置错误
- 存储资源不足

**解决方案**：
```bash
# 查看Pod事件
kubectl describe pod mysql-0

# 查看PVC状态
kubectl get pvc

# 检查StorageClass
kubectl get storageclass

# 检查PV
kubectl get pv
```

### 问题二：DNS解析失败

**现象**：
```bash
nslookup mysql-0.mysql-svc
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

** server can't find mysql-0.mysql-svc: NXDOMAIN
```

**原因**：
- Headless Service未创建
- Service的selector不匹配
- CoreDNS配置问题

**解决方案**：
```bash
# 确认Service存在
kubectl get svc mysql-svc

# 确认clusterIP为None
kubectl describe svc mysql-svc

# 检查selector匹配
kubectl get pods --show-labels

# 重启CoreDNS
kubectl rollout restart deployment/coredns -n kube-system
```

### 问题三：更新卡住

**现象**：
```bash
kubectl rollout status statefulset/mysql
Waiting for statefulset rolling update to complete 1 out of 3 new pods have been updated...
```

**原因**：
- Pod无法Ready
- 健康检查失败
- 资源不足

**解决方案**：
```bash
# 查看Pod状态
kubectl get pods -l app=mysql

# 查看Pod日志
kubectl logs mysql-2

# 查看事件
kubectl describe pod mysql-2

# 手动删除失败的Pod
kubectl delete pod mysql-2

# 或者回滚
kubectl rollout undo statefulset/mysql
```

### 问题四：数据丢失

**现象**：
- Pod重建后数据丢失

**原因**：
- PVC被误删除
- 存储类配置错误
- PV回收策略不当

**解决方案**：
```bash
# 检查PVC绑定
kubectl get pvc

# 检查PV状态
kubectl get pv

# 设置PVC保护
kubectl annotate pvc data-mysql-0 pv.kubernetes.io/protection="true"

# 定期备份
kubectl exec -it mysql-0 -- mysqldump -uroot -ppassword123 --all-databases > backup.sql
```

### 问题五：扩容失败

**现象**：
```bash
kubectl scale statefulset mysql --replicas=5
statefulset.apps/mysql scaled

kubectl get pods -l app=mysql
NAME      READY   STATUS    RESTARTS   AGE
mysql-0   1/1     Running   0          10m
mysql-1   1/1     Running   0          9m
mysql-2   1/1     Running   0          8m
# mysql-3和mysql-4没有创建
```

**原因**：
- 前一个Pod未Ready
- 资源不足
- 配额限制

**解决方案**：
```bash
# 查看StatefulSet状态
kubectl describe statefulset mysql

# 查看前一个Pod状态
kubectl describe pod mysql-2

# 检查资源配额
kubectl get resourcequota -n default

# 检查节点资源
kubectl describe nodes
```

---

## 十一、性能优化建议

### 1. 存储优化

```yaml
# 使用高性能存储类
storageClassName: fast-ssd

# 使用本地存储（如果适用）
storageClassName: local-storage

# 配置IOPS限制
resources:
  requests:
    storage: 10Gi
    iops: "1000"
```

### 2. 网络优化

```yaml
# 使用主机网络（谨慎使用）
hostNetwork: true

# 配置DNS策略
dnsPolicy: ClusterFirstWithHostNet
```

### 3. 调度优化

```yaml
# 使用节点亲和性
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchExpressions:
        - key: app
          operator: In
          values:
          - mysql
      topologyKey: kubernetes.io/hostname
```

---

## 十二、总结

StatefulSet的四大特性为有状态应用在Kubernetes中的运行提供了坚实基础：

1. **稳定的网络标识**：通过固定Pod名称和Headless Service，确保应用身份稳定
2. **有序的部署和扩缩容**：通过序号控制，确保操作顺序可控
3. **有序的滚动更新**：通过Partition机制，实现金丝雀发布
4. **稳定的持久化存储**：通过volumeClaimTemplates，保证数据持久化

合理配置StatefulSet，结合生产环境最佳实践，可以在Kubernetes中稳定运行数据库、消息队列等有状态应用，实现云原生转型的关键一步。

> 本文对应的面试题：[StatefulSet的四个特性是啥？]({% post_url 2026-04-15-sre-interview-questions %})
