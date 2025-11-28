---
layout: post
title: 解决 nmcli 静态 IP 配置错误：method 'manual' requires at least an address or a route
layout: post
date: 2025-11-30 15:00:00
categories: [Linux, Network]
tags: [nmcli, 静态IP, NetworkManager, 网络配置]
description: 详细解释 nmcli 配置静态 IP 时出现 "method 'manual' requires at least an address or a route" 错误的原因及解决方案。
---

## 问题现象

当使用 `nmcli` 命令尝试将网络连接的 IP 配置方法改为手动（静态 IP）时，出现以下错误：

```bash
root@ubuntu24:/run/NetworkManager/system-connections# nmcli con mod eth1 ipv4.method manual
错误：修改连接 "eth1" 失败：ipv4.method: method 'manual' requires at least an address or a route
```

## 错误原因分析

这个错误的意思是：**当使用手动 IP 配置方法（manual）时，必须至少提供一个 IP 地址或路由**。

在 NetworkManager 中，当你将 `ipv4.method` 设置为 `manual` 时，NetworkManager 期望你同时提供以下至少一项：
- IP 地址（`ipv4.addresses`）
- 路由信息（`ipv4.routes`）

单独设置 `ipv4.method manual` 是不够的，因为静态 IP 配置需要明确的网络参数。

## 解决方案

### 正确的命令格式

当使用 `nmcli` 配置静态 IP 时，需要在同一个命令中同时指定：
1. IP 配置方法（`ipv4.method manual`）
2. IP 地址和子网掩码（`ipv4.addresses "IP地址/子网掩码"`）
3. 网关地址（可选，`ipv4.gateway "网关地址"`）
4. DNS 服务器（可选，`ipv4.dns "DNS服务器地址"`）

### 示例命令

#### 1. 基本静态 IP 配置

```bash
# 同时设置 IP 配置方法和 IP 地址
nmcli con mod eth1 ipv4.method manual ipv4.addresses "192.168.1.100/24"
```

#### 2. 完整的静态 IP 配置

```bash
# 同时设置 IP 配置方法、IP 地址、网关和 DNS
nmcli con mod eth1 \
    ipv4.method manual \
    ipv4.addresses "192.168.1.100/24" \
    ipv4.gateway "192.168.1.1" \
    ipv4.dns "8.8.8.8,8.8.4.4"
```

#### 3. 配置多个 IP 地址

```bash
nmcli con mod eth1 \
    ipv4.method manual \
    ipv4.addresses "192.168.1.100/24,192.168.1.101/24" \
    ipv4.gateway "192.168.1.1"
```

#### 4. 应用配置并重启连接

```bash
# 重启连接以应用新配置
nmcli con down eth1 && nmcli con up eth1
```

### 完整的配置流程

1. **查看当前连接**
   ```bash
   nmcli con show
   ```

2. **查看当前连接的详细配置**
   ```bash
   nmcli con show eth1
   ```

3. **修改为静态 IP 配置**
   ```bash
   nmcli con mod eth1 \
       ipv4.method manual \
       ipv4.addresses "192.168.1.100/24" \
       ipv4.gateway "192.168.1.1" \
       ipv4.dns "8.8.8.8,8.8.4.4"
   ```

4. **验证配置更改**
   ```bash
   nmcli con show eth1 | grep ipv4
   ```

5. **重启连接以应用配置**
   ```bash
   nmcli con down eth1 && nmcli con up eth1
   ```

6. **验证 IP 地址是否生效**
   ```bash
   ip a show eth1
   ```

## 常见问题及解决方法

### 1. 忘记设置网关导致网络不通

**问题**：配置了静态 IP 但忘记设置网关，导致无法访问外部网络。

**解决方案**：添加网关配置

```bash
nmcli con mod eth1 ipv4.gateway "192.168.1.1"
nmcli con down eth1 && nmcli con up eth1
```

### 2. DNS 配置无效

**问题**：配置了 DNS 但无法解析域名。

**解决方案**：检查 DNS 配置并确保 NetworkManager 管理 DNS

```bash
# 查看 DNS 配置
nmcli con show eth1 | grep dns

# 确保 NetworkManager 管理 DNS
cat /etc/resolv.conf | grep nameserver
```

### 3. 无法删除旧的 DNS 服务器

**问题**：使用 `nmcli con mod` 命令添加新 DNS 时，旧的 DNS 仍然存在。

**解决方案**：先清空 DNS 配置，再添加新的 DNS

```bash
# 清空 DNS 配置
nmcli con mod eth1 ipv4.dns ""

# 添加新的 DNS
nmcli con mod eth1 ipv4.dns "8.8.8.8,8.8.4.4"
```

## 总结

当使用 `nmcli` 命令将网络连接配置为静态 IP 时，必须同时提供 IP 地址或路由信息，否则会出现 `method 'manual' requires at least an address or a route` 错误。

正确的做法是在同一个命令中同时指定：
- IP 配置方法（`ipv4.method manual`）
- IP 地址和子网掩码（`ipv4.addresses "IP地址/子网掩码"`）
- 可选的网关和 DNS 服务器

通过遵循正确的命令格式和配置流程，可以顺利使用 `nmcli` 配置静态 IP 地址，避免常见的配置错误。