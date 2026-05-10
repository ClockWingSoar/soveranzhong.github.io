# SRE运维面试题全解析：从理论到实践（第三部分）

## 情境与背景

作为一名SRE工程师，面试是职业发展的重要环节。面试官通常会从系统知识、工具使用、问题解决能力等多个维度考察候选人。本文基于真实面试场景，整理了高频面试题，并提供结构化的解析，帮助你快速掌握核心知识点，从容应对面试挑战。

## 核心面试题解析

### 216. k8s网络flannel的通信过程是啥？vxlan的通信过程？

**Why - 为什么这个问题重要？**

Flannel是Kubernetes最常用的CNI插件之一，负责为Pod提供跨节点的网络通信能力。理解Flannel的通信过程和VXLAN技术原理，是设计和维护K8s网络架构的基础，也是高级DevOps/SRE工程师必备的核心知识。**VXLAN是目前生产环境最常用的Flannel后端，其通过UDP封装实现三层网络上的二层扩展。**

**How - Flannel与VXLAN通信流程**

```mermaid
flowchart TB
    A["Pod A 发送数据"] --> B["cni0 网桥"]
    B --> C["路由匹配"]
    C --> D["flannel.1 VTEP"]
    D --> E["VXLAN 封装"]
    E --> F["UDP/8472 隧道"]
    F --> G["目标节点 VTEP"]
    G --> H["解封装"]
    H --> I["cni0 网桥"]
    I --> J["Pod B 接收"]

    style A fill:#e3f2fd
    style D fill:#c8e6c9
    style F fill:#fff3e0
    style J fill:#c8e6c9
```

**What - 通信过程详解**

| 阶段 | 源节点操作 | 目标节点操作 |
|:----:|-----------|-------------|
| **1. 子网分配** | flanneld向Etcd申请PodCIDR，假设为10.244.0.0/24 | 目标节点获得10.244.1.0/24 |
| **2. Pod发送** | Pod A(10.244.0.10)发送数据到Pod B(10.244.1.20) | - |
| **3. 网桥接收** | 数据包通过veth Pair进入cni0网桥 | - |
| **4. 路由匹配** | 内核路由表匹配到flannel.1接口 | - |
| **5. VTEP封装** | 源VTEP(flannel.1)封装原始帧为VXLAN数据包 | - |
| **6. 隧道传输** | 通过UDP 8472端口发送到目标VTEP IP | - |
| **7. VTEP接收** | - | 目标VTEP接收VXLAN数据包 |
| **8. 解封装** | - | 移除VXLAN头部，还原原始帧 |
| **9. 网桥转发** | - | 数据包通过cni0转发到Pod B |
| **10. Pod接收** | - | Pod B接收完整数据包 |

**VXLAN封装结构**

| 层次 | 封装内容 | 说明 |
|:----:|---------|------|
| **原始数据** | L2 Frame (Ethernet + IP + TCP) | 原始Pod数据包 |
| **VXLAN头** | VNI(24bit) + Flags + VNITag | 虚拟网络标识 |
| **UDP头** | 源端口随机 + 目的端口8472 | VXLAN封装协议 |
| **IP头** | 源VTEP IP + 目标VTEP IP | 隧道端点IP |
| **物理网络** | Ethernet Frame | 底层物理网络封装 |

**记忆口诀**：Pod发包走cni0，路由匹配flannel.1，VTEP封装VXLAN，UDP8472穿隧道，目标解封装，cni0送到Pod。

**面试标准答法（1分钟版）**：Flannel的通信过程：Pod发送数据包时，通过veth Pair到cni0网桥，内核根据路由表将数据包交给flannel.1接口（VTEP设备）；VTEP根据目标IP查找ARP表获取目标VTEP MAC地址，然后将原始L2帧封装为VXLAN数据包；VXLAN通过UDP 8472端口在物理网络上建立隧道传输；目标节点VTEP收到后解封装，将原始帧交给cni0网桥，网桥通过veth Pair转发到目标Pod。VXLAN本质上是在三层网络上构建二层overlay网络，通过24bit VNI实现1600万虚拟网络隔离。

> **延伸阅读**：想了解更多Flannel与VXLAN生产环境最佳实践？请参考 [K8S网络Flannel与VXLAN详解：从原理到生产环境实践]({% post_url 2026-05-10-k8s-flannel-vxlan-best-practices %})。

