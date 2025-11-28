---
layout: post
title: VMware Workstation 多网段网络配置实践：实现跨网段虚拟机通信
layout: post
date: 2025-11-27 17:00:00
categories: [Linux, Network, Virtualization]
tags: [VMware, 跨网段通信, 软路由, Rocky Linux, Ubuntu]
description: 详细介绍如何使用 VMware Workstation 创建多网段网络环境，通过两台 Rocky Linux 虚拟机充当路由器，实现不同网段 Ubuntu 客户端之间的跨网段通信。
---

## 一、环境规划

### 1.1 网络拓扑图

```
+------------------+       +------------------+
|  主机3 (Ubuntu)  |       |  主机4 (Ubuntu)  |
|  172.24.100.7/24 |       |  192.168.8.16/24 |
|  网关: 172.24.100.6 |       |  网关: 192.168.8.15  |
+------------------+       +------------------+
         |                           |
         | 仅主机-2 (172.24.100.0/24) | 仅主机-1 (192.168.8.0/24)
         |                           |
+------------------+       +------------------+
|  主机1 (Rocky 9) |       |  主机2 (Rocky 9) |
|  路由器          |       |  路由器          |
|  172.24.100.6/24 |       |  192.168.8.15/24 |
|  10.0.0.12/24    |-------|  10.0.0.15/24    |
+------------------+   NAT  +------------------+
                        (10.0.0.0/24)
```

### 1.2 主机规划

| 主机 | 角色 | 网卡类型 | IP地址 | 系统 |
|------|------|----------|--------|------|
| 主机1 | 路由器 | 仅主机-2网卡 | 172.24.100.6/24 | Rocky Linux 9 |
| 主机1 | 路由器 | NAT网卡 | 10.0.0.12/24 | Rocky Linux 9 |
| 主机2 | 路由器 | NAT网卡 | 10.0.0.15/24 | Rocky Linux 9 |
| 主机2 | 路由器 | 仅主机-1网卡 | 192.168.8.15/24 | Rocky Linux 9 |
| 主机3 | 客户端 | 仅主机-2网卡 | 172.24.100.7/24 | Ubuntu 24.04 |
| 主机4 | 客户端 | 仅主机-1网卡 | 192.168.8.16/24 | Ubuntu 24.04 |

### 1.3 VMware 网络配置

1. **添加新的仅主机网络**：
   - 在 VMware Workstation 中添加 `vmnet2` 网段
   - 网段地址：`172.24.100.0/24`
   - 子网掩码：`255.255.255.0`

2. **现有网络**：
   - `vmnet1`（仅主机-1）：`192.168.8.0/24`
   - `vmnet8`（NAT）：`10.0.0.0/24`

## 二、配置步骤

### 2.1 准备工作

1. **清理旧网卡**（如果需要）：
   ```bash
   # 查看现有网卡
   ip a
   
   # 如果需要清理旧网卡配置（以 eth0 为例）
   nmcli con delete eth0
   ```

2. **安装必要工具**：
   ```bash
   # Ubuntu
   apt update && apt install -y net-tools vim
   
   # Rocky Linux
   dnf update && dnf install -y net-tools vim
   ```

### 2.2 配置主机1（Rocky 9 路由器）

#### 2.2.1 配置网卡

1. **查看网卡信息**：
   ```bash
   ip a
   ```
   假设网卡名称为：
   - 仅主机-2网卡：`ens192`
   - NAT网卡：`ens224`

2. **配置仅主机-2网卡（172.24.100.6/24）**：
   ```bash
   nmcli con add type ethernet con-name ens192 ifname ens192 ipv4.addresses 172.24.100.6/24 ipv4.method manual
   nmcli con up ens192
   ```

3. **配置NAT网卡（10.0.0.12/24）**：
   ```bash
   nmcli con add type ethernet con-name ens224 ifname ens224 ipv4.addresses 10.0.0.12/24 ipv4.method manual
   nmcli con up ens224
   ```

#### 2.2.2 开启路由转发

1. **修改配置文件**：
   ```bash
   vim /etc/sysctl.conf
   ```
   添加或修改：
   ```
   net.ipv4.ip_forward=1
   ```

2. **使配置生效**：
   ```bash
   sysctl -p
   ```

3. **验证路由转发是否开启**：
   ```bash
   sysctl -a | grep ip_forward
   cat /proc/sys/net/ipv4/ip_forward
   ```
   输出应为 `1`

#### 2.2.3 配置防火墙

1. **关闭防火墙（简单测试环境）**：
   ```bash
   systemctl stop firewalld
   systemctl disable firewalld
   ```

2. **或配置防火墙规则（生产环境）**：
   ```bash
   firewall-cmd --permanent --add-masquerade
   firewall-cmd --reload
   ```

### 2.3 配置主机2（Rocky 9 路由器）

#### 2.3.1 配置网卡

1. **查看网卡信息**：
   ```bash
   ip a
   ```
   假设网卡名称为：
   - NAT网卡：`ens192`
   - 仅主机-1网卡：`ens224`

2. **配置NAT网卡（10.0.0.15/24）**：
   ```bash
   nmcli con add type ethernet con-name ens192 ifname ens192 ipv4.addresses 10.0.0.15/24 ipv4.method manual
   nmcli con up ens192
   ```

3. **配置仅主机-1网卡（192.168.8.15/24）**：
   ```bash
   nmcli con add type ethernet con-name ens224 ifname ens224 ipv4.addresses 192.168.8.15/24 ipv4.method manual
   nmcli con up ens224
   ```

#### 2.3.2 开启路由转发

同主机1的配置步骤，确保 `net.ipv4.ip_forward=1`

#### 2.3.3 配置防火墙

同主机1的配置步骤，关闭防火墙或配置适当的规则

### 2.4 配置主机3（Ubuntu 24.04 客户端）

#### 2.4.1 配置网卡

1. **查看网卡信息**：
   ```bash
   ip a
   ```
   假设仅主机-2网卡名称为 `ens18`

2. **配置网卡（172.24.100.7/24）**：
   ```bash
   nmcli con add type ethernet con-name ens18 ifname ens18 ipv4.addresses 172.24.100.7/24 ipv4.gateway 172.24.100.6 ipv4.method manual
   nmcli con up ens18
   ```

#### 2.4.2 验证网络连接

1. **测试到主机1的连接**：
   ```bash
   ping -c 4 172.24.100.6
   ```

2. **测试到主机1 NAT网卡的连接**：
   ```bash
   ping -c 4 10.0.0.12
   ```

### 2.5 配置主机4（Ubuntu 24.04 客户端）

#### 2.5.1 配置网卡

1. **查看网卡信息**：
   ```bash
   ip a
   ```
   假设仅主机-1网卡名称为 `ens18`

2. **配置网卡（192.168.8.16/24）**：
   ```bash
   nmcli con add type ethernet con-name ens18 ifname ens18 ipv4.addresses 192.168.8.16/24 ipv4.gateway 192.168.8.15 ipv4.method manual
   nmcli con up ens18
   ```

#### 2.5.2 验证网络连接

1. **测试到主机2的连接**：
   ```bash
   ping -c 4 192.168.8.15
   ```

2. **测试到主机2 NAT网卡的连接**：
   ```bash
   ping -c 4 10.0.0.15
   ```

### 2.6 配置静态路由

#### 2.6.1 在主机1上添加路由

添加到主机4网段（192.168.8.0/24）的路由，下一跳指向主机2的NAT网卡：

```bash
nmcli con mod ens224 +ipv4.routes "192.168.8.0/24 10.0.0.15"
nmcli con up ens224
```

或者使用 `ip` 命令临时添加（重启后失效）：
```bash
ip route add 192.168.8.0/24 via 10.0.0.15 dev ens224
```

#### 2.6.2 在主机2上添加路由

添加到主机3网段（172.24.100.0/24）的路由，下一跳指向主机1的NAT网卡：

```bash
nmcli con mod ens192 +ipv4.routes "172.24.100.0/24 10.0.0.12"
nmcli con up ens192
```

或者使用 `ip` 命令临时添加：
```bash
ip route add 172.24.100.0/24 via 10.0.0.12 dev ens192
```

## 三、测试连通性

### 3.1 测试主机3到主机4的连通性

从主机3执行：
```bash
ping -c 4 192.168.8.16
```

### 3.2 测试主机4到主机3的连通性

从主机4执行：
```bash
ping -c 4 172.24.100.7
```

### 3.3 跟踪路由

```bash
# 从主机3到主机4
traceroute 192.168.8.16

# 从主机4到主机3
traceroute 172.24.100.7
```

预期输出应该显示数据包经过主机1和主机2中转。

## 四、常见问题排查

### 4.1 无法ping通网关

1. **检查网卡配置**：
   ```bash
   nmcli con show
   ip a
   ```

2. **检查物理连接**：
   ```bash
   ethtool ens192 | grep Link
   ```
   确保显示 `Link detected: yes`

3. **检查IP地址和子网掩码**：
   确保网关和客户端在同一网段

### 4.2 无法ping通其他网段

1. **检查路由转发**：
   ```bash
   cat /proc/sys/net/ipv4/ip_forward
   ```
   确保输出为 `1`

2. **检查路由表**：
   ```bash
   ip route
   ```
   确保有到目标网段的路由

3. **检查防火墙**：
   ```bash
   # 查看防火墙状态
   systemctl status firewalld
   
   # 查看防火墙规则
   firewall-cmd --list-all
   ```

4. **检查NAT配置**：
   如果使用了NAT，确保masquerade已启用

### 4.3 路由表配置错误

1. **查看路由表**：
   ```bash
   ip route
   ```

2. **删除错误路由**：
   ```bash
   ip route del 192.168.8.0/24
   ```

3. **重新添加正确路由**：
   ```bash
   ip route add 192.168.8.0/24 via 10.0.0.15 dev ens224
   ```

## 五、优化配置

### 5.1 配置持久化路由

在 Rocky Linux 中，使用 NetworkManager 配置的路由会自动持久化。如果使用 `ip route` 命令添加的临时路由，需要手动配置持久化：

```bash
# 编辑网卡配置文件
vim /etc/sysconfig/network-scripts/ifcfg-ens224

# 添加路由配置
GATEWAY=10.0.0.1
IPADDR=10.0.0.12
PREFIX=24

# 添加静态路由
IPROUTE0="route add -net 192.168.8.0/24 via 10.0.0.15 dev ens224"
```

### 5.2 配置DNS解析

如果需要域名解析，可以在各主机上配置DNS：

```bash
# Ubuntu
nmcli con mod ens18 ipv4.dns "8.8.8.8 8.8.4.4"

# Rocky Linux
nmcli con mod ens192 ipv4.dns "8.8.8.8 8.8.4.4"
```

### 5.3 配置网络监控

可以安装网络监控工具，如 `nload`、`iftop` 等，监控网络流量：

```bash
# Ubuntu
apt install -y nload iftop

# Rocky Linux
dnf install -y nload iftop
```

## 六、总结

通过以上配置，我们成功实现了：

1. 利用两台 Rocky Linux 虚拟机充当路由器
2. 配置了三种不同类型的网络：仅主机-1、仅主机-2 和 NAT
3. 实现了不同网段客户端（主机3和主机4）之间的跨网段通信
4. 开启了路由转发功能，配置了静态路由

这个实验展示了如何使用软路由实现复杂网络环境的配置，对于理解网络路由、网段划分和跨网段通信非常有帮助。在实际生产环境中，可以根据需要调整网络拓扑和配置，实现更复杂的网络架构。

## 七、参考资料

1. [VMware Workstation 网络配置指南](https://docs.vmware.com/en/VMware-Workstation-Pro/17/com.vmware.ws.using.doc/GUID-22C64671-1E0B-4668-9B84-376D62140E7D.html)
2. [Rocky Linux 网络配置](https://docs.rockylinux.org/zh/guides/networking/networkmanager/)
3. [Ubuntu 网络配置](https://ubuntu.com/server/docs/network-configuration)
4. [Linux 路由配置指南](https://tldp.org/HOWTO/Adv-Routing-HOWTO/)
