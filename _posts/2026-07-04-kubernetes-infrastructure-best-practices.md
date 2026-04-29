---
layout: post
title: "Kubernetes生产环境基础设施最佳实践"
subtitle: "从物理机到云原生的完整基础设施架构"
date: 2026-07-04 10:00:00
author: "OpsOps"
header-img: "img/post-bg-k8s-infra.jpg"
catalog: true
tags:
  - Kubernetes
  - 基础设施
  - 物理机
  - 虚拟机
  - CPU架构
---

## 一、引言

Kubernetes作为云原生领域的核心编排平台，其基础设施选型直接影响系统性能和稳定性。本文将深入探讨Kubernetes生产环境的基础设施架构，包括部署方式选择、CPU架构选型、操作系统配置等关键问题。

---

## 二、SCQA分析框架

### 情境（Situation）
- Kubernetes已成为容器编排的标准
- 企业面临基础设施选型的挑战
- 需要平衡性能、成本和灵活性

### 冲突（Complication）
- 物理机性能好但成本高
- 虚拟机灵活但有性能损耗
- 不同架构各有优缺点

### 问题（Question）
- 如何选择Kubernetes部署方式？
- 物理机和虚拟机各有什么优势？
- 如何选择CPU架构？
- 操作系统如何配置？

### 答案（Answer）
- 根据业务需求选择部署方式
- 物理机适合核心业务，虚拟机适合非核心
- x86-64为主流，ARM64适合边缘场景
- 选择容器优化的Linux发行版

---

## 三、部署方式选择

### 3.1 物理机部署

**优势**：
```
┌─────────────────────────────────────────────────────────────────┐
│                    物理机部署优势                            │
├─────────────────────────────────────────────────────────────────┤
│                                                               │
│  • 性能优异：无虚拟化开销，资源利用率高                      │
│  • 稳定性强：减少虚拟化层故障点                              │
│  • 适合大规模：支撑高密度容器部署                            │
│  • 成本效益：长期运行成本更低                                │
│                                                               │
└─────────────────────────────────────────────────────────────────┘
```

**适用场景**：
- 核心业务系统
- 高性能计算场景
- 大规模容器集群

**配置示例**：
```bash
# 物理机推荐配置
CPU: Intel Xeon Gold 6330 (32核/64线程)
内存: 512GB DDR4 ECC
存储: 4TB NVMe SSD x 4 (RAID 5)
网络: 10Gbps x 2 (Bonding)
```

### 3.2 虚拟机部署

**优势**：
```
┌─────────────────────────────────────────────────────────────────┐
│                    虚拟机部署优势                            │
├─────────────────────────────────────────────────────────────────┤
│                                                               │
│  • 灵活性高：资源可动态调整                                  │
│  • 隔离性好：租户间互相隔离                                  │
│  • 灾备便捷：快照和迁移容易                                  │
│  • 维护简单：批量管理和更新                                  │
│                                                               │
└─────────────────────────────────────────────────────────────────┘
```

**适用场景**：
- 开发测试环境
- 非核心业务系统
- 多租户场景

**配置示例**：
```yaml
# VMware虚拟机配置
apiVersion: v1
kind: Node
metadata:
  name: node-vm-01
  labels:
    hardware-type: vmware
spec:
  allocatable:
    cpu: "16"
    memory: "32Gi"
    pods: "110"
```

### 3.3 混合部署策略

**架构设计**：
```
┌─────────────────────────────────────────────────────────────────┐
│                    混合部署架构                            │
├─────────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   Kubernetes集群                        │   │
│  ├─────────────────────────────────────────────────────────┤   │
│  │                                                         │   │
│  │  ┌──────────────┐    ┌──────────────┐                  │   │
│  │  │   物理机节点  │    │   虚拟机节点  │                  │   │
│  │  │ (核心业务)   │    │ (非核心业务) │                  │   │
│  │  │              │    │              │                  │   │
│  │  │ • 高优先级   │    │ • 低优先级   │                  │   │
│  │  │ • 高性能要求 │    │ • 弹性伸缩   │                  │   │
│  │  │ • 稳定性要求 │    │ • 成本优化   │                  │   │
│  │  └──────────────┘    └──────────────┘                  │   │
│  │                                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────────┘
```

**调度策略**：
```yaml
# Node Affinity配置
apiVersion: v1
kind: Pod
metadata:
  name: critical-app
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: hardware-type
            operator: In
            values:
            - baremetal
```

---

## 四、CPU架构选型

### 4.1 x86-64架构

**特点**：
```
┌─────────────────────────────────────────────────────────────────┐
│                    x86-64架构特点                           │
├─────────────────────────────────────────────────────────────────┤
│                                                               │
│  • 市场主流：占据服务器市场主导地位                          │
│  • 软件生态：支持所有主流软件和工具                          │
│  • 性能强大：单核性能高，适合通用场景                        │
│  • 兼容性好：支持所有容器镜像                                │
│                                                               │
└─────────────────────────────────────────────────────────────────┘
```

**适用场景**：
- 通用服务器场景
- 需要运行复杂软件的场景
- 需要广泛兼容性的场景

### 4.2 ARM64架构

**特点**：
```
┌─────────────────────────────────────────────────────────────────┐
│                    ARM64架构特点                            │
├─────────────────────────────────────────────────────────────────┤
│                                                               │
│  • 能耗低：比x86-64节能30-50%                              │
│  • 成本低：硬件成本更低                                      │
│  • 密度高：相同功耗下可部署更多节点                          │
│  • 边缘友好：适合边缘计算场景                                │
│                                                               │
└─────────────────────────────────────────────────────────────────┘
```

**适用场景**：
- 边缘计算场景
- 云原生轻量服务
- 大规模集群场景

### 4.3 架构对比

| 维度 | x86-64 | ARM64 |
|:------|:------|:------|
| **性能** | 单核性能高 | 多核并行好 |
| **能耗** | 较高 | 较低（节能30-50%） |
| **成本** | 较高 | 较低 |
| **软件生态** | 成熟完善 | 快速发展中 |
| **兼容性** | 所有容器镜像 | 部分镜像需要构建 |

---

## 五、操作系统配置

### 5.1 主流Linux发行版

**Ubuntu Server**：
```bash
# Ubuntu Server 22.04 LTS配置
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装依赖
sudo apt install -y containerd apt-transport-https ca-certificates curl

# 配置containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# 启用systemd cgroup驱动
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# 重启containerd
sudo systemctl restart containerd
```

**CentOS/RHEL**：
```bash
# CentOS 8配置
# 更新系统
sudo dnf update -y

# 安装依赖
sudo dnf install -y containerd.io

# 配置containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# 启用systemd cgroup驱动
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# 重启containerd
sudo systemctl restart containerd
```

### 5.2 容器优化OS

**Flatcar Container Linux**：
```bash
# Flatcar特点
# - 专为容器设计
# - 自动更新机制
# - 只读根文件系统
# - 轻量级（约300MB）

# 配置示例
# cloud-config.yaml
# 用户数据配置
```

**Ubuntu Core**：
```bash
# Ubuntu Core特点
# - 安全第一的设计
# - 事务性更新
# - 只读文件系统
# - 适合物联网和边缘场景
```

### 5.3 操作系统选择建议

| 场景 | 推荐OS | 理由 |
|:------|:------|:------|
| 通用生产环境 | Ubuntu Server | 社区活跃，更新快 |
| 企业级稳定环境 | CentOS/RHEL | 稳定，企业支持 |
| 容器专用环境 | Flatcar | 专为容器优化 |
| 边缘计算 | Ubuntu Core/Flatcar | 轻量，安全 |

---

## 六、基础设施配置最佳实践

### 6.1 节点标签和污点

**标签配置**：
```yaml
# 节点标签示例
apiVersion: v1
kind: Node
metadata:
  name: node-prod-01
  labels:
    node-role.kubernetes.io/control-plane: ""
    hardware-type: baremetal
    cpu-architecture: x86_64
    os: ubuntu
    environment: production
```

**污点配置**：
```yaml
# 污点配置示例
apiVersion: v1
kind: Node
metadata:
  name: node-critical-01
spec:
  taints:
  - key: dedicated
    value: critical
    effect: NoSchedule
```

**容忍度配置**：
```yaml
# Pod容忍度配置
apiVersion: v1
kind: Pod
metadata:
  name: critical-app
spec:
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "critical"
    effect: "NoSchedule"
```

### 6.2 资源预留

**Kubelet配置**：
```yaml
# kubelet配置示例
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
evictionHard:
  memory.available: "100Mi"
  nodefs.available: "10%"
  nodefs.inodesFree: "5%"
imageGCHighThresholdPercent: 85
imageGCLowThresholdPercent: 80
```

**预留资源**：
```bash
# 为kubelet预留资源
# 在kubelet启动参数中添加
--kube-reserved=cpu=100m,memory=512Mi
--system-reserved=cpu=200m,memory=1Gi
```

### 6.3 网络配置

**CNI插件选择**：
```yaml
# Calico配置示例
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    ipPools:
    - blockSize: 26
      cidr: 192.168.0.0/16
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
```

**网络优化**：
```bash
# 禁用IPv6（如果不需要）
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p

# 调整TCP参数
echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_fin_timeout = 30" >> /etc/sysctl.conf
sysctl -p
```

---

## 七、监控和维护

### 7.1 节点监控

**Prometheus配置**：
```yaml
# 节点监控配置
scrape_configs:
  - job_name: 'kubernetes-nodes'
    kubernetes_sd_configs:
      - role: node
    relabel_configs:
      - source_labels: [__address__]
        regex: '(.*):10250'
        replacement: '${1}:9100'
        target_label: __address__
```

**监控指标**：
```yaml
# 节点告警规则
groups:
- name: node-alerts
  rules:
  - alert: NodeHighCPUUsage
    expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[1m])) * 100) > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "节点CPU使用率过高"
  
  - alert: NodeHighMemoryUsage
    expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 90
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "节点内存使用率过高"
```

### 7.2 定期维护

**维护流程**：
```
┌─────────────────────────────────────────────────────────────────┐
│                    节点维护流程                              │
├─────────────────────────────────────────────────────────────────┤
│                                                               │
│  1. 标记节点为不可调度                                        │
│     kubectl cordon <node-name>                               │
│                    │                                         │
│                    ▼                                         │
│  2. 驱逐节点上的Pod                                          │
│     kubectl drain <node-name> --ignore-daemonsets            │
│                    │                                         │
│                    ▼                                         │
│  3. 执行维护操作（更新、修复等）                              │
│                    │                                         │
│                    ▼                                         │
│  4. 标记节点为可调度                                          │
│     kubectl uncordon <node-name>                             │
│                    │                                         │
│                    ▼                                         │
│  5. 验证节点状态                                              │
│     kubectl get nodes <node-name>                            │
│                                                               │
└─────────────────────────────────────────────────────────────────┘
```

---

## 八、总结

### 核心要点

1. **部署方式**：物理机适合核心业务，虚拟机适合非核心，混合部署兼顾两者
2. **CPU架构**：x86-64为主流，ARM64适合边缘和节能场景
3. **操作系统**：选择容器优化的Linux发行版
4. **配置优化**：合理配置节点标签、污点、资源预留

### 最佳实践清单

- ✅ 根据业务需求选择部署方式
- ✅ 使用Node Affinity和Taints隔离工作负载
- ✅ 预留系统资源给kubelet和系统进程
- ✅ 配置适当的网络优化参数
- ✅ 建立完善的节点监控体系

> 本文对应的面试题：[两套平台都部署在K8S上吗？K8S用的是物理机还是虚拟机？什么CPU架构？操作系统是什么？]({% post_url 2026-04-15-sre-interview-questions %})

---

## 附录：推荐工具

**基础设施管理**：
- Terraform：基础设施即代码
- Ansible：配置管理
- Packer：镜像构建

**监控工具**：
- Prometheus：监控和告警
- Grafana：可视化
- Node Exporter：节点指标

**网络工具**：
- Calico：CNI插件
- Cilium：eBPF网络
- MetalLB：裸金属负载均衡
