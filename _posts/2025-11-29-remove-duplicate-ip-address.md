---
layout: post
title: Linux 网卡出现两个 IP 地址的原因及解决方法
layout: post
date: 2025-11-29 15:00:00
categories: [Linux, Network]
tags: [Linux网络, IP地址, NetworkManager, Netplan]
description: 详细分析 Linux 网卡出现两个 IP 地址的原因，并提供多种解决方案来去除不需要的 IP 地址。
---

## 问题现象

在 Ubuntu 24.04 系统中，使用 `ip a` 命令查看网络接口信息时，发现 eth0 网卡有两个 IP 地址：

```bash
root@ubuntu24:/etc/netplan# ip a
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 00:0c:29:44:77:6b brd ff:ff:ff:ff:ff:ff
    altname enp2s1
    altname ens33
    inet 10.0.0.16/24 brd 10.0.0.255 scope global noprefixroute eth0
       valid_lft forever preferred_lft forever
    inet 172.24.100.2/24 brd 172.24.100.255 scope global dynamic noprefixroute eth0
       valid_lft 932sec preferred_lft 932sec
    inet6 fe80::52e5:df16:9564:f355/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
```

其中：
- `10.0.0.16/24` 是静态 IP 地址（没有 `dynamic` 标记）
- `172.24.100.2/24` 是动态获取的 IP 地址（有 `dynamic` 标记）

## 原因分析

### 1. 网络配置冲突

从 NetworkManager 配置文件可以看出，当前连接使用的是自动获取 IP 地址的方式：

```bash
root@ubuntu24:/etc/netplan# cat /run/NetworkManager/system-connections/netplan-NM-3f66d423-5d20-3818-a84f-db79126eeaa9.nmconnection
[connection]
id=eth0
type=ethernet
uuid=3f66d423-5d20-3818-a84f-db79126eeaa9
interface-name=eth0
#Netplan: passthrough setting
autoconnect-priority=-999
#Netplan: passthrough setting
timestamp=1764325222

[ethernet]
wake-on-lan=1

[ipv4]
method=auto

[ipv6]
method=auto
#Netplan: passthrough setting
addr-gen-mode=default

[proxy]
```

但同时存在静态 IP 地址 `10.0.0.16/24`，这可能是由于以下原因：

- **Netplan 配置冲突**：Netplan 配置文件中可能同时配置了静态 IP 和 DHCP
- **旧配置残留**：之前手动配置了静态 IP，后来改为 DHCP，但旧配置没有完全清除
- **多个网络配置文件**：存在多个有效的网络配置文件

### 2. IP 地址类型分析

从 `ip a` 输出可以看出：
- `10.0.0.16/24`：没有 `dynamic` 标记，说明是静态配置的
- `172.24.100.2/24`：有 `dynamic` 标记，说明是通过 DHCP 动态获取的

## 解决方案

### 方法一：使用 `ip` 命令临时移除 IP 地址

如果只是临时需要移除 IP 地址，可以使用 `ip` 命令：

```bash
# 移除指定的 IP 地址
ip addr del 10.0.0.16/24 dev eth0

# 验证是否移除成功
ip a show eth0
```

**注意**：这种方法只是临时生效，系统重启后 IP 地址会重新出现。

### 方法二：检查并修改 Netplan 配置

Netplan 是 Ubuntu 18.04 及以上版本的默认网络配置工具。需要检查 Netplan 配置文件：

1. **查看 Netplan 配置文件**
   ```bash
   ls -la /etc/netplan/
   cat /etc/netplan/*.yaml
   ```

2. **修改 Netplan 配置**
   如果发现配置文件中同时配置了静态 IP 和 DHCP，需要修改为只使用一种方式。
   
   **示例：只使用 DHCP**
   ```yaml
   network:
     version: 2
     renderer: NetworkManager
     ethernets:
       eth0:
         dhcp4: true
         dhcp6: true
   ```
   
   **示例：只使用静态 IP**
   ```yaml
   network:
     version: 2
     renderer: NetworkManager
     ethernets:
       eth0:
         addresses:
           - 172.24.100.2/24
         gateway4: 172.24.100.1
         nameservers:
           addresses: [8.8.8.8, 8.8.4.4]
   ```

3. **应用 Netplan 配置**
   ```bash
   netplan apply
   ```
   或者
   ```bash
   netplan generate && netplan apply
   ```

### 方法三：使用 NetworkManager 命令行工具移除 IP

1. **查看当前连接的 IP 配置**
   ```bash
   nmcli con show eth0 | grep ipv4.addresses
   ```

2. **移除静态 IP 地址**
   ```bash
   # 查看当前 ipv4 配置
   nmcli con show eth0 ipv4
   
   # 修改连接，移除静态 IP 配置（设置为自动获取）
   nmcli con mod eth0 ipv4.method auto ipv4.addresses ""
   
   # 重启连接
   nmcli con down eth0 && nmcli con up eth0
   ```

### 方法四：删除旧的网络配置文件

如果存在多个网络配置文件，可能会导致冲突：

1. **查看所有 NetworkManager 配置文件**
   ```bash
   ls -la /etc/NetworkManager/system-connections/
   ls -la /run/NetworkManager/system-connections/
   ```

2. **删除不需要的配置文件**
   ```bash
   # 先备份
   cp /etc/NetworkManager/system-connections/旧配置.nmconnection /root/
   
   # 删除旧配置
   rm /etc/NetworkManager/system-connections/旧配置.nmconnection
   ```

3. **重启 NetworkManager 服务**
   ```bash
   systemctl restart NetworkManager
   ```

### 方法五：检查并清理旧的 IP 配置

1. **检查是否有旧的 ifupdown 配置**
   ```bash
   cat /etc/network/interfaces
   ```
   如果有 eth0 的配置，需要注释或删除。

2. **检查是否有 systemd-networkd 配置**
   ```bash
   ls -la /etc/systemd/network/
   ```
   如果有相关配置，需要调整。

## 验证解决方案

执行上述操作后，使用 `ip a` 命令验证 IP 地址是否已经移除：

```bash
ip a show eth0
```

## 预防措施

1. **统一网络配置工具**：在 Ubuntu 系统中，建议只使用一种网络配置工具（Netplan + NetworkManager 或 systemd-networkd）

2. **定期清理旧配置**：在修改网络配置时，及时清理旧的配置文件

3. **使用一致的配置方式**：对于同一个网卡，不要同时配置静态 IP 和 DHCP

4. **重启网络服务**：修改网络配置后，确保重启相关服务以应用更改

5. **检查配置文件语法**：使用 `netplan try` 命令测试 Netplan 配置语法是否正确

## 总结

Linux 网卡出现两个 IP 地址通常是由于网络配置冲突导致的。通过以下步骤可以解决：

1. 分析 IP 地址类型（静态或动态）
2. 检查 Netplan 配置文件
3. 检查 NetworkManager 配置
4. 移除冲突的配置
5. 应用新配置并验证

选择合适的解决方案取决于你的网络环境和需求。对于临时需求，可以使用 `ip` 命令临时移除；对于长期解决方案，建议修改 Netplan 或 NetworkManager 配置。