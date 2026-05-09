# Kubernetes kubectl命令详解与生产环境最佳实践

## 情境与背景

kubectl是Kubernetes的命令行工具，是管理K8s集群的核心接口。掌握kubectl命令对于高效管理集群、排查问题、部署应用至关重要。作为高级DevOps/SRE工程师，需要深入理解kubectl的工作原理和最佳实践。

## 一、资源管理命令

### 1.1 资源创建与应用

**创建资源**：

```bash
# 使用create命令
kubectl create deployment nginx --image=nginx
kubectl create service clusterip nginx --tcp=80:80

# 使用apply命令（推荐）
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# 从目录批量应用
kubectl apply -f ./k8s/

# 使用JSON创建
kubectl create -f - <<EOF
{
  "apiVersion": "v1",
  "kind": "Pod",
  "metadata": {
    "name": "nginx"
  },
  "spec": {
    "containers": [{
      "name": "nginx",
      "image": "nginx"
    }]
  }
}
EOF
```

### 1.2 资源查看

**查看资源**：

```bash
# 查看所有资源
kubectl get all

# 查看特定资源
kubectl get pods
kubectl get deployments
kubectl get services
kubectl get nodes

# 查看详细信息
kubectl describe pod nginx
kubectl describe deployment nginx

# 自定义输出格式
kubectl get pods -o wide
kubectl get pods -o json
kubectl get pods -o yaml

# 选择器过滤
kubectl get pods -l app=nginx
kubectl get pods -l app=nginx,tier=frontend

# 查看资源列表（支持简写）
kubectl get po  # pods
kubectl get deploy  # deployments
kubectl get svc  # services
kubectl get ns  # namespaces
```

### 1.3 资源删除

**删除资源**：

```bash
# 删除指定资源
kubectl delete pod nginx
kubectl delete deployment nginx

# 通过文件删除
kubectl delete -f deployment.yaml

# 删除所有特定类型资源
kubectl delete pods --all

# 删除命名空间（谨慎使用）
kubectl delete namespace my-namespace

# 强制删除（用于卡住的资源）
kubectl delete pod nginx --force --grace-period=0
```

## 二、集群管理命令

### 2.1 集群信息

**查看集群状态**：

```bash
# 查看集群信息
kubectl cluster-info

# 查看节点信息
kubectl get nodes
kubectl describe node node-1

# 查看API版本
kubectl api-versions

# 查看服务器版本
kubectl version
```

### 2.2 节点管理

**节点操作**：

```bash
# 标记节点不可调度
kubectl cordon node-1

# 标记节点可调度
kubectl uncordon node-1

# 排空节点（驱逐pod）
kubectl drain node-1
kubectl drain node-1 --ignore-daemonsets

# 标记节点为污点
kubectl taint nodes node-1 key=value:NoSchedule
kubectl taint nodes node-1 key=value:NoExecute

# 移除污点
kubectl taint nodes node-1 key-
```

## 三、故障排查命令

### 3.1 日志查看

**查看日志**：

```bash
# 查看pod日志
kubectl logs nginx

# 实时查看日志
kubectl logs -f nginx

# 查看最近的日志
kubectl logs --tail=100 nginx

# 查看特定容器日志
kubectl logs nginx -c container-name

# 查看之前容器的日志（适用于CrashLoopBackOff）
kubectl logs nginx --previous

# 查看deployment的日志
kubectl logs deployment/nginx
```

### 3.2 执行命令

**在容器中执行命令**：

```bash
# 进入容器
kubectl exec -it nginx -- bash
kubectl exec -it nginx -- sh

# 执行单个命令
kubectl exec nginx -- ls -la
kubectl exec nginx -- cat /etc/nginx/nginx.conf

# 指定容器执行
kubectl exec nginx -c container-name -- bash

# 以root用户执行
kubectl exec -it nginx -- sudo -i
```

### 3.3 事件查看

**查看事件**：

```bash
# 查看所有事件
kubectl get events

# 按时间排序
kubectl get events --sort-by='.metadata.creationTimestamp'

# 查看命名空间事件
kubectl get events -n kube-system

# 查看特定资源事件
kubectl describe pod nginx
```

## 四、配置管理命令

### 4.1 kubeconfig管理

**配置管理**：

```bash
# 查看当前配置
kubectl config view

# 查看当前上下文
kubectl config current-context

# 切换上下文
kubectl config use-context my-cluster

# 添加集群配置
kubectl config set-cluster my-cluster --server=https://api.example.com

# 添加用户
kubectl config set-credentials my-user --token=my-token

# 设置上下文
kubectl config set-context my-cluster --cluster=my-cluster --user=my-user

# 删除配置
kubectl config delete-context my-cluster
```

### 4.2 Secret与ConfigMap

**配置资源管理**：

```bash
# 创建ConfigMap
kubectl create configmap my-config --from-literal=key1=value1 --from-literal=key2=value2
kubectl create configmap my-config --from-file=config.yaml
kubectl create configmap my-config --from-env-file=env.txt

# 创建Secret
kubectl create secret generic my-secret --from-literal=password=secret
kubectl create secret generic my-secret --from-file=ssh-key=~/.ssh/id_rsa

# 查看Secret内容（base64解码）
kubectl get secret my-secret -o jsonpath='{.data.password}' | base64 -d
```

## 五、工作负载管理命令

### 5.1 扩缩容

**扩缩容命令**：

```bash
# 手动扩缩容
kubectl scale deployment nginx --replicas=3

# 自动扩缩容
kubectl autoscale deployment nginx --min=2 --max=10 --cpu-percent=80

# 查看HPA
kubectl get hpa
```

### 5.2 滚动更新

**滚动更新命令**：

```bash
# 更新镜像
kubectl set image deployment/nginx nginx=nginx:1.24.0

# 查看更新状态
kubectl rollout status deployment/nginx

# 查看更新历史
kubectl rollout history deployment/nginx

# 回滚到上一版本
kubectl rollout undo deployment/nginx

# 回滚到特定版本
kubectl rollout undo deployment/nginx --to-revision=2

# 暂停/恢复更新
kubectl rollout pause deployment/nginx
kubectl rollout resume deployment/nginx
```

## 六、高级命令

### 6.1 标签与注解

**标签管理**：

```bash
# 添加标签
kubectl label pods nginx app=frontend
kubectl label nodes node-1 zone=us-west

# 更新标签
kubectl label pods nginx app=backend --overwrite

# 删除标签
kubectl label pods nginx app-

# 添加注解
kubectl annotate pods nginx description="web server"
```

### 6.2 端口转发与代理

**网络访问**：

```bash
# 端口转发
kubectl port-forward pod/nginx 8080:80
kubectl port-forward deployment/nginx 8080:80

# 访问service
kubectl port-forward service/nginx 8080:80

# 启动代理
kubectl proxy

# 访问API服务器
curl http://localhost:8001/api/v1/namespaces/default/pods
```

### 6.3 资源编辑

**在线编辑资源**：

```bash
# 编辑资源
kubectl edit deployment nginx

# 编辑特定字段
kubectl patch deployment nginx -p '{"spec":{"replicas":5}}'

# JSON patch
kubectl patch pod nginx --type='json' -p='[{"op": "replace", "path": "/spec/containers/0/image", "value":"nginx:1.24.0"}]'
```

## 七、生产环境最佳实践

### 7.1 安全最佳实践

**安全建议**：

```yaml
security_best_practices:
  - "使用RBAC限制用户权限"
  - "避免使用cluster-admin权限"
  - "定期轮换kubeconfig证书"
  - "使用ServiceAccount而非用户账户"
  - "启用审计日志"
```

**权限管理**：

```bash
# 创建ServiceAccount
kubectl create serviceaccount my-sa

# 创建角色
kubectl create role my-role --verb=get,list,watch --resource=pods

# 绑定角色
kubectl create rolebinding my-rolebinding --role=my-role --serviceaccount=default:my-sa
```

### 7.2 性能优化

**性能建议**：

```yaml
performance_best_practices:
  - "使用--request-timeout设置超时"
  - "使用--cache-dir缓存"
  - "限制输出字段"
  - "使用JSONPath过滤"
```

**高效查询**：

```bash
# 设置超时
kubectl get pods --request-timeout=10s

# 过滤输出
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'

# 使用自定义列
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase
```

### 7.3 配置管理最佳实践

**配置建议**：

```yaml
config_best_practices:
  - "使用环境变量管理配置"
  - "使用ConfigMap存储配置"
  - "使用Secret存储敏感信息"
  - "配置文件版本控制"
  - "使用helm管理复杂应用"
```

## 八、实战案例

### 8.1 案例一：部署应用

**步骤**：

```bash
# 1. 创建命名空间
kubectl create namespace my-app

# 2. 创建ConfigMap
kubectl create configmap app-config --from-literal=DB_HOST=db --from-literal=DB_PORT=5432

# 3. 创建Secret
kubectl create secret generic app-secret --from-literal=DB_PASSWORD=secret

# 4. 部署应用
kubectl apply -f deployment.yaml -n my-app

# 5. 创建Service
kubectl apply -f service.yaml -n my-app

# 6. 验证
kubectl get pods -n my-app
kubectl get service -n my-app
```

### 8.2 案例二：节点维护

**步骤**：

```bash
# 1. 标记节点不可调度
kubectl cordon node-1

# 2. 排空节点
kubectl drain node-1 --ignore-daemonsets

# 3. 执行维护操作（如升级内核）

# 4. 标记节点可调度
kubectl uncordon node-1

# 5. 验证
kubectl get nodes
```

### 8.3 案例三：故障排查

**步骤**：

```bash
# 1. 查看pod状态
kubectl get pods

# 2. 查看pod详情
kubectl describe pod nginx

# 3. 查看日志
kubectl logs nginx
kubectl logs nginx --previous

# 4. 进入容器调试
kubectl exec -it nginx -- bash

# 5. 查看事件
kubectl get events

# 6. 查看资源使用
kubectl top pods
```

## 九、面试1分钟精简版（直接背）

**完整版**：

常用kubectl命令包括：资源管理类（kubectl create/apply创建资源、kubectl delete删除资源、kubectl get查看资源、kubectl describe查看详情）；集群管理类（kubectl cluster-info查看集群信息、kubectl get nodes查看节点）；故障排查类（kubectl logs查看日志、kubectl exec进入容器、kubectl describe查看资源详情、kubectl get events查看事件）；配置管理类（kubectl config管理配置、kubectl create secret/configmap）；工作负载类（kubectl scale扩缩容、kubectl rollout管理滚动更新）。这些是日常运维最常用的命令。

**30秒超短版**：

kubectl apply创建资源，get查看，describe详情，logs日志，exec进入容器，scale扩缩容，rollout滚动更新。

## 十、总结

### 10.1 命令速查表

| 类别 | 命令 | 作用 |
|:----:|------|------|
| **资源管理** | `kubectl create/apply/delete/get/describe` | 资源生命周期管理 |
| **集群管理** | `kubectl cluster-info/node/cordon/uncordon/drain` | 集群和节点管理 |
| **故障排查** | `kubectl logs/exec/describe/events` | 问题排查 |
| **配置管理** | `kubectl config/secret/configmap` | 配置管理 |
| **工作负载** | `kubectl scale/rollout/autoscale` | 扩缩容和更新 |

### 10.2 最佳实践清单

```yaml
best_practices:
  - "使用apply而非create（支持幂等性）"
  - "使用namespace隔离资源"
  - "定期备份kubeconfig"
  - "使用RBAC限制权限"
  - "避免直接修改资源，使用配置文件"
```

### 10.3 记忆口诀

```
kubectl命令要熟练，资源管理apply创，
get看列表describe详，logs查看日志忙，
exec进入容器内，scale扩缩容不累，
rollout滚动更新棒，cordon/drain节点维护强。
```

> **参考链接**：[SRE运维面试题全解析：从理论到实践（第二部分）]({% post_url 2026-04-15-sre-interview-questions-part2 %})