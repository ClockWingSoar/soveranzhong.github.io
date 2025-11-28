---
layout: post
title: "Ubuntu 24 多张网卡配置失败问题分析与解决方案"
categories: [Linux, Network]
tags: [ubuntu, network, netplan, networkmanager, nic]
author: "soveranzhong"
date: 2025-11-27 00:00:00
---

## 问题描述

在 Ubuntu 24 系统中配置多张网卡时遇到了以下问题：

1. 执行 `nmcli conn` 显示存在多个网络连接，但只有 `netplan-eth0` 处于活动状态
2. 尝试激活 `netplan-eth1` 时失败，错误信息：
   ```
   错误：连接激活失败：No suitable device found for this connection (device eth0 not available because profile is not compatible with device (mismatching interface name)).
   ```
3. `/etc/netplan` 目录下存在多个配置文件，可能导致冲突

## 问题分析

### 1. 网络连接状态分析

```bash
nmcli conn
NAME                UUID                                  TYPE      DEVICE 
netplan-eth0        626dd384-8b3d-3690-9511-192b2c79b3fd  ethernet  eth0 
lo                  8e52dab3-0a2e-40b2-8e10-214acff45cb7  loopback  lo 
eth0                97e20144-edbe-3696-bdfd-08faa089f236  ethernet  -- 
netplan-eth1        8bf25856-ca0b-388e-823c-b898666ab9d2  ethernet  -- 
Wired connection 1  142b603d-adea-3fc2-b303-32e8905e87f6  ethernet  -- 
```

从输出可以看出：
- `netplan-eth0` 连接正常工作在 `eth0` 设备上
- `netplan-eth1` 连接存在但未关联到任何设备
- 存在多个冗余的连接配置（`eth0` 和 `Wired connection 1`）

### 2. Netplan 配置文件分析

#### 2.1 主配置文件（50-cloud-init.yaml）

```yaml
# Let NetworkManager manage all devices on this system
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    eth0:
      addresses:
        - "10.0.0.13/24"
      nameservers:
        addresses:
          - 10.0.0.2
      routes:
        - to: default
          via: 10.0.0.2  # 注意这里添加了空格
    eth1:
      addresses:
        - "10.0.0.113/24"
```

这个配置文件看起来是正确的，定义了两个网卡 `eth0` 和 `eth1` 的配置。

#### 2.2 NetworkManager 生成的配置文件

在 `/etc/netplan` 目录下还存在两个由 NetworkManager 生成的配置文件：
- `90-NM-142b603d-adea-3fc2-b303-32e8905e87f6.yaml`
- `90-NM-97e20144-edbe-3696-bdfd-08faa089f236.yaml`

这些文件包含了旧的或冲突的配置，特别是：
- 它们引用了 `ens33` 和 `eth0` 接口
- 它们可能与用户的主配置文件冲突
- 它们的文件名以 `90-` 开头，优先级高于用户的 `50-cloud-init.yaml`

### 3. 问题根本原因

1. **配置文件冲突**：存在多个冲突的网络配置文件，导致 Netplan 和 NetworkManager 无法正确处理
2. **设备命名不一致**：可能存在设备命名变化（如从 `ens33` 变为 `eth0`），但旧的配置文件仍在引用旧名称
3. **NetworkManager 生成的文件优先级过高**：以 `90-` 开头的文件优先级高于用户的 `50-` 文件，导致配置被覆盖
4. **eth1 设备可能未被正确识别**：可能是驱动问题或硬件识别问题

## 解决方案

### 1. 清理冲突的配置文件

首先，我们需要清理 `/etc/netplan` 目录下的冲突配置文件：

```bash
# 备份所有配置文件（可选）
sudo mkdir -p /etc/netplan/backup
sudo cp /etc/netplan/*.yaml /etc/netplan/backup/

# 删除 NetworkManager 生成的配置文件
sudo rm /etc/netplan/90-NM-*.yaml
```

### 2. 验证网卡设备是否存在

使用 `ip` 命令验证系统中是否存在 `eth1` 设备：

```bash
ip addr show
```

如果 `eth1` 设备不存在，可能是以下原因：
- 硬件未正确连接
- 驱动问题
- 设备名称不同（如 `ens34` 等）

### 3. 修正 Netplan 配置文件

确保 `/etc/netplan/50-cloud-init.yaml` 配置正确，特别是：
- 使用正确的设备名称
- 配置适当的 IP 地址和路由

### 4. 应用 Netplan 配置

```bash
# 生成配置
sudo netplan generate

# 应用配置
sudo netplan apply
```

### 5. 检查 NetworkManager 连接

```bash
# 查看所有连接
nmcli conn

# 删除冗余的连接（如果有）
sudo nmcli conn delete eth0
sudo nmcli conn delete "Wired connection 1"
```

### 6. 激活 netplan-eth1 连接

```bash
# 激活 netplan-eth1 连接
sudo nmcli conn up netplan-eth1
```

### 7. 验证配置

```bash
# 检查所有网卡的 IP 地址
ip addr show

# 测试网络连接
ping -c 3 10.0.0.2  # 测试 eth0 连接
ping -c 3 10.0.0.113 -I eth1  # 测试 eth1 连接
```

## 预防措施

1. **避免手动编辑 NetworkManager 生成的文件**：这些文件通常由 NetworkManager 自动生成，手动编辑可能导致冲突
2. **使用一致的配置方式**：选择 Netplan 或 NetworkManager 中的一种来管理网络，避免混合使用
3. **定期清理旧配置**：当网络配置发生变化时，及时清理旧的配置文件
4. **备份配置文件**：在修改配置前备份原文件，以便出现问题时可以恢复

## 高级故障排除

### 1. 查看 Netplan 日志

```bash
sudo journalctl -u netplan-wpa-wlan0.service  # 替换为实际的服务名
```

### 2. 查看 NetworkManager 日志

```bash
sudo journalctl -u NetworkManager
```

### 3. 检查网卡驱动

```bash
# 查看网卡硬件信息
lspci | grep -i ethernet

# 查看网卡驱动信息
ethtool -i eth0
ethtool -i eth1
```

### 4. 测试网卡硬件

```bash
# 测试网卡是否能检测到链接
ethtool eth1
```

## 总结

在 Ubuntu 24 中配置多张网卡时，常见的问题包括：

1. **配置文件冲突**：多个配置文件导致的冲突
2. **设备命名不一致**：设备名称变化导致的配置不匹配
3. **NetworkManager 与 Netplan 配置混合**：两种配置方式混用导致的问题

通过清理冲突的配置文件、验证网卡设备、修正 Netplan 配置并重新应用，我们可以解决多张网卡配置失败的问题。

记住，在管理网络配置时，保持配置的简洁性和一致性是关键。定期清理旧的配置文件，使用一种统一的配置方式，可以避免很多网络配置问题。