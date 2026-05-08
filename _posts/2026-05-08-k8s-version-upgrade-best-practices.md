# K8S版本升级实战：从准备到验证的完整指南

## 情境与背景

Kubernetes版本升级是生产环境运维的重要任务，涉及控制平面和工作节点的协调升级。作为高级DevOps/SRE工程师，必须掌握完整的升级流程和最佳实践。本文从DevOps/SRE视角，详细讲解K8S版本升级的完整操作流程。

## 一、升级前准备

### 1.1 版本兼容性检查

**版本策略**：
```yaml
# 版本升级策略
version_policy:
  current_version: "v1.29.0"
  target_version: "v1.30.0"
  max_jump: "1 minor version"  # 最多跨1个小版本
  supported_versions:
    - "v1.28"
    - "v1.29"
    - "v1.30"
```

**兼容性检查**：
```bash
# 检查版本信息
kubectl version --short

# 检查集群状态
kubectl get nodes -o wide
kubectl get cs

# 检查API版本弃用情况
kubectl api-versions | grep deprecated

# 检查组件版本
kubeadm version
kubelet --version
```

### 1.2 备份数据

**备份脚本**：
```bash
#!/bin/bash
# K8S升级前备份脚本

BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup/k8s-upgrade-${BACKUP_DATE}"

# 创建备份目录
mkdir -p ${BACKUP_DIR}

# 备份etcd数据
ETCDCTL_API=3 etcdctl snapshot save ${BACKUP_DIR}/etcd-snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# 备份证书
cp -r /etc/kubernetes/pki ${BACKUP_DIR}/

# 备份kubeconfig文件
cp /etc/kubernetes/admin.conf ${BACKUP_DIR}/
cp /etc/kubernetes/kubelet.conf ${BACKUP_DIR}/
cp /etc/kubernetes/controller-manager.conf ${BACKUP_DIR}/
cp /etc/kubernetes/scheduler.conf ${BACKUP_DIR}/

# 备份manifest文件
cp -r /etc/kubernetes/manifests ${BACKUP_DIR}/

echo "Backup completed successfully: ${BACKUP_DIR}"
```

### 1.3 通知相关团队

**通知清单**：
```yaml
# 升级通知清单
notification:
  teams:
    - "开发团队"
    - "测试团队"
    - "运维团队"
    - "业务团队"
  
  content:
    - "升级时间：2026-05-08 22:00-23:00"
    - "升级版本：v1.29.0 -> v1.30.0"
    - "影响范围：控制平面重启，可能有短暂服务中断"
    - "回滚方案：如有问题，将回滚到v1.29.0"
```

## 二、升级控制平面

### 2.1 升级kubeadm

**升级命令**：
```bash
# 更新apt源
apt update

# 升级kubeadm到指定版本
apt install -y kubeadm=1.30.0-00

# 验证kubeadm版本
kubeadm version
```

### 2.2 升级控制平面

**执行升级**：
```bash
# 查看升级计划
kubeadm upgrade plan

# 执行升级（指定版本）
kubeadm upgrade apply v1.30.0

# 输出示例
#[upgrade/config] Making sure the configuration is correct:
#[upgrade/config] Reading configuration from the cluster...
#[upgrade/config] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
#[preflight] Running pre-flight checks.
#[upgrade] Running cluster health checks
```

### 2.3 多主节点升级

**升级流程**：
```yaml
# 多主节点升级步骤
multi_master_upgrade:
  steps:
    1. "在第一个主节点执行 kubeadm upgrade apply"
    2. "等待API Server恢复"
    3. "在其他主节点执行 kubeadm upgrade node"
    4. "升级kubelet和kubectl"
    5. "重启kubelet"
```

**命令示例**：
```bash
# 在其他主节点执行
kubeadm upgrade node
```

## 三、升级工作节点

### 3.1 升级单个节点

**升级步骤**：
```bash
# 1. 驱逐节点上的Pod
kubectl drain node-1 --ignore-daemonsets

# 2. 升级kubelet和kubectl
apt install -y kubelet=1.30.0-00 kubectl=1.30.0-00

# 3. 重启kubelet
systemctl daemon-reload
systemctl restart kubelet

# 4. 取消节点封锁
kubectl uncordon node-1
```

### 3.2 批量升级节点

**批量升级脚本**：
```bash
#!/bin/bash
# 批量升级工作节点

NODES=$(kubectl get nodes -l node-role.kubernetes.io/worker -o name)

for node in $NODES; do
    NODE_NAME=$(echo $node | sed 's/node\///')
    
    echo "Upgrading node: $NODE_NAME"
    
    # 驱逐Pod
    kubectl drain $node --ignore-daemonsets --force
    
    # 升级kubelet（通过SSH）
    ssh $NODE_NAME "apt update && apt install -y kubelet=1.30.0-00 kubectl=1.30.0-00"
    ssh $NODE_NAME "systemctl daemon-reload && systemctl restart kubelet"
    
    # 取消封锁
    kubectl uncordon $node
    
    echo "Node $NODE_NAME upgraded successfully"
    sleep 60
done
```

## 四、验证升级结果

### 4.1 验证节点状态

**验证命令**：
```bash
# 查看节点版本
kubectl get nodes -o wide

# 输出示例
# NAME       STATUS   ROLES                  AGE   VERSION
# master-1   Ready    control-plane,master   365d  v1.30.0
# worker-1   Ready    worker                 365d  v1.30.0
```

### 4.2 验证组件状态

**验证命令**：
```bash
# 查看组件状态
kubectl get cs

# 查看Pod状态
kubectl get pods -n kube-system

# 验证API Server
curl -k https://localhost:6443/healthz

# 验证etcd
crictl exec $(crictl ps --name etcd -q) etcdctl endpoint health
```

### 4.3 验证应用状态

**验证命令**：
```bash
# 查看所有Pod状态
kubectl get pods -A

# 验证服务可用性
kubectl get services

# 执行应用健康检查
kubectl exec -n default my-app -- curl -s http://localhost/health
```

## 五、升级插件

### 5.1 升级CNI插件

**升级Calico**：
```bash
# 查看当前版本
kubectl get daemonset calico-node -n kube-system -o jsonpath='{.spec.template.spec.containers[0].image}'

# 升级到新版本
kubectl apply -f https://docs.projectcalico.org/v3.26/manifests/calico.yaml
```

### 5.2 升级Ingress Controller

**升级NGINX Ingress**：
```bash
# 升级Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

# 验证Ingress状态
kubectl get pods -n ingress-nginx
```

### 5.3 升级其他插件

**升级清单**：
```yaml
# 插件升级清单
plugins:
  - name: "CoreDNS"
    upgrade_command: "kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns.yaml"
  
  - name: "Metrics Server"
    upgrade_command: "kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.6.4/components.yaml"
  
  - name: "Dashboard"
    upgrade_command: "kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml"
```

## 六、回滚方案

### 6.1 回滚准备

**回滚检查**：
```bash
# 确认备份存在
ls -la /backup/k8s-upgrade-*/

# 确认回滚所需工具
which kubeadm
which etcdctl
```

### 6.2 执行回滚

**回滚步骤**：
```bash
# 1. 停止控制平面组件
systemctl stop kube-apiserver kube-controller-manager kube-scheduler etcd

# 2. 恢复etcd数据
ETCDCTL_API=3 etcdctl snapshot restore /backup/k8s-upgrade-YYYYMMDD_HHMMSS/etcd-snapshot.db \
  --data-dir=/var/lib/etcd

# 3. 恢复证书
cp -r /backup/k8s-upgrade-YYYYMMDD_HHMMSS/pki/* /etc/kubernetes/pki/

# 4. 恢复kubeconfig
cp /backup/k8s-upgrade-YYYYMMDD_HHMMSS/*.conf /etc/kubernetes/

# 5. 降级kubeadm和kubelet
apt install -y kubeadm=1.29.0-00 kubelet=1.29.0-00 kubectl=1.29.0-00

# 6. 重启组件
systemctl start etcd kube-apiserver kube-controller-manager kube-scheduler kubelet

# 7. 验证回滚
kubectl version --short
```

## 七、最佳实践

### 7.1 升级策略

**策略建议**：
```yaml
# 升级策略建议
upgrade_strategy:
  frequency: "quarterly"  # 每季度升级一次
  maintenance_window: "22:00-23:00"  # 维护窗口
  rollout_strategy: "canary"  # 金丝雀发布
  max_concurrent_nodes: 1  # 同时升级节点数
```

### 7.2 监控与告警

**监控配置**：
```yaml
# 升级监控
upgrade_monitoring:
  alerts:
    - name: "NodeNotReadyAfterUpgrade"
      condition: "node_status == 'NotReady' for 5m"
      severity: "critical"
    
    - name: "PodNotReadyAfterUpgrade"
      condition: "pod_status == 'NotReady' for 10m"
      severity: "warning"
    
    - name: "APIServerUnavailable"
      condition: "apiserver_health == 'unhealthy'"
      severity: "critical"
```

## 八、面试1分钟精简版（直接背）

**完整版**：

我们定期进行K8S版本升级。升级流程主要包括：首先备份etcd数据和证书，然后检查目标版本与当前版本的兼容性。升级控制平面时，先升级kubeadm工具，再执行kubeadm upgrade apply命令。工作节点升级时，逐个节点进行，先升级kubelet包，再重启kubelet服务。升级完成后验证集群状态，最后升级CNI、Ingress等插件。整个过程会在维护窗口期进行，并准备回滚方案。

**30秒超短版**：

备份检查后先升级控制平面，再逐个升级工作节点，最后验证并升级插件，全程在维护窗口进行。

## 九、总结

### 9.1 核心要点

1. **准备阶段**：备份数据、检查兼容性、通知团队
2. **控制平面**：升级kubeadm→执行upgrade apply
3. **工作节点**：驱逐Pod→升级kubelet→重启→取消封锁
4. **验证阶段**：检查节点、组件、应用状态
5. **插件升级**：升级CNI、Ingress等
6. **回滚方案**：准备回滚流程，确保可恢复

### 9.2 升级原则

| 原则 | 说明 |
|:----:|------|
| **先备份** | 升级前必须备份 |
| **小步快跑** | 最多跨1个小版本 |
| **逐个升级** | 工作节点逐个升级 |
| **验证优先** | 每步都验证状态 |
| **准备回滚** | 确保回滚方案可用 |

### 9.3 记忆口诀

```
备份检查做准备，控制平面先升级，
工作节点逐个来，验证插件不能少。
```

> **参考链接**：[SRE运维面试题全解析：从理论到实践（第二部分）]({% post_url 2026-04-15-sre-interview-questions-part2 %})