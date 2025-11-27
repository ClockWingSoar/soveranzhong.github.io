---
layout: post
title: "Ubuntu Netplan 配置文件 YAML 语法错误修复指南"
categories: [Linux, Network]
tags: [ubuntu, netplan, yaml, network]
author: "soveranzhong"
date: 2025-11-28 00:00:00
---

## 问题描述

在 Ubuntu 24 系统上执行 `netplan apply` 命令时遇到以下错误：

```bash
** (generate:162265): WARNING **: 22:56:14.429: Permissions for /etc/netplan/01-network-manager-all.yaml are too open. Netplan configuration should NOT be accessible by others.

** (generate:162265): WARNING **: 22:56:14.429: Permissions for /etc/netplan/50-cloud-init.yaml are too open. Netplan configuration should NOT be accessible by others.
/etc/netplan/50-cloud-init.yaml:9:7: Invalid YAML: did not find expected '-' indicator:
      nameservers:
      ^
```

## 问题分析

### 1. YAML 语法错误

错误信息指向了 `/etc/netplan/50-cloud-init.yaml` 文件的第9行，提示在 `nameservers:` 前面缺少预期的 `-` 指示符。但实际上，`nameservers:` 不应该有 `-`，因为它是一个映射（dictionary），而不是列表项。

查看原始配置文件：

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
           via:10.0.0.2 
     eth1: 
       addresses: 
       - "10.0.0.113/24"
```

### 2. 文件权限问题

Netplan 配置文件权限过于开放，不应该被其他人访问。

## 解决方案

### 1. 修复 YAML 语法错误

主要问题是缩进不一致和缺少空格。以下是修复后的配置文件：

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

### 2. 修复文件权限问题

执行以下命令修复 Netplan 配置文件的权限：

```bash
sudo chmod 600 /etc/netplan/*.yaml
```

### 3. 应用修复后的配置

```bash
sudo netplan apply
```

## 详细说明

### YAML 语法规则

1. **缩进一致性**：使用相同数量的空格进行缩进，推荐使用 2 个或 4 个空格。
2. **映射项**：使用 `key: value` 格式，冒号后必须有一个空格。
3. **列表项**：使用 `- ` 开头，短横线后必须有一个空格。
4. **嵌套结构**：通过缩进来表示嵌套关系。

### Netplan 配置文件权限

Netplan 配置文件包含网络配置信息，应该只有 root 用户可以访问。使用 `chmod 600` 命令可以确保文件只有所有者（root）可以读写，其他用户没有任何权限。

## 验证修复

执行以下命令验证修复是否成功：

```bash
sudo netplan apply
# 检查网络状态
ip addr show
dig +short google.com
```

## 总结

1. Netplan 配置文件必须严格遵循 YAML 语法规则，特别是缩进和空格。
2. 配置文件权限应该设置为 `600`，确保只有 root 用户可以访问。
3. 在应用配置前，可以使用 `netplan generate` 命令检查语法是否正确：
   ```bash
   sudo netplan generate
   ```

通过以上步骤，你可以成功修复 Netplan 配置文件的 YAML 语法错误和权限问题。