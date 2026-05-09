# Kubernetes集群搭建全流程：从基础设施到生产环境实践指南

## 情境与背景

Kubernetes集群搭建是DevOps/SRE工程师的核心技能之一。本指南详细讲解从基础设施准备到生产环境部署的完整流程，包括系统配置、容器运行时安装、K8s组件部署、网络配置及生产环境最佳实践。

## 一、基础设施准备

### 1.1 服务器规划

**节点规划**：

```yaml
infrastructure:
  master_nodes:
    count: 3
    role: "控制平面"
    min_spec:
      cpu: "4核"
      memory: "8GB"
      storage: "100GB SSD"
      
  worker_nodes:
    count: 3
    role: "工作节点"
    min_spec:
      cpu: "8核"
      memory: "16GB"
      storage: "200GB SSD"
      
  requirements:
    - "相同操作系统版本"
    - "网络互通"
    - "时间同步"
    - "SSH访问"
```

**网络规划**：

```yaml
network_planning:
  pod_network:
    cidr: "10.244.0.0/16"
    description: "Pod通信网络"
    
  service_network:
    cidr: "10.96.0.0/12"
    description: "Service ClusterIP网络"
    
  node_network:
    description: "节点通信网络"
    requirements:
      - "所有节点互通"
      - "开放必要端口"
```

### 1.2 端口要求

**端口配置**：

```yaml
required_ports:
  master:
    - port: 6443
      protocol: TCP
      description: "API Server"
    - port: 2379-2380
      protocol: TCP
      description: "etcd"
    - port: 10250
      protocol: TCP
      description: "Kubelet"
    - port: 10251
      protocol: TCP
      description: "Scheduler"
    - port: 10252
      protocol: TCP
      description: "Controller Manager"
      
  worker:
    - port: 10250
      protocol: TCP
      description: "Kubelet"
    - port: 30000-32767
      protocol: TCP
      description: "NodePort"
```

## 二、系统环境配置

### 2.1 主机名配置

**主机名设置**：

```markdown
## 系统环境配置

### 主机名配置

```bash
# 设置主机名
hostnamectl set-hostname master-01
hostnamectl set-hostname master-02
hostnamectl set-hostname master-03
hostnamectl set-hostname worker-01
hostnamectl set-hostname worker-02
hostnamectl set-hostname worker-03

# 更新/etc/hosts
cat >> /etc/hosts <<EOF
192.168.1.10 master-01
192.168.1.11 master-02
192.168.1.12 master-03
192.168.1.20 worker-01
192.168.1.21 worker-02
192.168.1.22 worker-03
EOF
```

### 2.2 系统参数配置

**系统优化**：

```bash
# 关闭防火墙
systemctl stop firewalld
systemctl disable firewalld

# 关闭SELinux
setenforce 0
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config

# 关闭Swap
swapoff -a
sed -i '/swap/s/^/#/' /etc/fstab

# 配置时间同步
timedatectl set-timezone Asia/Shanghai
yum install -y chrony
systemctl start chronyd
systemctl enable chronyd
```

### 2.3 内核参数配置

**内核优化**：

```bash
# 加载内核模块
cat >> /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# 配置sysctl参数
cat >> /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system
```

## 三、容器运行时安装

### 3.1 Containerd安装

**安装步骤**：

```yaml
containerd_install:
  prerequisites:
    - "yum install -y yum-utils device-mapper-persistent-data lvm2"
    
  docker_repo:
    command: "yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo"
    
  install:
    command: "yum install -y containerd.io"
    
  configure:
    - "mkdir -p /etc/containerd"
    - "containerd config default > /etc/containerd/config.toml"
    
  cgroup_driver:
    description: "设置systemd cgroup driver"
    config_path: "/etc/containerd/config.toml"
    change: "SystemdCgroup = true"
    
  start:
    - "systemctl start containerd"
    - "systemctl enable containerd"
```

### 3.2 Docker安装（可选）

**安装步骤**：

```bash
# 安装Docker
yum install -y docker-ce docker-ce-cli containerd.io

# 配置Docker
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

# 启动Docker
systemctl start docker
systemctl enable docker
```

## 四、K8s组件安装

### 4.1 添加K8s源

**源配置**：

```bash
# 添加K8s YUM源
cat > /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF
```

### 4.2 安装组件

**安装命令**：

```bash
# 安装K8s组件
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

# 启动kubelet
systemctl enable --now kubelet
```

## 五、Master节点初始化

### 5.1 单Master初始化

**初始化命令**：

```markdown
## Master节点初始化

### 单Master初始化

```bash
# 初始化Master节点
kubeadm init \
  --apiserver-advertise-address=192.168.1.10 \
  --pod-network-cidr=10.244.0.0/16 \
  --service-cidr=10.96.0.0/12 \
  --kubernetes-version=v1.28.0
```

**配置kubectl**：

```bash
# 配置kubectl
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# 验证
kubectl get nodes
```

### 5.2 高可用Master配置

**HA配置**：

```yaml
ha_master:
  etcd_cluster:
    - "master-01"
    - "master-02"
    - "master-03"
    
  load_balancer:
    type: "VIP/Keepalived"
    vip: "192.168.1.100"
    
  init_command: |
    kubeadm init \
      --control-plane-endpoint="192.168.1.100:6443" \
      --upload-certs \
      --pod-network-cidr=10.244.0.0/16 \
      --service-cidr=10.96.0.0/12
      
  join_command: |
    kubeadm join 192.168.1.100:6443 \
      --token <token> \
      --discovery-token-ca-cert-hash <hash> \
      --control-plane \
      --certificate-key <key>
```

## 六、Worker节点加入

### 6.1 获取加入命令

**获取命令**：

```bash
# 获取join命令（在Master节点执行）
kubeadm token create --print-join-command

# 输出示例
kubeadm join 192.168.1.10:6443 --token abcdef.0123456789abcdef \
    --discovery-token-ca-cert-hash sha256:0123456789abcdef0123456789abcdef
```

### 6.2 Worker加入集群

**执行命令**：

```bash
# 在Worker节点执行join命令
kubeadm join 192.168.1.10:6443 --token abcdef.0123456789abcdef \
    --discovery-token-ca-cert-hash sha256:0123456789abcdef0123456789abcdef
```

## 七、网络插件部署

### 7.1 Calico部署

**部署命令**：

```markdown
## 网络插件部署

### Calico部署

```bash
# 部署Calico
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# 验证Pod状态
kubectl get pods -n kube-system -w
```

### 7.2 Flannel部署

**部署命令**：

```bash
# 部署Flannel
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# 验证
kubectl get pods -n kube-flannel
```

### 7.3 Cilium部署

**部署命令**：

```bash
# 安装Cilium CLI
curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-amd64.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin
rm cilium-linux-amd64.tar.gz{,.sha256sum}

# 部署Cilium
cilium install
```

## 八、集群验证

### 8.1 节点状态检查

**验证命令**：

```yaml
cluster_verification:
  check_nodes:
    command: "kubectl get nodes"
    expected: "所有节点状态为Ready"
    
  check_pods:
    command: "kubectl get pods -n kube-system"
    expected: "所有Pod状态为Running"
    
  check_api:
    command: "kubectl cluster-info"
    expected: "API Server正常运行"
    
  test_deployment:
    command: "kubectl create deployment nginx --image=nginx"
    verify: "kubectl get pods"
```

### 8.2 功能验证

**测试Pod**：

```bash
# 创建测试Pod
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort

# 验证服务
kubectl get svc nginx
curl http://<node-ip>:<nodeport>
```

## 九、生产环境最佳实践

### 9.1 安全配置

**安全措施**：

```markdown
## 生产环境最佳实践

### 安全配置

```yaml
security_best_practices:
  rbac:
    description: "配置RBAC权限"
    principle: "最小权限原则"
    
  secrets:
    description: "使用Secrets管理敏感数据"
    types:
      - "Opaque"
      - "TLS"
      - "docker-registry"
      
  network_policy:
    description: "配置网络策略"
    purpose: "Pod间通信控制"
    
  audit_log:
    description: "启用审计日志"
    configuration: "/etc/kubernetes/manifests/kube-apiserver.yaml"
```

### 9.2 监控与日志

**监控配置**：

```yaml
monitoring:
  metrics_server:
    deployment: "kubectl apply -f metrics-server.yaml"
    
  prometheus:
    deployment: "helm install prometheus prometheus-community/prometheus"
    
  grafana:
    deployment: "helm install grafana grafana/grafana"
    
  logging:
    solution: "EFK Stack"
    components:
      - "Elasticsearch"
      - "Fluentd"
      - "Kibana"
```

### 9.3 备份与恢复

**备份策略**：

```yaml
backup_strategy:
  etcd_backup:
    command: "ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-snapshot.db"
    
  schedule:
    frequency: "每日"
    retention: "保留7天"
    
  restore:
    command: "ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-snapshot.db"
```

## 十、面试1分钟精简版（直接背）

**完整版**：

K8s集群搭建全流程：1. 基础设施准备：3台Master+多台Worker，配置网络和端口；2. 系统配置：设置主机名、关闭防火墙/SELinux/Swap、时间同步、内核参数；3. 安装容器运行时：Containerd或Docker；4. 安装K8s组件：kubeadm、kubelet、kubectl；5. Master初始化：kubeadm init指定Pod网络CIDR；6. Worker加入：kubeadm join；7. 部署网络插件：Calico/Flannel/Cilium；8. 验证集群：kubectl get nodes/pods。生产建议：配置高可用Master、启用RBAC、部署监控、定期备份etcd。

**30秒超短版**：

K8s搭建七步走：基础准备、系统配置、容器运行时、K8s组件、Master初始化、Worker加入、网络插件。

## 十一、总结

### 11.1 搭建步骤总结

```yaml
setup_summary:
  steps:
    1: "基础设施准备"
    2: "系统环境配置"
    3: "容器运行时安装"
    4: "K8s组件安装"
    5: "Master初始化"
    6: "Worker加入"
    7: "网络插件部署"
    8: "集群验证"
    
  key_points:
    - "关闭Swap和SELinux"
    - "配置时间同步"
    - "选择合适网络插件"
    - "验证所有组件状态"
```

### 11.2 最佳实践清单

```yaml
best_practices_checklist:
  security:
    - "配置RBAC"
    - "使用Secrets"
    - "启用网络策略"
    
  high_availability:
    - "多Master节点"
    - "负载均衡"
    - "etcd集群"
    
  monitoring:
    - "部署Metrics Server"
    - "配置Prometheus/Grafana"
    - "设置日志收集"
    
  backup:
    - "定期备份etcd"
    - "测试恢复流程"
    - "备份配置文件"
```

### 11.3 记忆口诀

```
K8s搭建分七步，基础准备是第一步，
系统配置要做好，容器运行时安装好，
kubeadm初始化master，worker加入集群中，
网络插件最后装，集群验证不能少，
安全监控要跟上，生产环境才可靠。
```

> **参考链接**：[SRE运维面试题全解析：从理论到实践（第二部分）]({% post_url 2026-04-15-sre-interview-questions-part2 %})