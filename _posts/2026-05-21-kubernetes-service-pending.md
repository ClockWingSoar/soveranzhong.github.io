---
layout: post
title: "Kubernetes Service Pending状态深度解析：从原因到解决方案"
date: 2026-05-21 10:00:00 +0800
categories: [SRE, Kubernetes, 故障排查]
tags: [Kubernetes, Service, Pending状态, 故障排查, Endpoints]
---

# Kubernetes Service Pending状态深度解析：从原因到解决方案

## 情境(Situation)

在Kubernetes集群中，Service是连接Pod和外部世界的桥梁，负责提供稳定的访问入口和负载均衡功能。然而，在实际操作中，我们经常会遇到Service处于Pending状态的情况，这会导致服务不可用，影响业务正常运行。

作为SRE工程师，我们需要深入理解Service Pending状态的原因，掌握系统性的排查方法，快速定位和解决问题，确保服务的稳定运行。

## 冲突(Conflict)

在实际应用中，SRE工程师经常面临以下挑战：

- **定位困难**：Service Pending状态可能由多种原因引起，定位问题根源需要系统分析
- **影响范围广**：Service不可用会影响整个应用的访问
- **时间压力**：生产环境中服务中断需要快速解决
- **复杂度高**：涉及Pod、网络、存储、权限等多个方面
- **预防困难**：如何提前发现和预防Service Pending状态

## 问题(Question)

如何系统性地排查和解决Kubernetes Service Pending状态，确保服务的稳定运行？

## 答案(Answer)

本文将从SRE视角出发，详细分析Kubernetes Service Pending状态的原因，提供系统性的排查方法和解决方案，以及预防措施和最佳实践，帮助SRE工程师快速定位和解决问题。核心方法论基于 [SRE面试题解析：k8s中Service中pending状态是因为啥？]({% post_url 2026-04-15-sre-interview-questions %}#74-k8s中Service中pending状态是因为啥)。

---

## 一、Service Pending状态概述

### 1.1 什么是Service Pending状态

**Service Pending状态**：
- Service创建后无法正常运行，处于待处理状态
- 通常表示Service无法找到或连接到后端Pod
- 可能由多种原因引起，需要系统性排查

### 1.2 影响

**Service Pending状态的影响**：
- 服务不可用，影响业务正常运行
- 客户端请求失败，用户体验下降
- 可能导致级联故障，影响其他依赖服务
- 增加运维成本和故障处理时间

---

## 二、常见原因分析

### 2.1 后端Pod未就绪

**原因**：后端Pod未就绪，导致Service无法找到可用的Endpoints

**表现**：
- Endpoints为空
- Pod处于NotReady状态
- 健康检查失败

**排查方法**：
1. 检查Pod状态：`kubectl get pods -l <selector>`
2. 查看Pod日志：`kubectl logs <pod-name>`
3. 检查健康检查配置：`kubectl describe pod <pod-name>`
4. 查看Pod事件：`kubectl get events --field-selector involvedObject.name=<pod-name>`

**解决方案**：
- 修复Pod启动问题
- 调整健康检查配置
- 确保Pod资源充足

### 2.2 Selector不匹配

**原因**：Service的Selector与Pod的标签不匹配

**表现**：
- Endpoints为空
- Pod状态正常
- Selector与Pod标签不一致

**排查方法**：
1. 检查Service配置：`kubectl get service <service-name> -o yaml`
2. 检查Pod标签：`kubectl get pods -l <selector> --show-labels`
3. 验证Selector匹配：`kubectl get pods -l <key>=<value>`

**解决方案**：
- 修正Service的Selector
- 修正Pod的标签
- 确保Selector与标签完全匹配

### 2.3 Pod调度问题

**原因**：Pod无法调度到节点上

**表现**：
- Pod处于Pending状态
- 调度器无法找到合适的节点
- 资源不足或节点亲和性冲突

**排查方法**：
1. 检查Pod状态：`kubectl get pods`
2. 查看Pod详情：`kubectl describe pod <pod-name>`
3. 检查节点状态：`kubectl get nodes`
4. 检查节点资源：`kubectl describe node <node-name>`

**解决方案**：
- 增加节点资源
- 调整Pod资源请求和限制
- 修正节点亲和性和污点配置

### 2.4 网络插件问题

**原因**：网络插件故障，导致Pod网络配置失败

**表现**：
- Pod处于ContainerCreating状态
- 网络配置失败
- CNI插件错误

**排查方法**：
1. 检查Pod事件：`kubectl get events --field-selector involvedObject.name=<pod-name>`
2. 检查网络插件状态：`kubectl get pods -n kube-system | grep cni`
3. 查看网络插件日志：`kubectl logs <cni-pod> -n kube-system`
4. 检查节点网络状态：`ip addr`

**解决方案**：
- 重启网络插件
- 检查CNI配置
- 确保节点网络连接正常

### 2.5 存储挂载问题

**原因**：存储卷挂载失败，导致Pod无法启动

**表现**：
- Pod处于ContainerCreating状态
- 存储挂载失败
- PVC状态异常

**排查方法**：
1. 检查Pod事件：`kubectl get events --field-selector involvedObject.name=<pod-name>`
2. 检查PVC状态：`kubectl get pvc`
3. 检查PV状态：`kubectl get pv`
4. 查看存储类配置：`kubectl get storageclass`

**解决方案**：
- 确保存储卷存在且可用
- 修正PVC配置
- 检查存储类权限

### 2.6 镜像拉取问题

**原因**：镜像拉取失败，导致容器无法创建

**表现**：
- Pod处于ImagePullBackOff状态
- 镜像拉取失败
- 镜像仓库认证失败或网络问题

**排查方法**：
1. 检查Pod事件：`kubectl get events --field-selector involvedObject.name=<pod-name>`
2. 手动拉取镜像：`docker pull <image-name>`
3. 检查镜像仓库认证：`kubectl get secret <secret-name> -o yaml`
4. 检查网络连接：`ping <registry-url>`

**解决方案**：
- 修正镜像名称和标签
- 配置正确的镜像拉取Secret
- 确保网络连接正常

### 2.7 权限问题

**原因**：权限不足，导致Service无法创建Endpoints

**表现**：
- Endpoints为空
- RBAC权限错误
- ServiceAccount权限不足

**排查方法**：
1. 检查RBAC配置：`kubectl get clusterrole,clusterrolebinding`
2. 检查ServiceAccount：`kubectl get serviceaccount <service-account>`
3. 查看授权情况：`kubectl auth can-i create endpoints --as=system:serviceaccount:<namespace>:<service-account>`

**解决方案**：
- 配置正确的RBAC权限
- 确保ServiceAccount有足够的权限
- 检查命名空间权限边界

---

## 三、系统性排查方法

### 3.1 排查流程

**系统性排查流程**：

1. **检查Service状态**：
   ```bash
   kubectl get svc <service-name>
   kubectl describe svc <service-name>
   ```

2. **检查Endpoints状态**：
   ```bash
   kubectl get endpoints <service-name>
   kubectl describe endpoints <service-name>
   ```

3. **检查后端Pod**：
   ```bash
   kubectl get pods -l <selector>
   kubectl describe pod <pod-name>
   ```

4. **检查Pod事件**：
   ```bash
   kubectl get events --sort-by='.lastTimestamp'
   kubectl get events --field-selector involvedObject.name=<pod-name>
   ```

5. **检查节点状态**：
   ```bash
   kubectl get nodes
   kubectl describe node <node-name>
   ```

6. **检查网络状态**：
   ```bash
   kubectl get pods -n kube-system | grep cni
   kubectl logs <cni-pod> -n kube-system
   ```

7. **检查存储状态**：
   ```bash
   kubectl get pvc
   kubectl get pv
   ```

8. **检查权限配置**：
   ```bash
   kubectl get serviceaccount
   kubectl get clusterrolebinding
   ```

### 3.2 Endpoints状态解读

**Endpoints状态解读**：

| 状态 | 含义 | 处理方法 |
|:------|:------|:------|
| **空Endpoints** | 无匹配Pod | 检查Selector和Pod状态 |
| **部分Endpoints** | 部分Pod可用 | 检查未就绪Pod |
| **完整Endpoints** | 所有Pod可用 | 正常状态 |

### 3.3 常见错误信息解读

**常见错误信息**：

| 错误信息 | 原因 | 解决方案 |
|:------|:------|:------|
| `No endpoints available for service` | 无可用Endpoints | 检查Pod状态和Selector |
| `Failed to pull image` | 镜像拉取失败 | 检查镜像配置和网络 |
| `Failed to attach volume` | 存储挂载失败 | 检查PVC和存储配置 |
| `No nodes available` | 无可用节点 | 检查节点状态和资源 |
| `Failed to configure network` | 网络配置失败 | 检查网络插件和配置 |

---

## 四、解决方案

### 4.1 后端Pod未就绪

**解决方案**：
1. **检查Pod日志**：
   ```bash
   kubectl logs <pod-name>
   ```

2. **检查健康检查配置**：
   ```yaml
   livenessProbe:
     httpGet:
       path: /health
       port: 8080
     initialDelaySeconds: 30
     periodSeconds: 10
   readinessProbe:
     httpGet:
       path: /ready
       port: 8080
     initialDelaySeconds: 5
     periodSeconds: 10
   ```

3. **调整资源配置**：
   ```yaml
   resources:
     requests:
       cpu: "100m"
       memory: "128Mi"
     limits:
       cpu: "200m"
       memory: "256Mi"
   ```

### 4.2 Selector不匹配

**解决方案**：
1. **修正Service Selector**：
   ```yaml
   spec:
     selector:
       app: my-app
       version: v1
   ```

2. **修正Pod标签**：
   ```yaml
   metadata:
     labels:
       app: my-app
       version: v1
   ```

3. **验证匹配**：
   ```bash
   kubectl get pods -l app=my-app,version=v1
   ```

### 4.3 Pod调度问题

**解决方案**：
1. **增加节点资源**：
   - 添加新节点
   - 调整节点资源分配

2. **调整Pod资源配置**：
   ```yaml
   resources:
     requests:
       cpu: "50m"
       memory: "64Mi"
   ```

3. **修正节点亲和性**：
   ```yaml
   affinity:
     nodeAffinity:
       requiredDuringSchedulingIgnoredDuringExecution:
         nodeSelectorTerms:
         - matchExpressions:
           - key: type
             operator: In
             values:
             - worker
   ```

### 4.4 网络插件问题

**解决方案**：
1. **重启网络插件**：
   ```bash
   kubectl rollout restart daemonset <cni-daemonset> -n kube-system
   ```

2. **检查CNI配置**：
   ```bash
   cat /etc/cni/net.d/<cni-config>.conf
   ```

3. **检查节点网络**：
   ```bash
   ip addr
   ip route
   ```

### 4.5 存储挂载问题

**解决方案**：
1. **检查PVC状态**：
   ```bash
   kubectl get pvc <pvc-name>
   ```

2. **确保PV可用**：
   ```bash
   kubectl get pv
   ```

3. **修正存储类配置**：
   ```yaml
   apiVersion: storage.k8s.io/v1
   kind: StorageClass
   metadata:
     name: standard
   provisioner: kubernetes.io/aws-ebs
   parameters:
     type: gp2
   reclaimPolicy: Retain
   allowVolumeExpansion: true
   ```

### 4.6 镜像拉取问题

**解决方案**：
1. **检查镜像名称和标签**：
   ```yaml
   image: myapp:v1.0.0
   ```

2. **配置镜像拉取Secret**：
   ```bash
   kubectl create secret docker-registry regcred \
     --docker-server=<registry-url> \
     --docker-username=<username> \
     --docker-password=<password> \
     --docker-email=<email>
   ```

3. **使用本地镜像**：
   ```yaml
   imagePullPolicy: IfNotPresent
   ```

### 4.7 权限问题

**解决方案**：
1. **配置RBAC权限**：
   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRole
   metadata:
     name: endpoints-manager
   rules:
   - apiGroups: [""]
     resources: ["endpoints"]
     verbs: ["create", "get", "list", "watch", "update"]
   ```

2. **绑定权限**：
   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRoleBinding
   metadata:
     name: endpoints-manager-binding
   subjects:
   - kind: ServiceAccount
     name: default
     namespace: default
   roleRef:
     kind: ClusterRole
     name: endpoints-manager
     apiGroup: rbac.authorization.k8s.io
   ```

---

## 五、预防措施

### 5.1 最佳实践

**预防Service Pending状态的最佳实践**：

1. **创建Service前确保后端资源就绪**：
   - 先创建Deployment或StatefulSet
   - 确保Pod正常运行后再创建Service
   - 使用就绪探针确保Pod真正可用

2. **正确配置Selector**：
   - 仔细检查标签键值对
   - 避免使用通用标签导致误匹配
   - 定期审计Service和Pod的对应关系

3. **监控与告警**：
   - 设置告警监控Service和Endpoints状态
   - 监控后端Pod的可用性
   - 记录关键事件便于排查

4. **资源管理**：
   - 合理配置Pod资源请求和限制
   - 确保节点资源充足
   - 使用资源配额管理命名空间资源

5. **网络配置**：
   - 选择稳定的网络插件
   - 确保网络插件正常运行
   - 配置适当的网络策略

6. **存储管理**：
   - 使用可靠的存储类
   - 确保存储卷可用性
   - 定期检查存储状态

7. **权限管理**：
   - 配置最小权限原则
   - 定期审计权限配置
   - 使用ServiceAccount隔离权限

### 5.2 监控与告警

**监控指标**：

- **Service指标**：
  - `kube_service_info`：Service信息
  - `kube_service_labels`：Service标签
  - `kube_service_spec_type`：Service类型

- **Endpoints指标**：
  - `kube_endpoint_address_available`：可用的Endpoint地址
  - `kube_endpoint_info`：Endpoint信息

- **Pod指标**：
  - `kube_pod_status_phase`：Pod状态
  - `kube_pod_container_status_ready`：容器就绪状态
  - `kube_pod_container_status_restarts_total`：容器重启次数

**告警规则**：

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: kubernetes-service-alerts
  namespace: monitoring
spec:
  groups:
  - name: kubernetes-service
    rules:
    - alert: ServiceEndpointsDown
      expr: kube_endpoint_address_available == 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Service endpoints down"
        description: "Service {{ $labels.service }} in namespace {{ $labels.namespace }} has no available endpoints."

    - alert: PodNotReady
      expr: kube_pod_status_phase{phase="Running"} == 0
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Pod not ready"
        description: "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} is not ready."

    - alert: ServicePending
      expr: kube_service_info{status="Pending"} == 1
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Service pending"
        description: "Service {{ $labels.service }} in namespace {{ $labels.namespace }} is in pending state."
```

### 5.3 自动化工具

**自动化排查工具**：

1. **kubectl插件**：
   - [kube-ps1](https://github.com/jonmosco/kube-ps1)：显示当前上下文和命名空间
   - [kubectx](https://github.com/ahmetb/kubectx)：快速切换上下文和命名空间
   - [kubens](https://github.com/ahmetb/kubectx)：快速切换命名空间

2. **故障排查工具**：
   - [stern](https://github.com/stern/stern)：多Pod日志查看
   - [kubectl-debug](https://github.com/aylei/kubectl-debug)：Pod调试
   - [k9s](https://github.com/derailed/k9s)：交互式Kubernetes控制台

3. **监控工具**：
   - Prometheus：监控指标
   - Grafana：可视化监控
   - Alertmanager：告警管理

---

## 六、案例分析

### 6.1 案例一：Selector不匹配

**问题**：Service创建后处于Pending状态，Endpoints为空。

**排查过程**：
1. 检查Service状态：`kubectl get svc my-service`
2. 检查Endpoints：`kubectl get endpoints my-service`（为空）
3. 检查Pod状态：`kubectl get pods -l app=my-app`（Pod正常运行）
4. 检查Selector：`kubectl get svc my-service -o yaml`（Selector为`app: myapp`）
5. 检查Pod标签：`kubectl get pods -l app=my-app --show-labels`（标签为`app: my-app`）

**原因**：Selector配置错误，`app: myapp`与Pod标签`app: my-app`不匹配。

**解决方案**：
1. 修正Service Selector：
   ```bash
   kubectl patch service my-service -p '{"spec":{"selector":{"app":"my-app"}}}'
   ```
2. 验证Endpoints：
   ```bash
   kubectl get endpoints my-service
   ```

**效果**：Service状态恢复正常，Endpoints显示可用Pod。

### 6.2 案例二：Pod调度问题

**问题**：Service创建后处于Pending状态，后端Pod也处于Pending状态。

**排查过程**：
1. 检查Service状态：`kubectl get svc my-service`
2. 检查Endpoints：`kubectl get endpoints my-service`（为空）
3. 检查Pod状态：`kubectl get pods -l app=my-app`（Pod处于Pending状态）
4. 查看Pod详情：`kubectl describe pod <pod-name>`
   - 错误信息：`FailedScheduling: 0/3 nodes are available: 3 Insufficient memory.`

**原因**：节点内存不足，导致Pod无法调度。

**解决方案**：
1. 检查节点资源：`kubectl describe node <node-name>`
2. 调整Pod资源请求：
   ```bash
   kubectl patch deployment my-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","resources":{"requests":{"memory":"128Mi"}}}]}}}'
   ```
3. 验证Pod状态：`kubectl get pods -l app=my-app`

**效果**：Pod成功调度，Service状态恢复正常。

### 6.3 案例三：网络插件问题

**问题**：Service创建后处于Pending状态，后端Pod处于ContainerCreating状态。

**排查过程**：
1. 检查Service状态：`kubectl get svc my-service`
2. 检查Endpoints：`kubectl get endpoints my-service`（为空）
3. 检查Pod状态：`kubectl get pods -l app=my-app`（Pod处于ContainerCreating状态）
4. 查看Pod事件：`kubectl get events --field-selector involvedObject.name=<pod-name>`
   - 错误信息：`Failed to configure network: cni plugin not initialized`

**原因**：网络插件未初始化，导致Pod网络配置失败。

**解决方案**：
1. 检查网络插件状态：`kubectl get pods -n kube-system | grep cni`
2. 重启网络插件：`kubectl rollout restart daemonset calico-node -n kube-system`
3. 验证Pod状态：`kubectl get pods -l app=my-app`

**效果**：Pod成功创建，Service状态恢复正常。

### 6.4 案例四：镜像拉取问题

**问题**：Service创建后处于Pending状态，后端Pod处于ImagePullBackOff状态。

**排查过程**：
1. 检查Service状态：`kubectl get svc my-service`
2. 检查Endpoints：`kubectl get endpoints my-service`（为空）
3. 检查Pod状态：`kubectl get pods -l app=my-app`（Pod处于ImagePullBackOff状态）
4. 查看Pod事件：`kubectl get events --field-selector involvedObject.name=<pod-name>`
   - 错误信息：`Failed to pull image "myapp:v1.0.0": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/library/myapp:v1.0.0": failed to resolve reference "docker.io/library/myapp:v1.0.0": pull access denied, repository does not exist or may require authorization`

**原因**：镜像不存在或认证失败。

**解决方案**：
1. 修正镜像名称：`kubectl patch deployment my-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"app","image":"myregistry/myapp:v1.0.0"}]}}}'`
2. 配置镜像拉取Secret：
   ```bash
   kubectl create secret docker-registry regcred --docker-server=myregistry --docker-username=user --docker-password=pass --docker-email=user@example.com
   kubectl patch deployment my-app -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"regcred"}]}}}'
   ```
3. 验证Pod状态：`kubectl get pods -l app=my-app`

**效果**：Pod成功拉取镜像并启动，Service状态恢复正常。

---

## 七、最佳实践总结

### 7.1 排查流程

**Service Pending状态排查流程**：

1. **检查Service状态**：确认Service是否处于Pending状态
2. **检查Endpoints**：查看是否有可用的Endpoints
3. **检查后端Pod**：确认Pod状态和健康状况
4. **检查Pod事件**：查找Pod创建和运行过程中的错误
5. **检查节点状态**：确认节点资源和健康状况
6. **检查网络状态**：确认网络插件和配置正常
7. **检查存储状态**：确认存储卷和PVC正常
8. **检查权限配置**：确认RBAC权限正确

### 7.2 预防措施

**预防Service Pending状态的措施**：

- [ ] **正确配置Selector**：确保Selector与Pod标签匹配
- [ ] **合理配置资源**：确保Pod资源请求和限制合理
- [ ] **健康检查**：配置适当的健康检查探针
- [ ] **监控告警**：设置Service和Endpoints监控告警
- [ ] **权限管理**：配置正确的RBAC权限
- [ ] **网络配置**：确保网络插件正常运行
- [ ] **存储管理**：确保存储卷可用
- [ ] **镜像管理**：确保镜像可拉取且认证正确

### 7.3 工具推荐

**推荐工具**：

- **kubectl**：Kubernetes命令行工具
- **stern**：多Pod日志查看
- **kubectl-debug**：Pod调试
- **k9s**：交互式Kubernetes控制台
- **Prometheus**：监控指标
- **Grafana**：可视化监控
- **Alertmanager**：告警管理

### 7.4 常见问题快速解决

**常见问题快速解决**：

| 问题 | 快速解决方法 |
|:------|:------|
| Selector不匹配 | 修正Service Selector或Pod标签 |
| Pod调度失败 | 调整Pod资源请求或增加节点资源 |
| 网络插件问题 | 重启网络插件或检查CNI配置 |
| 存储挂载失败 | 检查PVC和存储配置 |
| 镜像拉取失败 | 修正镜像名称或配置镜像拉取Secret |
| 权限不足 | 配置正确的RBAC权限 |

---

## 总结

Kubernetes Service Pending状态是一个常见但复杂的问题，可能由多种原因引起。通过本文的详细分析，我们可以掌握系统性的排查方法和解决方案，快速定位和解决问题，确保服务的稳定运行。

**核心要点**：

1. **常见原因**：后端Pod未就绪、Selector不匹配、Pod调度问题、网络插件问题、存储挂载问题、镜像拉取问题和权限问题
2. **排查流程**：从Service到Endpoints再到Pod，逐步定位问题根源
3. **解决方案**：针对不同原因采取相应的解决措施
4. **预防措施**：正确配置Selector、合理配置资源、设置监控告警等
5. **工具使用**：利用kubectl、stern、k9s等工具辅助排查

通过遵循这些最佳实践，我们可以减少Service Pending状态的发生，提高服务的可用性和稳定性，确保业务的正常运行。

> **延伸学习**：更多面试相关的Service Pending状态知识，请参考 [SRE面试题解析：k8s中Service中pending状态是因为啥？]({% post_url 2026-04-15-sre-interview-questions %}#74-k8s中Service中pending状态是因为啥)。

---

## 参考资料

- [Kubernetes Service文档](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Kubernetes Endpoints文档](https://kubernetes.io/docs/concepts/services-networking/service/#endpoints)
- [Kubernetes Pod文档](https://kubernetes.io/docs/concepts/workloads/pods/)
- [Kubernetes故障排查](https://kubernetes.io/docs/tasks/debug-application-cluster/)
- [Kubernetes网络插件](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/)
- [Kubernetes存储](https://kubernetes.io/docs/concepts/storage/)
- [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Kubernetes健康检查](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
- [Kubernetes资源管理](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Kubernetes调度](https://kubernetes.io/docs/concepts/scheduling-eviction/)
- [Prometheus监控](https://prometheus.io/docs/introduction/overview/)
- [Grafana监控](https://grafana.com/docs/grafana/latest/)
- [kubectl命令参考](https://kubernetes.io/docs/reference/kubectl/overview/)
- [Kubernetes最佳实践](https://kubernetes.io/docs/concepts/configuration/overview/)
- [Kubernetes网络最佳实践](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Kubernetes安全最佳实践](https://kubernetes.io/docs/concepts/security/)
- [Kubernetes性能调优](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [Kubernetes集群管理](https://kubernetes.io/docs/concepts/cluster-administration/)
- [Kubernetes事件](https://kubernetes.io/docs/concepts/overview/working-with-objects/events/)
- [Kubernetes标签和选择器](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
- [Kubernetes命名空间](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
- [Kubernetes ServiceAccount](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
- [Kubernetes ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Kubernetes Secret](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Kubernetes StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [Kubernetes Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Kubernetes DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)
- [Kubernetes Job](https://kubernetes.io/docs/concepts/workloads/controllers/job/)
- [Kubernetes CronJob](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)