---
layout: post
title: 使用 nmcli 命令修改 Linux 网络连接名称
layout: post
date: 2025-11-28 20:00:00
categories: [Linux, Network]
tags: [nmcli, 网络连接, Linux网络配置]
description: 详细介绍如何使用 nmcli 命令修改 Linux 系统中已有的网络连接名称。
---

## 问题背景

在使用 `nmcli` 命令管理 Linux 网络连接时，有时需要修改已有的网络连接名称。例如，将默认的 "有线连接 1" 修改为更直观的 "eth0"，以便于管理和识别。

## 解决方案

要修改已有的网络连接名称，需要使用 `nmcli connection modify` 命令，并指定 `connection.id` 属性来设置新的连接名称。

### 命令格式

```bash
nmcli con mod "旧连接名称" connection.id "新连接名称"
```

### 具体操作步骤

1. **查看当前网络连接**
   ```bash
   nmcli conn show
   ```
   输出示例：
   ```
   NAME        UUID                                  TYPE      DEVICE 
   有线连接 1  3f66d423-5d20-3818-a84f-db79126eeaa9  ethernet  eth0   
   lo          0fb252ad-d38d-4045-8470-3aed9e3d0c66  loopback  lo     
   ```

2. **修改连接名称**
   ```bash
   nmcli con mod "有线连接 1" connection.id "eth0"
   ```

3. **验证修改结果**
   ```bash
   nmcli conn show
   ```
   输出示例：
   ```
   NAME   UUID                                  TYPE      DEVICE 
   eth0   3f66d423-5d20-3818-a84f-db79126eeaa9  ethernet  eth0   
   lo     0fb252ad-d38d-4045-8470-3aed9e3d0c66  loopback  lo     
   ```

## 常见错误及解决方法

### 错误：无效的 <设置>.<属性> "eth0"

**错误命令**：
```bash
nmcli con mod "有线连接 1" eth0
```

**错误原因**：命令格式不正确，缺少 `connection.id` 属性指定。

**解决方法**：使用正确的命令格式，指定 `connection.id` 属性。

### 错误：未找到连接

**错误命令**：
```bash
nmcli con mod "不存在的连接名称" connection.id "新名称"
```

**错误原因**：指定的旧连接名称不存在。

**解决方法**：先使用 `nmcli conn show` 命令查看当前存在的连接名称，然后使用正确的名称进行修改。

## 其他 nmcli 连接管理命令

### 1. 创建新连接
```bash
nmcli con add type ethernet con-name "新连接名称" ifname "网卡名称"
```

### 2. 删除连接
```bash
nmcli con del "连接名称"
```

### 3. 激活连接
```bash
nmcli con up "连接名称"
```

### 4. 停用连接
```bash
nmcli con down "连接名称"
```

### 5. 查看连接详细信息
```bash
nmcli con show "连接名称"
```

## 总结

使用 `nmcli connection modify` 命令结合 `connection.id` 属性可以轻松修改 Linux 系统中已有的网络连接名称。正确的命令格式是：

```bash
nmcli con mod "旧连接名称" connection.id "新连接名称"
```

通过这种方式，可以将默认生成的连接名称修改为更直观、更易于管理的名称，提高网络连接管理的效率。