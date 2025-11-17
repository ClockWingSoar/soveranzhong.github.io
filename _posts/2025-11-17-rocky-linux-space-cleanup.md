---
layout: post
title: "Rocky Linux系统空间清理指南 - 解决根分区满导致的安装失败"
date: 2025-11-17 12:00:00
categories: linux
tags: [rocky-linux, 系统维护, 空间清理]
---

# Rocky Linux系统空间清理指南 - 解决根分区满导致的安装失败

## 情境与问题

作为SRE工程师，我们经常需要在Linux系统上安装各种软件包进行开发和维护工作。今天在Rocky Linux 9.6系统上执行`yum groupinstall "Development Tools" "System Tools"`时，遇到了一个常见但棘手的问题：

```bash
[Errno 2] No usable temporary directory found in ['/tmp', '/var/tmp', '/usr/tmp', '/root']
```

通过`df -h`命令检查发现，根分区(`/dev/mapper/rl-root`)已使用100%：

```bash
文件系统             容量  已用  可用 已用% 挂载点
devtmpfs             4.0M     0  4.0M    0% /dev
tmpfs                1.8G     0  1.8G    0% /dev/shm
tmpfs                725M  9.6M  716M    2% /run
/dev/mapper/rl-root   70G   70G   20K  100% /
/dev/sda1            960M  598M  363M   63% /boot
/dev/mapper/rl-home  126G  1.1G  124G    1% /home
```

这是一个典型的Linux系统空间耗尽问题。本文将详细介绍如何分析系统空间占用情况，并提供一套完整的清理方案。

## 空间占用分析

在进行清理之前，我们需要先了解系统空间的占用情况，找出占用空间最多的文件和目录。

### 1. 检查分区使用情况

```bash
# 查看所有分区的使用情况
df -h

# 查看inode使用情况（有时inode耗尽也会导致空间问题）
df -i
```

### 2. 查找大目录

使用`du`命令查找占用空间最多的目录：

```bash
# 查找根目录下占用空间最多的前10个目录
du -h --max-depth=1 / | sort -hr | head -10

# 查找特定目录下的大文件
du -h /var | sort -hr | head -20
```

### 3. 使用ncdu进行交互式分析

`ncdu`是一个更友好的交互式磁盘使用分析工具：

```bash
# 安装ncdu
yum install -y ncdu

# 分析根目录
ncdu /
```

## 系统空间清理策略

根据空间分析结果，我们可以采取以下策略进行针对性清理：

### 1. 清理包管理器缓存

YUM/DNF会在`/var/cache/dnf`或`/var/cache/yum`目录下缓存大量的RPM包：

```bash
# 清理所有缓存的包
dnf clean all
# 或 yum clean all

# 只清理旧版本的包缓存
dnf clean packages
```

### 2. 删除旧的内核版本

Linux系统会保留多个内核版本，占用大量空间：

```bash
# 查看已安装的内核版本
rpm -q kernel

# 查看当前使用的内核
uname -r

# 删除旧内核（保留当前和最新的一个）
dnf remove -y $(rpm -q kernel | grep -v $(uname -r) | head -n -1)
```

### 3. 清理日志文件

系统日志文件通常存放在`/var/log`目录下，可能会变得非常大：

```bash
# 查看大日志文件
find /var/log -type f -size +100M

# 安全清理旧日志（保留最新的）
journalctl --vacuum-time=2weeks

# 清理特定服务的旧日志
rm -f /var/log/nginx/access.log-*
rm -f /var/log/httpd/access_log-*
```

### 4. 清理临时文件

临时文件存放在`/tmp`、`/var/tmp`等目录：

```bash
# 清理30天前的临时文件
find /tmp -type f -mtime +30 -delete
find /var/tmp -type f -mtime +30 -delete

# 清理系统d目录中的过时文件
rm -rf /var/spool/abrt/*
rm -rf /var/spool/cron/*
```

### 5. 查找并清理大文件

```bash
# 查找根目录下大于100MB的文件
find / -type f -size +100M -exec ls -lh {} \;

# 查找并清理特定类型的大文件（如ISO、压缩包等）
find /home -name "*.iso" -o -name "*.tar.gz" -o -name "*.zip" | xargs ls -lh
```

### 6. 清理Docker容器和镜像

如果系统上运行了Docker，可能会有大量未使用的容器和镜像：

```bash
# 清理未使用的容器、镜像和卷
docker system prune -a -f

# 查看Docker占用空间
docker system df
```

### 7. 清理用户家目录

用户家目录中可能存在大量临时文件和下载内容：

```bash
# 清理每个用户的下载目录
find /home -name "Downloads" -type d -exec du -sh {} \;

# 清理浏览器缓存
rm -rf /home/*/.cache/google-chrome/*
rm -rf /home/*/.mozilla/firefox/*/Cache/*
```

## 自动化清理脚本

为了方便定期清理，我们可以创建一个自动化脚本：

```bash
#!/bin/bash
# 系统空间自动化清理脚本

# 设置日志文件
LOG_FILE="/var/log/system_cleanup.log"
echo "$(date) - 开始系统清理" >> $LOG_FILE

# 1. 清理包管理器缓存
echo "$(date) - 清理包管理器缓存" >> $LOG_FILE
dnf clean all >> $LOG_FILE 2>&1

# 2. 删除旧内核
echo "$(date) - 删除旧内核" >> $LOG_FILE
CURRENT_KERNEL=$(uname -r)
OLD_KERNELS=$(rpm -q kernel | grep -v $CURRENT_KERNEL | head -n -1)
if [ -n "$OLD_KERNELS" ]; then
    dnf remove -y $OLD_KERNELS >> $LOG_FILE 2>&1
else
    echo "$(date) - 没有旧内核需要删除" >> $LOG_FILE
fi

# 3. 清理日志文件
echo "$(date) - 清理系统日志" >> $LOG_FILE
journalctl --vacuum-time=2weeks >> $LOG_FILE 2>&1

# 4. 清理临时文件
echo "$(date) - 清理临时文件" >> $LOG_FILE
find /tmp -type f -mtime +30 -delete
find /var/tmp -type f -mtime +30 -delete

# 5. 显示清理后的空间使用情况
echo "$(date) - 清理完成，当前空间使用情况：" >> $LOG_FILE
df -h >> $LOG_FILE 2>&1

echo "$(date) - 系统清理结束" >> $LOG_FILE
```

将脚本保存为`/usr/local/bin/system_cleanup.sh`，并设置执行权限：

```bash
chmod +x /usr/local/bin/system_cleanup.sh
```

可以使用`cron`设置定期执行：

```bash
# 每周日凌晨2点执行清理
crontab -e
0 2 * * 0 /usr/local/bin/system_cleanup.sh
```

## 预防措施

1. **监控系统空间**：使用Prometheus + Grafana或Nagios等工具监控分区使用情况，设置阈值告警

2. **合理规划分区**：安装系统时为根分区分配足够的空间，或使用LVM动态扩展分区

3. **定期清理**：设置自动化脚本定期清理系统垃圾

4. **使用日志轮转**：确保日志文件正确配置了轮转策略

5. **限制Docker资源**：为Docker设置合理的存储限制，定期清理未使用的资源

## 总结

系统空间耗尽是Linux系统维护中常见的问题，通过本文介绍的分析和清理方法，可以快速定位并解决空间问题。关键在于：

1. 使用合适的工具分析空间占用情况
2. 针对性地清理不同类型的垃圾文件
3. 建立自动化清理机制
4. 实施预防措施避免问题再次发生

希望本文能帮助你有效管理Rocky Linux系统空间，确保系统稳定运行。