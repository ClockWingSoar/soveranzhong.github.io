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

### 217. logstash和filebeat之间有啥区别？

**Why - 为什么这个问题重要？**

在ELK日志系统中，Filebeat和Logstash是最常用的两个组件。理解它们的定位、功能差异和使用场景，是构建高效日志收集架构的基础。**Filebeat负责轻量级采集，Logstash负责复杂处理，两者是互补关系而非替代关系。**

**How - 组件定位与架构**

```mermaid
flowchart LR
    A["日志源"] --> B["Filebeat"]
    B --> C["Kafka/Redis"]
    C --> D["Logstash"]
    D --> E["Elasticsearch"]
    E --> F["Kibana"]

    style B fill:#c8e6c9
    style D fill:#fff3e0
```

**What - 核心区别对比**

| 维度 | Filebeat | Logstash |
|:----:|----------|----------|
| **定位** | 轻量级日志采集器 | 重量级日志处理管道 |
| **资源消耗** | 低（Go语言，单进程~40MB） | 高（JVM，1GB+内存） |
| **功能** | 采集、初步过滤、多行合并 | 采集、解析、转换、丰富、输出 |
| **性能** | 高（单实例可处理MB/s日志） | 中等（需要更多资源） |
| **插件生态** | Input/Module有限 | Input/Filter/Output丰富 |
| **部署位置** | 靠近日志源（每台主机） | 集中部署（独立服务器） |
| **配置复杂度** | 简单 | 复杂 |
| **可靠性** | At-least-once | At-least-once |
| **适用场景** | 大规模日志采集 | 复杂日志处理 |

**Filebeat优势场景**

| 场景 | 推荐原因 |
|------|----------|
| **大规模采集** | 轻量低资源占用，每台主机部署 |
| **简单日志转发** | 仅需基本过滤和多行合并 |
| **K8s环境** | 有官方K8s Module自动发现Pod日志 |
| **资源敏感环境** | 嵌入式应用日志收集 |

**Logstash优势场景**

| 场景 | 推荐原因 |
|------|----------|
| **复杂解析** | JSON/XML/CSV等多格式解析 |
| **数据富化** | 结合GeoIP、数据库丰富日志 |
| **多输出** | 同时写入ES、HDFS、Kafka等 |
| **高级转换** | 正则替换、条件分支、聚合统计 |

**记忆口诀**：采集用Filebeat，处理用Logstash，量大轻量选Filebeat，复杂解析用Logstash。

**面试标准答法（1分钟版）**：Filebeat和Logstash是ELK栈的两个核心组件，定位不同：Filebeat是轻量级日志采集器，用Go编写，资源消耗低（单进程约40MB），负责从日志源采集数据、做初步过滤和多行合并，适合大规模部署在每台主机上；Logstash是重量级日志处理管道，用JVM运行，功能强大，支持丰富的Input/Filter/Output插件，能做复杂的数据解析、转换和富化，适合集中部署做复杂处理。生产环境的最佳实践是：Filebeat部署在日志源采集日志，通过Kafka解耦后，Logstash做集中处理和解析，最后写入Elasticsearch。

> **延伸阅读**：想了解更多Filebeat与Logstash生产环境最佳实践？请参考 [Filebeat与Logstash对比分析：ELK日志收集架构最佳实践]({% post_url 2026-05-10-filebeat-logstash-comparison-best-practices %})。

### 218. 有一个节点notready，原因是啥？

**Why - 为什么这个问题重要？**

K8s节点NotReady是生产环境最常见的故障之一，直接影响Pod调度和业务可用性。**节点NotReady意味着kubelet无法向API Server报告节点状态，导致该节点上的Pod无法被调度或面临被驱逐的风险。**快速定位NotReady原因是SRE的核心技能。

**How - 排查思路与流程**

```mermaid
flowchart TB
    A["节点NotReady"] --> B["检查kubelet状态"]
    B --> C{"kubelet运行正常?"}
    C -->|否| D["启动/重启kubelet"]
    C -->|是| E["检查网络连通性"]
    E --> F{"API Server可达?"}
    F -->|否| G["检查网络插件"]
    F -->|是| H["检查资源状态"]
    G --> I["重启网络插件"]
    H --> J{"资源充足?"}
    J -->|否| K["扩容或驱逐Pod"]
    J -->|是| L["检查系统服务"]

    style A fill:#ffcdd2
    style D fill:#c8e6c9
    style I fill:#c8e6c9
    style K fill:#c8e6c9
```

**What - 常见原因与解决方案**

| 原因分类 | 具体原因 | 排查命令 | 解决方案 |
|---------|---------|----------|----------|
| **kubelet停止** | kubelet进程异常退出 | `systemctl status kubelet` | 重启kubelet |
| **网络不通** | 节点到API Server网络中断 | `ping <api-server-ip>` | 检查网络/防火墙 |
| **网络插件异常** | Flannel/Calico等CNI故障 | `systemctl status flanneld` | 重启网络插件 |
| **资源不足** | 内存/磁盘/文件描述符耗尽 | `df -h` / `free -m` | 扩容或驱逐Pod |
| **证书过期** | kubelet证书过期 | `openssl x509 -in /var/lib/kubelet/pki/cert.crt -dates` | 更新证书 |
| **swap启用** | K8s要求关闭swap | `swapon -s` | 关闭swap |
| **内核问题** | 内核参数异常 | `dmesg | tail` | 重启节点 |
| **时间不同步** | NTP时间偏差过大 | `timedatectl status` | 同步NTP |

**排查步骤详解**

| 步骤 | 操作 | 命令 |
|:----:|------|------|
| **1. 查看节点状态** | 确认NotReady状态 | `kubectl get nodes` |
| **2. 查看节点详情** | 查看NotReady原因 | `kubectl describe node <node-name>` |
| **3. 检查kubelet日志** | 定位具体错误 | `journalctl -u kubelet -n 100` |
| **4. 检查网络插件** | 确认CNI状态 | `kubectl get pods -n kube-system` |
| **5. 检查资源使用** | 磁盘/内存/文件描述符 | `df -h && free -m && lsof | wc -l` |

**记忆口诀**：节点NotReady先查kubelet，网络插件要确认，资源不足看磁盘，内核问题查dmesg，证书时间也要问。

**面试标准答法（1分钟版）**：节点NotReady的排查思路：先kubectl describe node看Events信息，同时检查kubelet进程状态和日志；常见原因包括：kubelet停止（systemctl restart kubelet）、网络插件异常（重启flanneld或calico-node）、节点资源耗尽（磁盘满或内存不足）、证书过期、swap未关闭等。生产环境应配置监控告警，在节点NotReady时及时发现，同时准备节点自动恢复脚本。

> **延伸阅读**：想了解更多K8s节点NotReady故障排查？请参考 [K8s节点NotReady故障排查与恢复：生产环境最佳实践]({% post_url 2026-05-11-k8s-node-notready-troubleshooting-best-practices %})。

### 219. k8s中资源不足了，硬驱逐的资源条件是什么？

**Why - 为什么这个问题重要？**

K8s Pod驱逐是保障节点稳定性的最后一道防线，理解硬驱逐（Hard Eviction）和软驱逐（Soft Eviction）的阈值条件，是生产环境避免意外Pod丢失的关键。**硬驱逐阈值触发后会立即杀死Pod，不给宽限期；软驱逐有gracePeriod可以优雅处理。**

**How - 驱逐机制架构**

```mermaid
flowchart TB
    A["节点资源紧张"] --> B["kubelet监控"]
    B --> C{"是否达到阈值?"}
    C -->|硬驱逐阈值| D["立即杀死Pod"]
    C -->|软驱逐阈值| E["进入gracePeriod"]
    E --> F{"超时仍未缓解?"}
    F -->|是| G["杀死Pod"]
    F -->|否| H["Pod存活"]

    style D fill:#ffcdd2
    style G fill:#ffcdd2
    style H fill:#c8e6c9
```

**What - 驱逐阈值详解**

| 驱逐信号 | 软驱逐默认值 | 硬驱逐默认值 | 说明 |
|---------|-------------|-------------|------|
| **memory.available** | 500Mi | 256Mi | 节点可用内存 |
| **nodefs.available** | 10% | 5% | nodefs文件系统可用空间 |
| **nodefs.inodesfree** | 5% | 4% | inode可用数量 |
| **imagefs.available** | 15% | 10% | imagefs文件系统可用空间 |
| **imagefs.inodesfree** | 5% | 4% | imagefs inode可用数量 |
| **pid.available** | 4% | 4% | 可用进程ID数量 |

**imagefs与nodefs区分**

| 文件系统 | 触发条件 | kubelet标志 | 用途 |
|---------|---------|-------------|------|
| **nodefs** | `nodefs.available` | `--root-dir` | kubelet工作目录、Pod日志等 |
| **imagefs** | `imagefs.available` | `--storage-driver-root` | 容器镜像存储 |

**生产环境推荐配置**

| 配置项 | 推荐值 | 说明 |
|:------:|:------:|------|
| **硬驱逐内存阈值** | 100Mi-200Mi | 预留足够缓冲 |
| **硬驱逐磁盘阈值** | 5% | 避免磁盘耗尽 |
| **软驱逐内存阈值** | 500Mi-1Gi | 给Pod迁移时间 |
| **gracePeriod** | 30-60秒 | 优雅终止时间 |

**记忆口诀**：硬驱逐立即杀，软驱逐有宽限，memory.available256Mi，nodefs5%inode4%，imagefs10%inode5%。

**面试标准答法（1分钟版）**：K8s硬驱逐的资源条件由kubelet的--eviction-hard参数控制，常见信号包括memory.available（硬驱逐256Mi，软驱逐500Mi）、nodefs.available（硬驱逐5%，软驱逐10%）、imagefs.available（硬驱逐10%，软驱逐15%）以及inode相关信号。硬驱逐触发后立即杀死Pod，软驱逐有gracePeriod（如30秒）作为宽限期。生产环境推荐配置合理的硬驱逐阈值预留缓冲，同时开启软驱逐让Pod有优雅迁移的时间。

> **延伸阅读**：想了解更多K8s Pod驱逐机制？请参考 [K8s Pod硬驱逐与软驱逐详解：资源阈值配置与生产环境最佳实践]({% post_url 2026-05-11-k8s-pod-eviction-threshold-best-practices %})。

