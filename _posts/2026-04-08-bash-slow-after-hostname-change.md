---
layout: post
title: "Bash命令运行缓慢问题分析与修复"
date: 2026-04-08 10:00:00 +0800
categories: [Linux, 系统优化]
tags: [bash, DNS, 主机名, 系统优化]
---

## 问题描述

最近在使用一个自动设置主机名和IP的脚本后，发现bash中运行所有命令都变得特别慢，每次执行命令都需要等待几秒钟。更奇怪的是，只要切换到VPN网络就恢复正常，切换回正常网络又开始变慢。

## 问题分析

通过观察提示符可以发现，主机名部分显示为空：`root@,10.0.0.148:~#`，这表明系统在反向解析主机名时出现了问题。

### 根本原因

1. **主机名未在/etc/hosts中正确绑定**：使用`hostnamectl set-hostname`更改主机名后，没有同步更新`/etc/hosts`文件
2. **DNS服务器不可达**：脚本中硬编码了DNS服务器为`10.0.0.2`，在正常网络下这个地址不可达
3. **Bash命令的解析行为**：每条bash命令都会尝试解析主机名，解析超时导致命令执行缓慢

## 快速定位方法

运行以下命令测试DNS解析是否超时：

```bash
time nslookup ubuntu24-148
time getent hosts ubuntu24-148
```

如果命令执行明显等待2~5秒，说明100%是DNS问题。

## 解决方案

### 1. 修复/etc/hosts文件（最关键）

```bash
cat > /etc/hosts <<EOF
127.0.0.1   localhost
10.0.0.148  ubuntu24-148
::1         ip6-localhost ip6-loopback
fe00::0     ip6-localnet
ff00::0     ip6-mcastprefix
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF
```

### 2. 修改DNS配置，使用公共DNS

```bash
cat > /etc/netplan/50-cloud-init.yaml <<EOF
network:
  version: 2
  ethernets:
    ens33:
      addresses:
        - 10.0.0.148/24
      nameservers:
        addresses:
          - 127.0.0.53
          - 223.5.5.5
          - 8.8.8.8
      routes:
        - to: default
          via: 10.0.0.2
EOF

chmod 600 /etc/netplan/50-cloud-init.yaml
netplan apply
```

### 3. 检查主机名解析

```bash
hostname
hostname -f
getent hosts $(hostname)
```

这三条命令应该瞬间返回，不再卡顿。

### 4. 彻底关闭bash反向解析（可选）

编辑全局bash配置，禁止每次命令都去解析主机名：

```bash
echo 'export HOSTNAME=$(hostname)' >> /etc/profile
echo 'export PROMPT_COMMAND=""' >> /etc/profile
source /etc/profile
exec bash
```

## 调试命令

### 跟踪DNS调用

```bash
strace -e trace=hostname,socket,sendto getent hosts $(hostname)
```

### 查看DNS超时时间

```bash
time resolvectl query $(hostname)
```

## 优化脚本

为了防止以后出现同样的问题，建议在设置主机名的脚本中添加自动更新hosts的逻辑，并检查网卡名称：

```bash
#!/bin/bash
# *************************************
# * 功能: 设定主机名和主机ip
# * 作者: 钟翼翔
# * 联系: clockwingsoar@outlook.com
# * 版本: 2026-4-08
# *************************************
set -e # 遇到错误立即退出

# 1. 提示用户输入IP地址（仅需输入最后一段，如147）
read -p "请输入10.0.0.0/24网段的IP最后一段（如147）：" IP_LAST
IP_FULL="10.0.0.${IP_LAST}"
HOSTNAME="ubuntu24-${IP_LAST}"

# 2. 设置主机名
echo "正在设置主机名为：${HOSTNAME}"
hostnamectl set-hostname "${HOSTNAME}"

# 3. 更新/etc/hosts文件（关键修复）
echo "正在更新/etc/hosts文件"
echo "127.0.0.1 localhost ${HOSTNAME}" > /etc/hosts
echo "::1 localhost ${HOSTNAME}" >> /etc/hosts

# 4. 自动获取当前默认网卡名（防止ens33不存在的情况）
NIC_NAME=$(ip route | grep default | awk '{print $5}' | head -n1)
: ${NIC_NAME:=ens33} # 如果没搜到则默认为ens33

echo "检测到网卡名：${NIC_NAME}"

# 5. 定制apt源
rm -rf /etc/apt/sources.list.d/*
cat > /etc/apt/sources.list <<-eof
deb https://mirrors.aliyun.com/ubuntu/ noble main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ noble-security main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ noble-updates main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ noble-backports main restricted universe multiverse
eof

# 6. 生成新的netplan配置（网关默认用10.0.0.2，可根据实际修改）
rm -rf /etc/netplan/*
NETPLAN_FILE="/etc/netplan/50-cloud-init.yaml"
echo "正在生成netplan网络配置（IP：${IP_FULL}/24）"
cat > "${NETPLAN_FILE}" << EOF
network:
  version: 2
  ethernets:
    ${NIC_NAME}: # 使用自动检测的网卡名
      addresses:
        - "${IP_FULL}/24"
      nameservers:
        addresses:
          - 127.0.0.53
          - 223.5.5.5
          - 8.8.8.8
      routes:
        - to: default
          via: 10.0.0.2 # 网关地址可根据实际修改
EOF
chmod 600 "${NETPLAN_FILE}"

# 7. 应用netplan配置并验证
echo "正在应用网络配置..."
netplan apply
> ~/.bash_history

# 8. 验证结果
echo -e "\n配置完成！当前信息："
echo "主机名：$(hostname)"
echo "IP地址：$(hostname -I)"
echo "网卡名：${NIC_NAME}"

# 9. 测试主机名解析
echo -e "\n测试主机名解析："
time getent hosts $(hostname)

rm -f $0 && echo "脚本已成功自我删除"
```

## 总结

Bash命令运行缓慢的根本原因是：**主机名未在hosts中正确绑定 + DNS服务器外网不可达 → bash每次解析主机名超时**。

通过以上修复步骤，可以立即恢复bash的正常运行速度。特别是在脚本中添加自动更新hosts的逻辑，可以从根本上避免这个问题的发生。

希望这篇文章能帮助到遇到类似问题的朋友！