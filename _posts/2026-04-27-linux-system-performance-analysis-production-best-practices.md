---
layout: post
title: "Linux系统性能分析生产环境最佳实践：从CPU到内存"
date: 2026-04-27 09:00:00
categories: [SRE, Linux, 性能优化]
tags: [Linux, 性能分析, CPU, 内存, 磁盘, 网络, 运维]
---

# Linux系统性能分析生产环境最佳实践：从CPU到内存

## 情境(Situation)

在生产环境中，系统性能问题是SRE工程师经常面临的挑战。多核系统中，**CPU负载往往不均衡**，只看平均CPU使用率会掩盖"单核心跑满，其他核心空闲"的问题。快速定位性能瓶颈，是保障服务稳定性和用户体验的关键。

作为SRE工程师，掌握系统性能分析工具和方法，能够在故障发生时快速定位问题，在性能下降时及时优化，是必备的核心技能。

## 冲突(Conflict)

许多SRE工程师在系统性能分析中遇到以下挑战：

- **定位困难**：无法快速确定性能瓶颈所在（CPU、内存、磁盘或网络）
- **工具使用**：不熟悉各种性能分析工具的使用方法
- **分析方法**：缺乏系统化的性能分析流程
- **优化策略**：不知道如何根据分析结果制定优化方案
- **监控缺失**：缺乏有效的性能监控和告警机制

## 问题(Question)

如何在生产环境中高效进行系统性能分析，快速定位瓶颈，制定有效的优化策略？

## 答案(Answer)

本文将从SRE视角出发，结合真实生产案例，提供一套完整的Linux系统性能分析生产环境最佳实践。核心方法论基于 [SRE面试题解析：top命令中如何显示单独的CPU数据？]({% post_url 2026-04-15-sre-interview-questions %}#20-top命令中如何显示单独的cpu数据)。

---

## 一、CPU性能分析

### 1.1 top命令详解

**基本用法**：

```bash
# 启动top
top

# 显示单独CPU数据（按数字1）
top -1

# 批处理模式（适合脚本）
top -n 1 -b | head -20

# 按CPU使用率排序
top -o %CPU

# 显示指定进程
top -p <PID1>,<PID2>

# 显示线程
top -H
```

**top界面解析**：

```
top - 10:00:00 up 10 days,  2:34,  1 user,  load average: 0.65, 0.42, 0.36
Tasks: 123 total,   1 running, 122 sleeping,   0 stopped,   0 zombie
%Cpu0  :  2.0 us,  1.0 sy,  0.0 ni, 96.0 id,  1.0 wa,  0.0 hi,  0.0 si,  0.0 st
%Cpu1  :  3.0 us,  2.0 sy,  0.0 ni, 94.0 id,  1.0 wa,  0.0 hi,  0.0 si,  0.0 st
KiB Mem :  8192000 total,  4096000 free,  2048000 used,  2048000 buff/cache
KiB Swap:  4096000 total,  4096000 free,        0 used.  5632000 avail Mem 

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND
1234 root      20   0  204800  51200  25600 S   5.0  0.6   0:30.00 nginx
5678 mysql     20   0 1048576 262144  65536 S   2.5  3.2   1:20.00 mysqld
```

**CPU字段含义**：

| 字段 | 含义 | 关注重点 | 可能原因 |
|:-----|:-----|:---------|:---------|
| **us** | 用户态CPU使用率 | 应用程序消耗 | 应用逻辑复杂 |
| **sy** | 系统态CPU使用率 | 内核消耗 | 系统调用频繁 |
| **ni** | nice调整的CPU使用率 | 低优先级进程 | 进程优先级设置 |
| **id** | 空闲CPU百分比 | 系统空闲程度 | 系统负载低 |
| **wa** | I/O等待CPU使用率 | 磁盘/网络瓶颈 | 磁盘I/O繁忙 |
| **hi** | 硬中断CPU使用率 | 硬件中断 | 硬件设备活动 |
| **si** | 软中断CPU使用率 | 软件中断 | 网络数据包处理 |
| **st** | 被虚拟机窃取的CPU | 虚拟化环境 | 宿主机负载高 |

**top快捷键**：

| 快捷键 | 功能 | 说明 |
|:-------|:-----|:------|
| `1` | 显示/隐藏单个CPU数据 | 切换多CPU视图 |
| `t` | 切换CPU显示格式 | 显示/隐藏CPU统计 |
| `P` | 按CPU使用率排序 | 找出CPU密集型进程 |
| `M` | 按内存使用率排序 | 找出内存密集型进程 |
| `c` | 显示完整命令路径 | 查看进程详细信息 |
| `k` | 终止某个进程 | 输入PID终止进程 |
| `r` | 重新设置进程优先级 | 调整进程nice值 |
| `H` | 显示线程 | 查看进程的线程 |
| `u` | 显示指定用户进程 | 过滤用户进程 |
| `q` | 退出top | 退出命令 |

### 1.2 其他CPU分析工具

**htop**：

```bash
# 安装htop
apt install htop  # Debian/Ubuntu
yum install htop  # CentOS/RHEL

# 启动htop
htop

# 快捷键
# F1: 帮助
# F2: 设置
# F3: 搜索
# F4: 过滤器
# F5: 树状视图
# F6: 排序
# F7: 降低优先级
# F8: 提高优先级
# F9: 终止进程
# F10: 退出
```

**mpstat**：

```bash
# 安装sysstat
apt install sysstat  # Debian/Ubuntu
yum install sysstat  # CentOS/RHEL

# 查看所有CPU
mpstat -P ALL 1

# 输出示例
08:00:00 AM  CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
08:00:01 AM  all    2.00    0.00    1.50    0.50    0.00    0.00    0.00    0.00    0.00   96.00
08:00:01 AM    0    1.00    0.00    1.00    1.00    0.00    0.00    0.00    0.00    0.00   97.00
08:00:01 AM    1    3.00    0.00    2.00    0.00    0.00    0.00    0.00    0.00    0.00   95.00
```

**pidstat**：

```bash
# 查看进程CPU使用情况
pidstat -u 1

# 查看线程CPU使用情况
pidstat -t -u 1

# 查看指定进程
pidstat -p <PID> 1
```

**sar**：

```bash
# 查看CPU使用情况
sar -u 1 5

# 查看单个CPU
sar -P ALL 1 5

# 查看历史数据
sar -u -f /var/log/sysstat/sa15
```

### 1.3 CPU瓶颈分析

**常见CPU瓶颈**：

| 现象 | 可能原因 | 解决方案 |
|:-----|:---------|:----------|
| **us高** | 应用程序计算密集 | 优化应用算法，增加CPU核心 |
| **sy高** | 系统调用频繁 | 减少系统调用，优化内核参数 |
| **wa高** | I/O等待 | 优化磁盘I/O，使用SSD |
| **hi/si高** | 中断频繁 | 检查硬件设备，优化网络配置 |
| **st高** | 虚拟机资源不足 | 增加虚拟机资源，优化宿主机 |

**分析流程**：

1. **识别瓶颈CPU**：使用top -1查看各核心负载
2. **定位问题进程**：使用top按CPU排序
3. **分析进程行为**：使用pidstat查看进程详细情况
4. **检查系统调用**：使用strace跟踪系统调用
5. **优化处理**：根据分析结果进行优化

**实战案例**：

```bash
# 1. 查看CPU使用情况
top -1

# 2. 发现CPU0使用率高，定位进程
top -o %CPU

# 3. 查看进程详细信息
pidstat -p <PID> 1

# 4. 跟踪系统调用
strace -p <PID> -c

# 5. 查看进程线程
pstree -p <PID>
top -H -p <PID>
```

---

## 二、内存性能分析

### 2.1 内存分析工具

**free**：

```bash
# 查看内存使用情况
free -h

# 输出示例
              total        used        free      shared  buff/cache   available
Mem:           7.8G        2.0G        4.0G        100M        1.8G        5.5G
Swap:          4.0G          0B        4.0G
```

**vmstat**：

```bash
# 查看虚拟内存统计
vmstat 1

# 输出示例
procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu----- 
r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
0  0      0 4194304  524288 1887436    0    0     0     0  100  200  2  1 97  0  0
```

**pmap**：

```bash
# 查看进程内存映射
pmap -x <PID>

# 查看进程内存使用摘要
pmap -x <PID> | tail -1
```

**smem**：

```bash
# 安装smem
apt install smem  # Debian/Ubuntu
yum install smem  # CentOS/RHEL

# 查看进程内存使用
smem -t -k

# 按用户查看内存使用
smem -u -k
```

### 2.2 内存瓶颈分析

**常见内存问题**：

| 现象 | 可能原因 | 解决方案 |
|:-----|:---------|:----------|
| **内存使用率高** | 应用内存泄漏 | 检查应用代码，使用内存分析工具 |
| **swap使用频繁** | 内存不足 | 增加内存，优化应用内存使用 |
| **OOM killer** | 内存耗尽 | 增加内存，调整OOM配置 |
| **缓存占用高** | 文件系统缓存 | 正常现象，可通过drop_caches释放 |

**分析流程**：

1. **查看内存使用**：使用free -h查看整体内存情况
2. **定位内存密集进程**：使用top按内存排序
3. **分析进程内存**：使用pmap查看进程内存映射
4. **检查swap使用**：使用vmstat查看swap活动
5. **优化处理**：根据分析结果进行优化

**实战案例**：

```bash
# 1. 查看内存使用情况
free -h

# 2. 定位内存密集进程
top -o %MEM

# 3. 查看进程内存映射
pmap -x <PID>

# 4. 查看swap使用情况
vmstat 1

# 5. 清理缓存（谨慎使用）
sync && echo 3 > /proc/sys/vm/drop_caches
```

---

## 三、磁盘I/O性能分析

### 3.1 磁盘I/O分析工具

**iostat**：

```bash
# 查看磁盘I/O统计
iostat -x 1

# 输出示例
device             r/s     w/s     rkB/s     wkB/s avgrq-sz avgqu-sz   await r_await w_await  svctm  %util
nvme0n1           0.00    0.00      0.00      0.00     0.00     0.00    0.00    0.00    0.00   0.00   0.00
sda               2.00    1.00     16.00      8.00    16.00     0.01    3.33    4.00    2.00   2.00   0.60
```

**iotop**：

```bash
# 安装iotop
apt install iotop  # Debian/Ubuntu
yum install iotop  # CentOS/RHEL

# 启动iotop

iotop

# 查看磁盘写入最活跃的进程

iotop -o -P
```

**df**：

```bash
# 查看磁盘使用情况
df -h

# 查看inode使用情况
df -i
```

**du**：

```bash
# 查看目录大小
du -sh /path/to/directory

# 查看目录下文件大小
du -h --max-depth=1 /path/to/directory
```

### 3.2 磁盘I/O瓶颈分析

**常见磁盘I/O问题**：

| 现象 | 可能原因 | 解决方案 |
|:-----|:---------|:----------|
| **高iowait** | 磁盘I/O繁忙 | 优化磁盘，使用SSD，调整I/O调度 |
| **高await** | I/O响应时间长 | 优化应用I/O模式，使用RAID |
| **高%util** | 磁盘利用率高 | 增加磁盘，优化I/O操作 |
| **磁盘空间不足** | 文件系统满 | 清理空间，扩展磁盘 |

**分析流程**：

1. **查看磁盘I/O**：使用iostat -x查看磁盘性能
2. **定位I/O密集进程**：使用iotop查看进程I/O
3. **检查磁盘空间**：使用df -h查看磁盘使用
4. **分析文件大小**：使用du查看大文件
5. **优化处理**：根据分析结果进行优化

**实战案例**：

```bash
# 1. 查看磁盘I/O情况
iostat -x 1

# 2. 定位I/O密集进程

iotop

# 3. 查看磁盘空间
df -h

# 4. 查找大文件
du -h --max-depth=1 / | sort -hr | head -10

# 5. 查看I/O调度策略
cat /sys/block/sda/queue/scheduler

# 6. 调整I/O调度策略（临时）
echo deadline > /sys/block/sda/queue/scheduler
```

---

## 四、网络性能分析

### 4.1 网络分析工具

**netstat**：

```bash
# 查看网络连接
netstat -tunlp

# 查看监听端口
netstat -tunlp | grep LISTEN

# 查看已建立的连接
netstat -tun | grep ESTABLISHED
```

**ss**：

```bash
# 查看网络连接
ss -tunlp

# 查看监听端口
ss -tunlp | grep LISTEN

# 查看已建立的连接
ss -tun | grep ESTABLISHED

# 统计连接状态
ss -s
```

**iftop**：

```bash
# 安装iftop
apt install iftop  # Debian/Ubuntu
yum install iftop  # CentOS/RHEL

# 启动iftop
iftop -i eth0
```

**nethogs**：

```bash
# 安装nethogs
apt install nethogs  # Debian/Ubuntu
yum install nethogs  # CentOS/RHEL

# 启动nethogs
nethogs eth0
```

**ping**：

```bash
# 测试网络连通性
ping google.com

# 测试网络延迟
ping -c 5 google.com
```

**traceroute**：

```bash
# 跟踪网络路径
traceroute google.com

# 使用TCP跟踪
traceroute -T -p 80 google.com
```

**tcpdump**：

```bash
# 抓包分析
tcpdump -i eth0 port 80

# 保存抓包
tcpdump -i eth0 -w capture.pcap

# 分析抓包
tcpdump -r capture.pcap
```

### 4.2 网络瓶颈分析

**常见网络问题**：

| 现象 | 可能原因 | 解决方案 |
|:-----|:---------|:----------|
| **网络延迟高** | 网络拥塞，路由问题 | 检查网络拓扑，优化路由 |
| **丢包率高** | 网络质量差，硬件问题 | 检查网络设备，更换网线 |
| **带宽不足** | 流量过大 | 增加带宽，优化流量 |
| **连接数过多** | 应用连接管理不当 | 优化连接池，调整内核参数 |

**分析流程**：

1. **查看网络连接**：使用ss查看连接状态
2. **监控网络流量**：使用iftop查看流量情况
3. **定位流量进程**：使用nethogs查看进程流量
4. **测试网络连通**：使用ping和traceroute测试
5. **抓包分析**：使用tcpdump进行深入分析
6. **优化处理**：根据分析结果进行优化

**实战案例**：

```bash
# 1. 查看网络连接状态
ss -s

# 2. 监控网络流量
iftop -i eth0

# 3. 定位流量进程
nethogs eth0

# 4. 测试网络延迟
ping -c 5 google.com

# 5. 跟踪网络路径
traceroute google.com

# 6. 抓包分析
tcpdump -i eth0 port 80 -c 100
```

---

## 五、系统整体性能分析

### 5.1 综合分析工具

**Glances**：

```bash
# 安装Glances
pip install glances

# 启动Glances
glances

# Web界面
glances -w
# 访问 http://localhost:61208
```

**dstat**：

```bash
# 安装dstat
apt install dstat  # Debian/Ubuntu
yum install dstat  # CentOS/RHEL

# 启动dstat
dstat

# 查看CPU、内存、磁盘、网络
dstat -cdngy
```

**collectl**：

```bash
# 安装collectl
apt install collectl  # Debian/Ubuntu
yum install collectl  # CentOS/RHEL

# 启动collectl
collectl

# 查看CPU和内存
collectl -scm
```

### 5.2 性能分析流程

**标准分析流程**：

1. **整体状态检查**：
   - 使用top查看系统整体状态
   - 使用free查看内存使用
   - 使用df查看磁盘空间
   - 使用ss查看网络连接

2. **CPU分析**：
   - 使用top -1查看各核心负载
   - 使用mpstat查看CPU详细统计
   - 使用pidstat查看进程CPU使用

3. **内存分析**：
   - 使用free -h查看内存使用
   - 使用vmstat查看虚拟内存
   - 使用pmap查看进程内存

4. **磁盘I/O分析**：
   - 使用iostat -x查看磁盘I/O
   - 使用iotop查看进程I/O
   - 使用df和du查看磁盘空间

5. **网络分析**：
   - 使用ss查看网络连接
   - 使用iftop查看网络流量
   - 使用ping和traceroute测试网络

6. **综合分析**：
   - 分析各子系统之间的关系
   - 定位瓶颈所在
   - 制定优化方案

**性能分析脚本**：

```bash
#!/bin/bash
# system_perf_analyzer.sh - 系统性能分析脚本

OUTPUT_FILE="system_perf_analysis_$(date +%Y%m%d_%H%M%S).txt"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$OUTPUT_FILE"
}

header() {
    echo "\n=======================================" >> "$OUTPUT_FILE"
    echo "$*" >> "$OUTPUT_FILE"
    echo "=======================================" >> "$OUTPUT_FILE"
}

main() {
    echo "系统性能分析报告" > "$OUTPUT_FILE"
    echo "分析时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$OUTPUT_FILE"
    
    header "1. 系统基本信息"
    log "主机名: $(hostname)"
    log "内核版本: $(uname -r)"
    log "CPU核心数: $(nproc)"
    log "总内存: $(free -h | grep Mem | awk '{print $2}')"
    
    header "2. CPU使用情况"
    log "top命令输出:"
    top -n 1 -b | head -20 >> "$OUTPUT_FILE"
    
    header "3. 内存使用情况"
    log "free命令输出:"
    free -h >> "$OUTPUT_FILE"
    
    header "4. 磁盘使用情况"
    log "df命令输出:"
    df -h >> "$OUTPUT_FILE"
    
    header "5. 磁盘I/O情况"
    log "iostat命令输出:"
    iostat -x 1 3 >> "$OUTPUT_FILE"
    
    header "6. 网络连接情况"
    log "ss命令输出:"
    ss -s >> "$OUTPUT_FILE"
    log "监听端口:"
    ss -tunlp | grep LISTEN >> "$OUTPUT_FILE"
    
    header "7. 进程状态"
    log "CPU使用率Top 10:"
    ps aux --sort=-%cpu | head -11 >> "$OUTPUT_FILE"
    log "\n内存使用率Top 10:"
    ps aux --sort=-%mem | head -11 >> "$OUTPUT_FILE"
    
    echo "\n分析完成，报告已保存到: $OUTPUT_FILE"
}

main
```

---

## 六、性能优化最佳实践

### 6.1 CPU优化

**内核参数优化**：

```bash
# 临时调整
sysctl -w kernel.sched_autogroup_enabled=0  # 禁用自动分组
sysctl -w kernel.sched_migration_cost_ns=500000  # 调整迁移成本
sysctl -w kernel.sched_min_granularity_ns=1000000  # 调整时间片粒度

# 永久调整
cat >> /etc/sysctl.conf << EOF
# CPU调度优化
kernel.sched_autogroup_enabled = 0
kernel.sched_migration_cost_ns = 500000
kernel.sched_min_granularity_ns = 1000000
EOF

# 应用配置
sysctl -p
```

**进程优化**：

```bash
# 调整进程优先级
renice -n -5 <PID>  # 提高优先级
renice -n 10 <PID>  # 降低优先级

# CPU绑定
taskset -c 0,1 <command>  # 绑定到0和1核心
taskset -p 0x3 <PID>  # 绑定到0和1核心（十六进制）

# 查看进程CPU绑定
ps -o pid,psr -p <PID>
```

**应用优化**：
- 优化算法和数据结构
- 使用多线程/多进程
- 减少系统调用
- 使用异步I/O
- 避免死锁和竞态条件

### 6.2 内存优化

**内核参数优化**：

```bash
# 临时调整
sysctl -w vm.swappiness=10  # 减少swap使用
sysctl -w vm.overcommit_memory=1  # 允许过量分配
sysctl -w vm.dirty_background_ratio=5  # 后台脏页比例
sysctl -w vm.dirty_ratio=10  # 脏页比例

# 永久调整
cat >> /etc/sysctl.conf << EOF
# 内存管理优化
vm.swappiness = 10
vm.overcommit_memory = 1
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
EOF

# 应用配置
sysctl -p
```

**应用优化**：
- 合理使用缓存
- 避免内存泄漏
- 使用内存池
- 优化数据结构
- 减少内存碎片

### 6.3 磁盘I/O优化

**内核参数优化**：

```bash
# 临时调整
sysctl -w vm.dirty_background_ratio=5
sysctl -w vm.dirty_ratio=10
sysctl -w vm.dirty_expire_centisecs=3000
sysctl -w vm.dirty_writeback_centisecs=500

# 永久调整
cat >> /etc/sysctl.conf << EOF
# 磁盘I/O优化
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 500
EOF

# 应用配置
sysctl -p
```

**I/O调度优化**：

```bash
# 查看当前调度策略
cat /sys/block/sda/queue/scheduler

# 临时调整调度策略
echo deadline > /sys/block/sda/queue/scheduler  # 适合数据库
echo cfq > /sys/block/sda/queue/scheduler      # 适合通用场景
echo noop > /sys/block/sda/queue/scheduler      # 适合SSD

# 永久调整（Ubuntu）
cat >> /etc/udev/rules.d/60-scheduler.rules << EOF
ACTION=="add|change", KERNEL=="sd*", ATTR{queue/scheduler}="deadline"
EOF
```

**应用优化**：
- 使用SSD
- 优化文件系统
- 使用RAID
- 批量I/O操作
- 避免随机I/O

### 6.4 网络优化

**内核参数优化**：

```bash
# 临时调整
sysctl -w net.core.somaxconn=65535
sysctl -w net.ipv4.tcp_max_syn_backlog=65535
sysctl -w net.ipv4.tcp_fin_timeout=30
sysctl -w net.ipv4.tcp_keepalive_time=600
sysctl -w net.ipv4.tcp_keepalive_probes=3
sysctl -w net.ipv4.tcp_keepalive_intvl=15
sysctl -w net.core.netdev_max_backlog=65535
sysctl -w net.ipv4.tcp_fastopen=3

# 永久调整
cat >> /etc/sysctl.conf << EOF
# 网络优化
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl = 15
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_fastopen = 3
EOF

# 应用配置
sysctl -p
```

**应用优化**：
- 使用长连接
- 实现连接池
- 优化网络协议
- 使用CDN
- 压缩数据传输

---

## 七、监控与告警

### 7.1 性能监控

**Prometheus + Grafana**：

```yaml
# node_exporter 配置
scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']

# 告警规则
groups:
  - name: system_alerts
    rules:
    - alert: HighCpuUsage
      expr: (100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 90
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "高CPU使用率"
        description: "{{ "{{" }} $labels.instance }} CPU使用率超过90%持续5分钟"

    - alert: HighMemoryUsage
      expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 90
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "高内存使用率"
        description: "{{ "{{" }} $labels.instance }} 内存使用率超过90%持续5分钟"

    - alert: DiskSpaceLow
      expr: (node_filesystem_size_bytes{mountpoint="/"} - node_filesystem_free_bytes{mountpoint="/"}) / node_filesystem_size_bytes{mountpoint="/"} * 100 > 85
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "磁盘空间不足"
        description: "{{ "{{" }} $labels.instance }} 根分区使用率超过85%持续10分钟"

    - alert: HighIoWait
      expr: avg by(instance) (irate(node_cpu_seconds_total{mode="iowait"}[5m])) * 100 > 30
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "高I/O等待"
        description: "{{ "{{" }} $labels.instance }} I/O等待超过30%持续5分钟"
```

**Zabbix监控**：

1. **创建模板**：
   - 配置 → 模板 → 创建模板
   - 名称：Linux Performance

2. **添加监控项**：
   - CPU使用率：system.cpu.util[,idle]
   - 内存使用率：vm.memory.size[used_percent]
   - 磁盘使用率：vfs.fs.size[/,pused]
   - 磁盘I/O：vfs.dev.read[/dev/sda,ops]
   - 网络流量：net.if.in[eth0]

3. **添加触发器**：
   - CPU使用率 > 90%
   - 内存使用率 > 90%
   - 磁盘使用率 > 85%
   - I/O等待 > 30%

### 7.2 告警阈值

| 指标 | 告警级别 | 阈值 | 持续时间 |
|:-----|:---------|:------|:----------|
| **CPU使用率** | 警告 | > 80% | 5分钟 |
| | 严重 | > 90% | 5分钟 |
| **内存使用率** | 警告 | > 80% | 5分钟 |
| | 严重 | > 90% | 5分钟 |
| **磁盘使用率** | 警告 | > 80% | 10分钟 |
| | 严重 | > 90% | 10分钟 |
| **I/O等待** | 警告 | > 20% | 5分钟 |
| | 严重 | > 30% | 5分钟 |
| **网络流量** | 警告 | > 80%带宽 | 10分钟 |
| | 严重 | > 90%带宽 | 10分钟 |

---

## 八、最佳实践总结

### 8.1 性能分析工具汇总

| 类别 | 工具 | 用途 | 推荐指数 |
|:-----|:-----|:-----|:---------|
| **CPU分析** | top | 实时CPU监控 | ⭐⭐⭐ |
| | htop | 交互式CPU监控 | ⭐⭐⭐ |
| | mpstat | CPU详细统计 | ⭐⭐⭐ |
| | pidstat | 进程CPU分析 | ⭐⭐⭐ |
| | sar | 历史CPU数据 | ⭐⭐⭐ |
| **内存分析** | free | 内存使用概览 | ⭐⭐⭐ |
| | vmstat | 虚拟内存统计 | ⭐⭐⭐ |
| | pmap | 进程内存映射 | ⭐⭐⭐ |
| | smem | 内存使用分析 | ⭐⭐⭐ |
| **磁盘I/O分析** | iostat | 磁盘I/O统计 | ⭐⭐⭐ |
| | iotop | 进程I/O监控 | ⭐⭐⭐ |
| | df | 磁盘空间使用 | ⭐⭐⭐ |
| | du | 目录大小分析 | ⭐⭐⭐ |
| **网络分析** | ss | 网络连接状态 | ⭐⭐⭐ |
| | iftop | 网络流量监控 | ⭐⭐⭐ |
| | nethogs | 进程流量分析 | ⭐⭐⭐ |
| | ping | 网络连通性测试 | ⭐⭐⭐ |
| | traceroute | 网络路径跟踪 | ⭐⭐⭐ |
| | tcpdump | 网络抓包分析 | ⭐⭐⭐ |
| **综合分析** | Glances | 综合系统监控 | ⭐⭐⭐ |
| | dstat | 多维度统计 | ⭐⭐⭐ |
| | collectl | 系统资源收集 | ⭐⭐⭐ |

### 8.2 性能分析方法论

**核心原则**：
- **系统性**：从整体到局部，综合分析各子系统
- **实时性**：及时发现和解决性能问题
- **持续性**：建立长期性能监控机制
- **数据驱动**：基于数据进行分析和优化
- **循序渐进**：逐步定位和解决问题

**分析步骤**：
1. **观察现象**：发现性能异常
2. **收集数据**：使用工具收集性能数据
3. **分析数据**：识别瓶颈所在
4. **制定方案**：根据分析结果制定优化方案
5. **实施优化**：执行优化措施
6. **验证效果**：验证优化效果
7. **持续监控**：建立长期监控机制

### 8.3 常见性能问题与解决方案

| 问题 | 症状 | 解决方案 |
|:-----|:-----|:----------|
| **CPU瓶颈** | CPU使用率高，响应缓慢 | 优化应用算法，增加CPU核心，调整进程优先级 |
| **内存不足** | 内存使用率高，swap频繁使用 | 增加内存，优化应用内存使用，调整内存参数 |
| **磁盘I/O瓶颈** | I/O等待高，磁盘利用率高 | 使用SSD，优化I/O调度，调整应用I/O模式 |
| **网络瓶颈** | 网络延迟高，丢包率高 | 优化网络配置，增加带宽，使用CDN |
| **进程阻塞** | 进程状态异常，响应缓慢 | 检查进程状态，排查死锁和竞态条件 |
| **系统负载高** | 系统负载超过CPU核心数 | 分析负载来源，优化应用，增加资源 |

---

## 总结

Linux系统性能分析是SRE工程师的核心技能之一，掌握各种性能分析工具和方法，能够快速定位和解决性能问题，保障服务的稳定性和可靠性。

**核心要点**：

1. **工具掌握**：熟练使用各种性能分析工具
2. **方法应用**：采用系统化的性能分析方法
3. **瓶颈定位**：快速识别性能瓶颈所在
4. **优化实施**：制定并执行有效的优化方案
5. **监控告警**：建立完善的性能监控机制
6. **持续改进**：不断优化系统性能

> **延伸学习**：更多面试相关的系统性能分析知识，请参考 [SRE面试题解析：top命令中如何显示单独的CPU数据？]({% post_url 2026-04-15-sre-interview-questions %}#20-top命令中如何显示单独的cpu数据)。

---

## 参考资料

- [Linux性能优化指南](https://www.oreilly.com/library/view/linux-performance-optimization/9781492056541/)
- [Linux系统性能分析工具](https://www.brendangregg.com/linuxperf.html)
- [top命令手册](https://man7.org/linux/man-pages/man1/top.1.html)
- [htop官方文档](https://htop.dev/)
- [sysstat官方文档](https://github.com/sysstat/sysstat)
- [Prometheus官方文档](https://prometheus.io/docs/introduction/overview/)
- [Grafana官方文档](https://grafana.com/docs/grafana/latest/)
- [Zabbix官方文档](https://www.zabbix.com/documentation/current/)
- [Linux内核文档](https://www.kernel.org/doc/Documentation/)
- [性能调优指南](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/performance_tuning_guide/index)
- [网络性能调优](https://wiki.linuxfoundation.org/networking/netperf)
- [磁盘性能调优](https://wiki.archlinux.org/title/Improving_performance#Storage)
- [内存管理调优](https://www.kernel.org/doc/html/latest/admin-guide/mm/index.html)
- [CPU调度调优](https://www.kernel.org/doc/html/latest/scheduler/index.html)