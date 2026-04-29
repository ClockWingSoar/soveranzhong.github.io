---
layout: post
title: "K8s故障案例分析与实战指南"
subtitle: "深入剖析常见故障场景，掌握系统化排查方法"
date: 2026-06-25 10:00:00
author: "OpsOps"
header-img: "img/post-bg-troubleshooting.jpg"
catalog: true
tags:
  - Kubernetes
  - 故障排查
  - 案例分析
  - 实战经验
---

## 一、引言

在Kubernetes生产环境中，故障是不可避免的。如何快速定位和解决问题是SRE工程师的核心能力。本文将通过多个真实故障案例，深入剖析问题的根因，分享系统化的排查方法，并总结生产环境中的最佳实践。

---

## 二、SCQA分析框架

### 情境（Situation）
- K8s集群运行着大量微服务
- 故障随时可能发生，影响业务连续性
- 需要快速定位和解决问题

### 冲突（Complication）
- 故障现象复杂，原因多样
- 日志分散，难以快速定位
- 缺乏系统化的排查方法

### 问题（Question）
- 常见的K8s故障有哪些？
- 如何快速定位故障根因？
- 有哪些有效的排查工具和方法？
- 如何预防故障发生？

### 答案（Answer）
- 常见故障包括Pod Pending、频繁重启、Service不可用等
- 建立系统化的排查流程：观察→收集→定位→验证→修复→总结
- 使用kubectl命令、日志、监控等工具
- 通过监控告警、健康检查、配置规范等预防故障

---

## 三、典型故障案例详解

### 案例一：Pod一直处于Pending状态

**现象描述**：
```bash
kubectl get pod my-pod
# NAME      READY   STATUS    RESTARTS   AGE
# my-pod    0/1     Pending   0          5m
```

**根因分析**：

| 可能原因 | 检查方法 | 解决方案 |
|:------|:------|:------|
| **资源不足** | `kubectl top nodes` | 增加节点或降低资源请求 |
| **节点选择器不匹配** | `kubectl describe pod` | 检查nodeSelector/nodeAffinity |
| **污点容忍问题** | `kubectl describe node` | 添加Toleration或移除Taint |
| **镜像拉取失败** | `kubectl describe pod` | 检查镜像地址和凭证 |
| **Volume绑定失败** | `kubectl get pvc` | 确保PV可用 |

**排查步骤**：
```bash
# 1. 查看Pod事件
kubectl describe pod my-pod

# 2. 检查节点资源
kubectl top nodes

# 3. 检查污点配置
kubectl describe node <node-name> | grep Taints

# 4. 检查PVC状态
kubectl get pvc
```

**预防措施**：
- 配置ResourceQuota和LimitRange
- 合理设置Pod资源请求
- 使用节点亲和性分散Pod分布

---

### 案例二：Pod频繁重启

**现象描述**：
```bash
kubectl get pod my-pod
# NAME      READY   STATUS    RESTARTS   AGE
# my-pod    1/1     Running   5          10m
```

**根因分析**：

| 可能原因 | 检查方法 | 解决方案 |
|:------|:------|:------|
| **Liveness Probe过严** | `kubectl describe pod` | 调整探针参数 |
| **应用崩溃** | `kubectl logs --previous` | 修复代码bug |
| **OOM killed** | `dmesg | grep oom` | 增加内存限制 |
| **配置错误** | `kubectl exec -it <pod> -- env` | 检查环境变量 |

**排查步骤**：
```bash
# 1. 查看重启原因
kubectl describe pod my-pod | grep -A 10 "Last State"

# 2. 查看上一次崩溃日志
kubectl logs my-pod --previous

# 3. 检查资源使用
kubectl top pod my-pod

# 4. 检查Liveness Probe
kubectl get pod my-pod -o yaml | grep -A 10 livenessProbe
```

**预防措施**：
- 合理配置Liveness/Readiness Probe
- 设置适当的资源限制
- 实施健康检查监控

---

### 案例三：Service无法访问后端Pod

**现象描述**：
```bash
kubectl get endpoints my-service
# NAME          ENDPOINTS   AGE
# my-service    <none>      5m
```

**根因分析**：

| 可能原因 | 检查方法 | 解决方案 |
|:------|:------|:------|
| **标签不匹配** | `kubectl get service -o yaml` | 修正Pod标签或Service selector |
| **Pod未就绪** | `kubectl get pod` | 检查Readiness Probe |
| **NetworkPolicy阻止** | `kubectl get networkpolicy` | 调整网络策略 |
| **端口配置错误** | `kubectl describe service` | 检查port/targetPort映射 |

**排查步骤**：
```bash
# 1. 检查Service selector
kubectl get service my-service -o jsonpath='{.spec.selector}'

# 2. 检查Pod标签
kubectl get pod --show-labels

# 3. 检查Pod就绪状态
kubectl get pod -o wide

# 4. 检查NetworkPolicy
kubectl get networkpolicy
```

**预防措施**：
- 建立标签命名规范
- 配置Readiness Probe
- 谨慎配置NetworkPolicy

---

### 案例四：节点故障导致Pod不可用

**现象描述**：
```bash
kubectl get node node-01
# NAME      STATUS     ROLES    AGE    VERSION
# node-01   NotReady   worker   10d    v1.28.0

kubectl get pod -o wide | grep node-01
# NAME      READY   STATUS        NODE      AGE
# my-pod    1/1     Unknown      node-01   5m
```

**根因分析**：

| 可能原因 | 检查方法 | 解决方案 |
|:------|:------|:------|
| **节点宕机** | `ping <node-ip>` | 重启节点或更换硬件 |
| **kubelet故障** | `systemctl status kubelet` | 重启kubelet |
| **网络分区** | `telnet <master-ip> 6443` | 检查网络连接 |
| **资源耗尽** | `free -h && top` | 释放资源或扩容 |

**排查步骤**：
```bash
# 1. 检查节点状态
kubectl describe node node-01

# 2. 远程登录节点
ssh node-01
systemctl status kubelet

# 3. 检查系统资源
free -h
df -h

# 4. 检查网络连接
telnet <master-ip> 6443
```

**应急响应**：
```bash
# 1. 驱逐节点上的Pod
kubectl drain node-01 --ignore-daemonsets --delete-local-data

# 2. 标记节点为不可调度
kubectl cordon node-01

# 3. 修复节点后恢复
kubectl uncordon node-01
```

**预防措施**：
- 配置Pod反亲和性
- 实施节点健康监控
- 准备备用节点

---

### 案例五：Ingress无法访问

**现象描述**：
```bash
curl http://example.com
# curl: (7) Failed to connect to example.com port 80: Connection refused
```

**根因分析**：

| 可能原因 | 检查方法 | 解决方案 |
|:------|:------|:------|
| **Controller未部署** | `kubectl get pods -n ingress-nginx` | 部署Ingress Controller |
| **规则配置错误** | `kubectl describe ingress` | 修正后端Service配置 |
| **DNS解析失败** | `nslookup example.com` | 检查DNS配置 |
| **TLS证书问题** | `openssl s_client -connect example.com:443` | 更新证书 |

**排查步骤**：
```bash
# 1. 检查Ingress Controller状态
kubectl get pods -n ingress-nginx

# 2. 检查Ingress配置
kubectl describe ingress my-ingress

# 3. 查看Controller日志
kubectl logs -n ingress-nginx <controller-pod>

# 4. 测试直连
curl http://<node-ip>:<port> -H "Host: example.com"
```

**预防措施**：
- 部署高可用Ingress Controller
- 使用证书管理器自动更新证书
- 配置健康检查

---

### 案例六：数据卷挂载失败

**现象描述**：
```bash
kubectl describe pod my-pod | grep -A 5 "MountVolume"
# Warning  FailedMount  5m    kubelet  MountVolume.SetUp failed for volume "data" : hostPath type check failed: /data is not a directory
```

**根因分析**：

| 可能原因 | 检查方法 | 解决方案 |
|:------|:------|:------|
| **hostPath不存在** | `ssh node-01 ls -la /data` | 创建目录 |
| **PVC绑定失败** | `kubectl get pvc` | 确保PV可用 |
| **权限不足** | `ssh node-01 ls -la /data` | 设置正确权限 |
| **StorageClass错误** | `kubectl get storageclass` | 检查provisioner |

**排查步骤**：
```bash
# 1. 检查PVC状态
kubectl get pvc my-pvc

# 2. 检查PV状态
kubectl get pv

# 3. 检查hostPath目录
ssh node-01
ls -la /data

# 4. 创建目录并设置权限
mkdir -p /data
chown 1000:1000 /data
```

**预防措施**：
- 使用PersistentVolumeClaim而非hostPath
- 配置StorageClass自动创建PV
- 设置适当的目录权限

---

### 案例七：DNS解析失败

**现象描述**：
```bash
kubectl exec -it my-pod -- nslookup my-service
# nslookup: can't resolve 'my-service'
```

**根因分析**：

| 可能原因 | 检查方法 | 解决方案 |
|:------|:------|:------|
| **CoreDNS故障** | `kubectl get pods -n kube-system` | 重启CoreDNS |
| **配置错误** | `kubectl exec -it <pod> -- cat /etc/resolv.conf` | 检查DNS配置 |
| **NetworkPolicy阻止** | `kubectl get networkpolicy` | 允许DNS访问 |
| **命名空间问题** | 使用完整域名 | 使用`<service>.<namespace>.svc.cluster.local` |

**排查步骤**：
```bash
# 1. 检查CoreDNS状态
kubectl get pods -n kube-system -l k8s-app=kube-dns

# 2. 查看CoreDNS日志
kubectl logs -n kube-system <coredns-pod>

# 3. 检查Pod的DNS配置
kubectl exec -it my-pod -- cat /etc/resolv.conf

# 4. 使用完整域名测试
kubectl exec -it my-pod -- nslookup my-service.default.svc.cluster.local
```

**预防措施**：
- 监控CoreDNS健康状态
- 配置允许DNS访问的NetworkPolicy
- 使用完整域名进行跨命名空间访问

---

## 四、故障排查方法论

### 4.1 排查流程

```
┌─────────────────────────────────────────────────────────────────┐
│                    系统化故障排查流程                          │
├─────────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    │
│  │  1.观察现象  │ →→→ │  2.收集信息  │ →→→ │  3.定位根因  │    │
│  │              │    │              │    │              │    │
│  │ kubectl get │    │ kubectl logs │    │   逐层排查   │    │
│  │    describe │    │    events    │    │              │    │
│  └──────────────┘    └──────────────┘    └──────┬───────┘    │
│                                                  │            │
│                                                  ▼            │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    │
│  │  6.验证效果  │ ←←─ │  5.实施修复  │ ←←─ │  4.验证假设  │    │
│  │              │    │              │    │              │    │
│  │   确认解决   │    │   应用方案   │    │   小范围测试  │    │
│  └──────────────┘    └──────────────┘    └──────────────┘    │
│                                                  │            │
│                                                  ▼            │
│                                      ┌──────────────┐        │
│                                      │  7.记录总结  │        │
│                                      │   文档化    │        │
│                                      └──────────────┘        │
│                                                               │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 分层排查法

| 层次 | 检查内容 | 工具命令 |
|:------|:------|:------|
| **应用层** | Pod状态、日志、健康检查 | `kubectl get pod`, `kubectl logs` |
| **服务层** | Service配置、Endpoint | `kubectl get service`, `kubectl get endpoints` |
| **网络层** | Ingress、NetworkPolicy、DNS | `kubectl get ingress`, `kubectl get networkpolicy` |
| **节点层** | 节点状态、资源使用 | `kubectl get node`, `kubectl top nodes` |
| **控制层** | kube-apiserver、etcd | `kubectl get pods -n kube-system` |

### 4.3 常用排查工具

| 工具 | 用途 | 示例命令 |
|:------|:------|:------|
| **kubectl describe** | 查看资源详细信息 | `kubectl describe pod <pod-name>` |
| **kubectl logs** | 查看Pod日志 | `kubectl logs <pod-name> --previous` |
| **kubectl get events** | 查看事件 | `kubectl get events --sort-by='.metadata.creationTimestamp'` |
| **kubectl top** | 查看资源使用 | `kubectl top pods` |
| **kubectl exec** | 进入Pod执行命令 | `kubectl exec -it <pod-name> -- bash` |
| **dmesg** | 查看系统日志 | `dmesg | tail -20` |

---

## 五、生产环境最佳实践

### 5.1 监控告警体系

**关键指标监控**：
```yaml
groups:
- name: k8s-troubleshooting
  rules:
  - alert: PodPendingTooLong
    expr: kube_pod_status_phase{phase="Pending"} == 1
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "Pod持续Pending超过10分钟"

  - alert: PodRestartingFrequent
    expr: increase(kube_pod_container_status_restarts_total[5m]) > 3
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Pod频繁重启"

  - alert: NodeNotReady
    expr: kube_node_status_condition{condition="Ready",status="false"} == 1
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "节点状态为NotReady"

  - alert: ServiceNoEndpoints
    expr: kube_endpoint_address_available == 0
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Service没有Endpoint"
```

### 5.2 健康检查配置

**完整探针配置**：
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
    startupProbe:
      httpGet:
        path: /healthz
        port: 8080
      failureThreshold: 30
      periodSeconds: 10
```

### 5.3 Pod分布策略

**反亲和性配置**：
```yaml
spec:
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels:
            app: web
        topologyKey: kubernetes.io/hostname
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        preference:
          matchExpressions:
          - key: node-type
            operator: In
            values: ["high-performance"]
```

**拓扑分布约束**：
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

### 5.4 配置规范

**标签规范**：
```yaml
metadata:
  labels:
    app: my-app
    tier: backend
    version: v1.2.0
    environment: production
    component: api
```

**资源限制**：
```yaml
spec:
  containers:
  - name: app
    image: myapp:latest
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "200m"
        memory: "256Mi"
```

### 5.5 应急响应流程

**故障响应SOP**：
```
1. 接收告警 → 确认故障范围
2. 初步诊断 → 定位故障类型
3. 执行修复 → 应用解决方案
4. 验证恢复 → 确认服务正常
5. 复盘总结 → 记录经验教训
```

**备份策略**：
```bash
# 定期备份配置
0 2 * * * kubectl get all -o yaml > /backup/k8s-backup-$(date +%Y%m%d).yaml

# 备份etcd
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-snapshot-$(date +%Y%m%d).db
```

---

## 六、故障排查清单

### 快速检查清单

- ✅ Pod状态是否正常？
- ✅ Pod是否有就绪？
- ✅ Service是否有Endpoint？
- ✅ 标签是否匹配？
- ✅ 资源是否充足？
- ✅ 网络策略是否允许访问？
- ✅ DNS解析是否正常？
- ✅ 节点状态是否正常？

### 日志检查清单

- ✅ Pod日志是否有错误？
- ✅ kubelet日志是否有异常？
- ✅ CoreDNS日志是否正常？
- ✅ Ingress Controller日志是否有错误？
- ✅ 事件日志是否有警告？

---

## 七、总结

### 核心要点

1. **系统化排查**：建立观察→收集→定位→验证→修复→总结的流程
2. **分层排查**：从应用层到控制层逐层检查
3. **工具使用**：熟练使用kubectl命令和日志工具
4. **预防为主**：通过监控、健康检查、配置规范预防故障

### 经验总结

| 故障类型 | 快速定位方法 | 预防措施 |
|:------|:------|:------|
| **Pod Pending** | `kubectl describe pod` | 合理配置资源请求 |
| **Pod重启** | `kubectl logs --previous` | 配置合理的健康检查 |
| **Service不可用** | `kubectl get endpoints` | 确保标签匹配 |
| **节点故障** | `kubectl describe node` | 配置Pod反亲和性 |
| **Ingress故障** | `kubectl logs ingress-controller` | 监控Controller状态 |
| **DNS故障** | `kubectl get pods -n kube-system` | 监控CoreDNS |

> 本文对应的面试题：[请列举几个典型的K8s故障案例及解决方案？]({% post_url 2026-04-15-sre-interview-questions %})

---

## 附录：常用命令速查

```bash
# 查看Pod状态
kubectl get pod -o wide

# 查看Pod详细信息
kubectl describe pod <pod-name>

# 查看Pod日志
kubectl logs <pod-name>
kubectl logs <pod-name> --previous

# 查看事件
kubectl get events --sort-by='.metadata.creationTimestamp'

# 查看节点状态
kubectl get node
kubectl describe node <node-name>

# 查看Service和Endpoint
kubectl get service
kubectl get endpoints

# 查看Ingress
kubectl get ingress
kubectl describe ingress <ingress-name>

# 查看资源使用
kubectl top pods
kubectl top nodes

# 进入Pod
kubectl exec -it <pod-name> -- bash

# 驱逐节点Pod
kubectl drain <node-name> --ignore-daemonsets

# 标记节点不可调度
kubectl cordon <node-name>

# 恢复节点调度
kubectl uncordon <node-name>
```
