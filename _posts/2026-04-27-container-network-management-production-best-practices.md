---
layout: post
title: "容器网络管理生产环境最佳实践：从IP查看到网络架构设计"
date: 2026-04-27 22:30:00
categories: [SRE, Docker, 容器]
tags: [Docker, 容器网络, IP地址, 网络模式, 生产环境]
---

# 容器网络管理生产环境最佳实践：从IP查看到网络架构设计

## 情境(Situation)

在容器化环境中，网络配置是确保应用正常运行的关键因素。无论是微服务架构还是传统应用容器化，容器之间的网络通信、容器与外部服务的连接都依赖于正确的网络配置。作为SRE工程师，掌握容器网络管理技能，不仅能快速排查网络问题，还能设计出更加可靠、安全的容器网络架构。

## 冲突(Conflict)

在容器网络管理中，SRE工程师经常面临以下挑战：

- **IP地址管理**：容器IP地址的动态分配和追踪
- **网络模式选择**：不同网络模式的适用场景和配置
- **跨主机通信**：多节点容器集群的网络互通
- **网络性能**：容器网络的吞吐量和延迟优化
- **网络安全**：容器网络的隔离和访问控制

## 问题(Question)

如何有效地管理容器网络，包括IP地址查看、网络模式配置、跨主机通信和网络性能优化，以确保容器化应用的稳定运行？

## 答案(Answer)

本文将从SRE视角出发，详细介绍容器网络管理的核心技术和最佳实践，涵盖IP地址查看、网络模式配置、网络架构设计等内容。核心方法论基于 [SRE面试题解析：怎么查看一个容器的ip地址]({% post_url 2026-04-15-sre-interview-questions %}#36-怎么查看一个容器的ip地址)。

---

## 一、容器IP地址查看

### 1.1 常用方法

**docker inspect 命令**：

```bash
# 查看容器在bridge网络中的IP地址
docker inspect -f '{{ "{{" }}.NetworkSettings.Networks.bridge.IPAddress}}' <容器名或ID>

# 查看容器所有网络的IP地址
docker inspect -f '{{ "{{" }}.NetworkSettings.Networks}}' <容器名或ID>

# 格式化输出为JSON
docker inspect -f '{{ "{{" }}json .NetworkSettings.Networks}}' <容器名或ID> | python -m json.tool

# 查看容器完整的网络配置
docker inspect --format '{{ "{{" }}json .NetworkSettings}}' <容器名或ID> | python -m json.tool
```

**docker exec 命令**：

```bash
# 进入容器查看IP地址
docker exec -it <容器名或ID> ip addr

# 使用hostname命令查看IP
docker exec <容器名或ID> hostname -I

# 使用ifconfig命令查看（需容器内安装net-tools）
docker exec <容器名或ID> ifconfig
```

**docker network 命令**：

```bash
# 查看所有网络
docker network ls

# 查看特定网络的详细信息
docker network inspect <网络名>

# 查看网络中的所有容器
docker network inspect -f '{{ "{{" }}range .Containers}}{{ "{{" }}.Name}}: {{ "{{" }}.IPv4Address}}{{ "{{" }}end}}' <网络名>

# 查找特定容器的网络信息
docker network inspect <网络名> | grep -A 10 <容器名>
```

### 1.2 不同网络模式的IP查看

**bridge模式**：

```bash
# 查看容器在bridge网络中的IP
docker inspect -f '{{ "{{" }}.NetworkSettings.Networks.bridge.IPAddress}}' <容器名>

# 查看bridge网络的子网信息
docker network inspect bridge | grep -A 5 Subnet
```

**host模式**：

```bash
# host模式下容器无独立IP，与宿主机共用
# 查看宿主机IP
hostname -I

# 验证容器是否使用host模式
docker inspect -f '{{ "{{" }}.HostConfig.NetworkMode}}' <容器名>
```

**自定义网络**：

```bash
# 查看容器在自定义网络中的IP
docker inspect -f '{{ "{{" }}.NetworkSettings.Networks.<网络名>.IPAddress}}' <容器名>

# 查看自定义网络的详细信息
docker network inspect <网络名>
```

**none模式**：

```bash
# none模式下容器无网络连接
# 验证容器是否使用none模式
docker inspect -f '{{ "{{" }}.HostConfig.NetworkMode}}' <容器名>
```

### 1.3 批量查看容器IP

**脚本化查看**：

```bash
#!/bin/bash
# 批量查看容器IP地址

echo "容器名/ID\t\t\tIP地址（bridge）\t网络模式"
echo "=============================================================="

# 获取所有容器
containers=$(docker ps -aq)

for container in $containers; do
    # 获取容器名
    name=$(docker inspect -f '{{ "{{" }}.Name}}' $container | sed 's/^\///')
    
    # 获取网络模式
    network_mode=$(docker inspect -f '{{ "{{" }}.HostConfig.NetworkMode}}' $container)
    
    # 获取IP地址（根据网络模式）
    if [ "$network_mode" = "bridge" ]; then
        ip=$(docker inspect -f '{{ "{{" }}.NetworkSettings.Networks.bridge.IPAddress}}' $container)
    elif [ "$network_mode" = "host" ]; then
        ip="与宿主机共用"
    elif [ "$network_mode" = "none" ]; then
        ip="无网络"
    else
        # 自定义网络
        networks=$(docker inspect -f '{{ "{{" }}range $k, $v := .NetworkSettings.Networks}}{{ "{{" }}$k}}:{{ "{{" }}$v.IPAddress}} {{ "{{" }}end}}' $container)
        ip="$networks"
    fi
    
    echo "$name\t\t$ip\t$network_mode"
done
```

**输出示例**：

```
容器名/ID			IP地址（bridge）	网络模式
==============================================================
nginx01			172.17.0.2	bridge
redis01			172.17.0.3	bridge
db01			192.168.1.2	custom-network
test01			与宿主机共用	host
```

---

## 二、容器网络模式

### 2.1 网络模式对比

| 网络模式 | 描述 | 优点 | 缺点 | 适用场景 |
|:---------|:------|:------|:------|:----------|
| **bridge** | 默认模式，容器通过网桥与宿主机通信 | 隔离性好，配置简单 | 网络性能一般 | 单主机容器通信 |
| **host** | 容器与宿主机共享网络命名空间 | 网络性能最优 | 无网络隔离 | 对网络性能要求高的场景 |
| **none** | 容器无网络连接 | 完全隔离 | 无法通信 | 需要完全隔离的场景 |
| **自定义网络** | 用户创建的网络，支持多种驱动 | 灵活配置，隔离性好 | 配置复杂 | 多容器协作，网络隔离 |
| **overlay** | 跨主机网络，用于 swarm 集群 | 支持跨主机通信 | 配置复杂 | 多节点容器集群 |
| **macvlan** | 容器直接使用物理网络 | 网络性能好 | 需要物理网络支持 | 需要直接访问物理网络的场景 |

### 2.2 网络模式配置

**bridge模式**：

```bash
# 创建容器时使用bridge模式（默认）
docker run -d --name nginx01 nginx

# 查看bridge网络
docker network inspect bridge
```

**host模式**：

```bash
# 创建容器时使用host模式
docker run -d --name nginx02 --network host nginx

# 验证网络模式
docker inspect -f '{{ "{{" }}.HostConfig.NetworkMode}}' nginx02
```

**none模式**：

```bash
# 创建容器时使用none模式
docker run -d --name nginx03 --network none nginx

# 验证网络模式
docker inspect -f '{{ "{{" }}.HostConfig.NetworkMode}}' nginx03
```

**自定义网络**：

```bash
# 创建自定义网络（bridge驱动）
docker network create --driver bridge my-network

# 创建容器时使用自定义网络
docker run -d --name nginx04 --network my-network nginx

# 查看自定义网络
docker network inspect my-network
```

**overlay网络**：

```bash
# 初始化swarm集群
docker swarm init

# 创建overlay网络
docker network create --driver overlay overlay-network

# 在swarm服务中使用overlay网络
docker service create --name web --network overlay-network nginx
```

### 2.3 网络模式最佳实践

**选择原则**：
- **单主机多容器**：使用bridge或自定义网络
- **对网络性能要求高**：使用host模式
- **需要网络隔离**：使用自定义网络
- **跨主机通信**：使用overlay网络
- **特殊网络需求**：使用macvlan网络

**配置建议**：
- 生产环境推荐使用自定义网络，便于网络隔离和管理
- 避免使用默认bridge网络，缺乏网络隔离
- 合理规划网络子网，避免IP冲突
- 使用固定IP地址（在自定义网络中），便于服务发现

---

## 三、容器网络管理

### 3.1 网络创建与管理

**网络创建**：

```bash
# 创建bridge网络
docker network create --driver bridge --subnet 192.168.1.0/24 --gateway 192.168.1.1 my-bridge-network

# 创建overlay网络
docker network create --driver overlay --subnet 10.0.0.0/24 overlay-network

# 创建macvlan网络
docker network create --driver macvlan --subnet 192.168.2.0/24 --gateway 192.168.2.1 --opt parent=eth0 my-macvlan-network
```

**网络管理**：

```bash
# 查看所有网络
docker network ls

# 查看网络详情
docker network inspect <网络名>

# 连接容器到网络
docker network connect <网络名> <容器名>

# 断开容器与网络的连接
docker network disconnect <网络名> <容器名>

# 删除网络（需先断开所有容器连接）
docker network rm <网络名>

# 清理未使用的网络
docker network prune
```

### 3.2 网络配置优化

**MTU设置**：

```bash
# 创建网络时设置MTU
docker network create --driver bridge --opt com.docker.network.driver.mtu=1450 my-network

# 查看网络MTU设置
docker network inspect my-network | grep MTU
```

**网络选项**：

```bash
# 创建网络时设置其他选项
docker network create --driver bridge \
  --subnet 192.168.1.0/24 \
  --gateway 192.168.1.1 \
  --opt com.docker.network.bridge.name=my-bridge \
  --opt com.docker.network.bridge.enable_icc=true \
  --opt com.docker.network.bridge.enable_ip_masquerade=true \
  my-network
```

**容器网络配置**：

```bash
# 创建容器时指定网络和IP
docker run -d --name nginx01 \
  --network my-network \
  --ip 192.168.1.10 \
  nginx

# 为容器添加多个网络
docker run -d --name app \
  --network network1 \
  --network network2 \
  myapp
```

### 3.3 网络故障排查

**网络连通性测试**：

```bash
# 测试容器之间的连通性
docker exec <容器1> ping <容器2 IP>

# 测试容器与外部服务的连通性
docker exec <容器> ping google.com

# 测试容器与宿主机的连通性
docker exec <容器> ping <宿主机IP>
```

**网络配置检查**：

```bash
# 检查容器网络配置
docker inspect --format '{{ "{{" }}json .NetworkSettings}}' <容器名> | python -m json.tool

# 检查网络驱动
docker network inspect <网络名> | grep Driver

# 检查iptables规则
iptables -L -n | grep DOCKER
```

**常见网络问题**：

| 问题 | 原因 | 解决方案 |
|:------|:------|:----------|
| 容器无IP | 容器未运行或网络未配置 | 启动容器，检查网络配置 |
| IP无法访问 | 防火墙阻止或网络模式问题 | 检查iptables规则，验证网络模式 |
| 跨主机通信失败 | 网络配置不当或防火墙阻止 | 配置overlay网络，检查防火墙 |
| 网络性能差 | 网络模式选择不当或MTU设置不合理 | 选择合适的网络模式，优化MTU |

---

## 四、容器网络架构设计

### 4.1 单主机网络架构

**基本架构**：
- 使用自定义bridge网络隔离不同应用
- 为每个应用创建独立的网络
- 使用固定IP地址便于服务发现

**示例**：

```bash
# 创建前端网络
docker network create --subnet 192.168.1.0/24 frontend-network

# 创建后端网络
docker network create --subnet 192.168.2.0/24 backend-network

# 创建数据库网络
docker network create --subnet 192.168.3.0/24 db-network

# 启动前端容器
 docker run -d --name frontend --network frontend-network --ip 192.168.1.10 nginx

# 启动后端容器（连接前端和后端网络）
docker run -d --name backend --network frontend-network --ip 192.168.1.20 app
 docker network connect backend-network backend --ip 192.168.2.10

# 启动数据库容器
docker run -d --name db --network backend-network --ip 192.168.2.20 mysql
```

### 4.2 多主机网络架构

**基本架构**：
- 使用overlay网络实现跨主机通信
- 配置swarm集群或Kubernetes
- 使用服务发现和负载均衡

**Docker Swarm示例**：

```bash
# 初始化swarm集群
 docker swarm init --advertise-addr <manager-ip>

# 添加工作节点
docker swarm join --token <token> <manager-ip>:2377

# 创建overlay网络
docker network create --driver overlay --attachable app-network

# 部署服务
docker service create \
  --name web \
  --network app-network \
  --replicas 3 \
  --publish published=80,target=80 \
  nginx
```

**Kubernetes网络**：
- 使用CNI插件（如Calico、Flannel、Cilium）
- 支持Pod间通信和服务发现
- 提供网络策略实现访问控制

### 4.3 网络安全架构

**网络隔离**：
- 使用自定义网络隔离不同应用
- 配置网络策略限制容器间通信
- 使用防火墙规则保护容器网络

**访问控制**：
- 使用Docker网络的icc选项控制容器间通信
- 在Kubernetes中使用NetworkPolicy
- 配置iptables规则限制网络访问

**示例**：

```bash
# 创建网络时禁用容器间通信
docker network create --driver bridge --opt com.docker.network.bridge.enable_icc=false isolated-network

# 连接容器到网络
docker network connect isolated-network container1
docker network connect isolated-network container2

# 此时container1和container2无法通信
# 需要手动连接到同一网络并配置端口映射
```

---

## 五、生产环境最佳实践

### 5.1 网络规划

**IP地址规划**：
- 为不同环境（开发、测试、生产）分配不同的网络段
- 为每个应用或服务分配独立的子网
- 使用CIDR格式合理规划IP地址范围

**网络命名规范**：
- 使用有意义的网络名称，如 `<环境>-<应用>-network`
- 保持网络名称的一致性和可读性
- 记录网络配置信息，便于维护

**文档化**：
- 记录网络架构设计和配置
- 维护网络拓扑图
- 文档化IP地址分配和网络规则

### 5.2 监控与管理

**网络监控**：
- 监控容器网络的连通性和性能
- 使用Prometheus和Grafana监控网络指标
- 设置网络相关的告警规则

**示例监控指标**：
- 网络吞吐量
- 网络延迟
- 丢包率
- 连接数

**网络管理工具**：
- **Docker Network CLI**：基础网络管理
- **Docker Compose**：多容器网络配置
- **Docker Swarm**：集群网络管理
- **Kubernetes**：容器编排和网络管理
- **Calico**：高级网络策略和安全

### 5.3 自动化与脚本

**网络配置脚本**：

```bash
#!/bin/bash
# 容器网络配置脚本

# 配置变量
NETWORK_NAME="app-network"
SUBNET="192.168.1.0/24"
GATEWAY="192.168.1.1"
CONTAINERS=(
  "web:192.168.1.10"
  "api:192.168.1.11"
  "db:192.168.1.12"
)

# 创建网络
echo "创建网络 $NETWORK_NAME..."
docker network create \
  --driver bridge \
  --subnet $SUBNET \
  --gateway $GATEWAY \
  $NETWORK_NAME

# 启动容器
for container in "${CONTAINERS[@]}"; do
  name=$(echo $container | cut -d: -f1)
  ip=$(echo $container | cut -d: -f2)
  
  echo "启动容器 $name，IP: $ip..."
  docker run -d \
    --name $name \
    --network $NETWORK_NAME \
    --ip $ip \
    nginx

done

# 验证网络配置
echo "\n网络配置验证："
docker network inspect $NETWORK_NAME
```

**网络故障排查脚本**：

```bash
#!/bin/bash
# 容器网络故障排查脚本

if [ $# -eq 0 ]; then
  echo "Usage: $0 <container-name>"
  exit 1
fi

CONTAINER=$1

echo "=== 容器网络故障排查 ==="
echo "容器：$CONTAINER"
echo "日期：$(date)"
echo

# 检查容器状态
echo "1. 容器状态："
docker ps -a | grep $CONTAINER

# 检查容器网络配置
echo "\n2. 网络配置："
docker inspect --format '{{ "{{" }}json .NetworkSettings}}' $CONTAINER | python -m json.tool

# 检查网络模式
echo "\n3. 网络模式："
docker inspect -f '{{ "{{" }}.HostConfig.NetworkMode}}' $CONTAINER

# 检查IP地址
echo "\n4. IP地址："
docker inspect -f '{{ "{{" }}range $k, $v := .NetworkSettings.Networks}}{{ "{{" }}$k}}: {{ "{{" }}$v.IPAddress}}{{ "{{" }}end}}' $CONTAINER

# 测试网络连通性
echo "\n5. 网络连通性测试："
IP=$(docker inspect -f '{{ "{{" }}.NetworkSettings.Networks.*.IPAddress}}' $CONTAINER | tr ' ' '\n' | grep -v '^$' | head -1)

if [ -n "$IP" ]; then
  echo "测试容器内部网络："
  docker exec $CONTAINER ping -c 2 $IP
  
  echo "\n测试外部网络："
  docker exec $CONTAINER ping -c 2 google.com
  
  echo "\n测试宿主机连通性："
  HOST_IP=$(hostname -I | cut -d' ' -f1)
  docker exec $CONTAINER ping -c 2 $HOST_IP
else
  echo "容器无IP地址"
fi

# 检查网络规则
echo "\n6. 网络规则："
iptables -L -n | grep DOCKER

echo "\n=== 排查完成 ==="
```

---

## 六、案例分析

### 6.1 案例1：微服务架构网络设计

**背景**：某电商平台采用微服务架构，使用Docker容器部署。

**需求**：
- 前端服务与后端服务隔离
- 数据库服务独立网络
- 服务间通信安全可控
- 支持水平扩展

**解决方案**：

1. **网络设计**：
   ```bash
   # 创建前端网络
   docker network create --subnet 192.168.1.0/24 frontend-network
   
   # 创建后端网络
   docker network create --subnet 192.168.2.0/24 backend-network
   
   # 创建数据库网络
   docker network create --subnet 192.168.3.0/24 db-network
   ```

2. **服务部署**：
   ```bash
   # 前端服务
   docker run -d --name frontend --network frontend-network --ip 192.168.1.10 -p 80:80 nginx
   
   # 后端API服务（连接前端和后端网络）
   docker run -d --name api --network frontend-network --ip 192.168.1.20 backend-api
   docker network connect backend-network api --ip 192.168.2.10
   
   # 数据库服务
   docker run -d --name db --network backend-network --ip 192.168.2.20 mysql
   ```

**实施效果**：
- 网络隔离确保服务安全
- 固定IP地址便于服务发现
- 服务间通信可控
- 支持水平扩展

### 6.2 案例2：跨主机容器通信

**背景**：某企业部署多节点Docker集群，需要容器跨主机通信。

**需求**：
- 容器在不同主机间无缝通信
- 网络性能稳定
- 易于管理和监控

**解决方案**：

1. **使用Docker Swarm**：
   ```bash
   # 初始化swarm集群
   docker swarm init --advertise-addr 192.168.100.10
   
   # 添加工作节点
   docker swarm join --token <token> 192.168.100.10:2377
   
   # 创建overlay网络
   docker network create --driver overlay --attachable cluster-network
   ```

2. **部署服务**：
   ```bash
   # 部署Web服务
   docker service create \
     --name web \
     --network cluster-network \
     --replicas 5 \
     --publish published=80,target=80 \
     nginx
   
   # 部署数据库服务
   docker service create \
     --name db \
     --network cluster-network \
     --replicas 1 \
     mysql
   ```

**实施效果**：
- 容器跨主机无缝通信
- 服务自动负载均衡
- 高可用架构
- 易于扩展和管理

### 6.3 案例3：网络性能优化

**背景**：某高流量应用容器网络性能瓶颈。

**现象**：
- 容器网络延迟高
- 吞吐量不足
- 影响应用响应速度

**分析**：
- 使用默认bridge网络，性能一般
- MTU设置不合理
- 网络模式选择不当

**解决方案**：

1. **优化网络模式**：
   ```bash
   # 对网络性能要求高的服务使用host模式
   docker run -d --name high-performance-app --network host app
   ```

2. **优化MTU设置**：
   ```bash
   # 创建网络时设置合适的MTU
   docker network create --driver bridge --opt com.docker.network.driver.mtu=1450 optimized-network
   
   # 部署应用
   docker run -d --name app --network optimized-network nginx
   ```

3. **使用macvlan网络**：
   ```bash
   # 创建macvlan网络
   docker network create --driver macvlan \
     --subnet 192.168.1.0/24 \
     --gateway 192.168.1.1 \
     --opt parent=eth0 \
     macvlan-network
   
   # 部署应用
   docker run -d --name app --network macvlan-network --ip 192.168.1.100 nginx
   ```

**实施效果**：
- 网络延迟降低50%
- 吞吐量提升30%
- 应用响应速度明显改善

---

## 七、最佳实践总结

### 7.1 核心原则

**网络隔离**：
- 使用自定义网络隔离不同应用
- 避免使用默认bridge网络
- 合理规划网络子网

**性能优化**：
- 根据应用需求选择合适的网络模式
- 优化MTU设置
- 考虑使用host或macvlan模式提升性能

**安全可控**：
- 配置网络策略限制容器间通信
- 使用防火墙规则保护容器网络
- 定期审计网络配置

**可管理性**：
- 文档化网络架构和配置
- 建立网络监控和告警机制
- 自动化网络配置和管理

### 7.2 工具推荐

**网络管理工具**：
- **Docker Network**：基础网络管理
- **Docker Compose**：多容器网络配置
- **Docker Swarm**：集群网络管理
- **Kubernetes**：容器编排和网络管理
- **Calico**：高级网络策略和安全
- **Flannel**：Kubernetes网络插件
- **Cilium**：基于eBPF的网络和安全

**监控工具**：
- **Prometheus**：监控网络指标
- **Grafana**：网络数据可视化
- **Netdata**：实时网络监控
- **cAdvisor**：容器资源监控

### 7.3 经验总结

**常见误区**：
- **忽视网络隔离**：使用默认bridge网络，缺乏安全性
- **网络模式选择不当**：对所有应用使用同一种网络模式
- **IP地址管理混乱**：未规划IP地址，导致冲突
- **缺乏网络监控**：无法及时发现网络问题
- **跨主机通信配置复杂**：未使用合适的网络方案

**成功经验**：
- **网络规划先行**：在部署前规划网络架构
- **使用自定义网络**：提高隔离性和可管理性
- **固定IP地址**：便于服务发现和管理
- **监控网络性能**：及时发现和解决网络问题
- **自动化配置**：减少人工操作错误

---

## 总结

容器网络管理是容器化环境中的关键环节，掌握容器IP地址查看、网络模式配置、网络架构设计等技能，对于SRE工程师来说至关重要。本文提供了一套完整的生产环境最佳实践，包括容器IP地址查看方法、网络模式对比、网络管理技巧和网络架构设计。

**核心要点**：

1. **IP地址查看**：使用docker inspect、docker exec和docker network命令
2. **网络模式**：根据应用需求选择合适的网络模式
3. **网络管理**：创建和管理自定义网络，优化网络配置
4. **网络架构**：设计合理的网络架构，确保服务安全和性能
5. **监控与优化**：建立网络监控机制，优化网络性能

通过本文的指导，希望能帮助SRE工程师更有效地管理容器网络，提高容器化应用的稳定性和性能，为业务提供可靠的容器运行环境。

> **延伸学习**：更多面试相关的容器网络知识，请参考 [SRE面试题解析：怎么查看一个容器的ip地址]({% post_url 2026-04-15-sre-interview-questions %}#36-怎么查看一个容器的ip地址)。

---

## 参考资料

- [Docker网络文档](https://docs.docker.com/network/)
- [Docker网络模式详解](https://docs.docker.com/network/#network-drivers)
- [Docker Swarm网络](https://docs.docker.com/network/overlay/)
- [Kubernetes网络](https://kubernetes.io/docs/concepts/services-networking/)
- [Calico网络策略](https://docs.projectcalico.org/getting-started/kubernetes/network-policy)
- [Flannel网络插件](https://github.com/flannel-io/flannel)
- [Cilium网络解决方案](https://cilium.io/)
- [容器网络性能优化](https://www.docker.com/blog/container-networking-performance/)
- [Docker网络最佳实践](https://success.docker.com/article/networking-best-practices)
- [容器网络安全](https://docs.docker.com/engine/security/)
- [网络监控工具](https://prometheus.io/docs/introduction/overview/)
- [Grafana网络监控](https://grafana.com/docs/grafana/latest/datasources/prometheus/)
- [Netdata容器监控](https://www.netdata.cloud/)
- [cAdvisor容器监控](https://github.com/google/cadvisor)
- [容器网络故障排查](https://docs.docker.com/engine/troubleshooting/network/)
- [Overlay网络配置](https://docs.docker.com/network/overlay/#configure-an-overlay-network)
- [Macvlan网络配置](https://docs.docker.com/network/macvlan/)
- [Docker Compose网络](https://docs.docker.com/compose/networking/)
- [容器网络架构设计](https://www.nginx.com/blog/container-networking-reference-architecture/)
- [微服务网络设计](https://microservices.io/patterns/networks/service-mesh.html)