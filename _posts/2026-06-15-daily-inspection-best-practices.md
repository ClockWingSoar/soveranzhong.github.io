---
layout: post
title: "运维日常巡检体系建设与最佳实践"
subtitle: "从硬件到应用，构建全面的巡检体系"
date: 2026-06-15 10:00:00
author: "OpsOps"
header-img: "img/post-bg-inspection.jpg"
catalog: true
tags:
  - 运维
  - 巡检
  - 监控
  - 自动化
  - DevOps
---

## 一、引言

日常巡检是运维工作的基石，通过系统化、规范化的检查流程，可以及时发现潜在问题，保障系统的稳定运行。一个完善的巡检体系不仅能提高故障发现效率，还能降低运维成本，提升业务连续性。本文将深入探讨日常巡检的内容体系、执行流程、工具选择和最佳实践。

---

## 二、SCQA分析框架

### 情境（Situation）
- 服务器和应用的稳定运行对业务至关重要
- 人工巡检效率低、容易遗漏关键问题
- 故障往往在发生后才被发现，造成业务损失

### 冲突（Complication）
- 巡检内容繁杂，难以全面覆盖
- 阈值设置不合理导致误报或漏报
- 缺乏统一的巡检标准和流程
- 巡检结果难以追溯和分析

### 问题（Question）
- 日常巡检应该检查哪些内容？
- 如何制定合理的巡检频率？
- 有哪些工具可以自动化巡检？
- 如何处理巡检发现的异常？
- 如何建立完善的巡检体系？

### 答案（Answer）
- 巡检涵盖硬件、系统、网络、应用、安全五个层面
- 根据检查项的重要程度制定不同频率
- 使用Zabbix、Prometheus等工具自动化巡检
- 建立异常处理流程，及时响应和修复问题
- 建立标准化巡检体系，确保全面覆盖

---

## 三、巡检内容体系

### 3.1 硬件层巡检

**核心检查项**：

| 检查项 | 检查方法 | 正常范围 | 告警阈值 |
|:------|:------|:------|:------|
| CPU使用率 | `top`, `mpstat` | <70% | >80% |
| CPU温度 | `sensors`, IPMI | <70℃ | >85℃ |
| 内存使用率 | `free -h` | <70% | >85% |
| 磁盘空间 | `df -h` | <70% | >90% |
| 磁盘IO | `iostat -x` | iowait<20% | iowait>30% |
| 电源状态 | IPMI工具 | 正常（绿灯） | 异常（黄灯/红灯） |
| 风扇状态 | IPMI工具 | 正常运行 | 异常噪音/停转 |

**硬件巡检脚本示例**：
```bash
#!/bin/bash
echo "=== 硬件巡检报告 ==="
echo ""

# CPU使用率
echo "1. CPU使用率"
top -bn1 | head -5

# 内存使用
echo ""
echo "2. 内存使用"
free -h

# 磁盘空间
echo ""
echo "3. 磁盘空间"
df -h

# 磁盘IO
echo ""
echo "4. 磁盘IO"
iostat -x 1 1

# 系统温度
echo ""
echo "5. 系统温度"
sensors 2>/dev/null || echo "未安装sensors工具"
```

### 3.2 系统层巡检

**核心检查项**：

| 检查项 | 检查方法 | 正常状态 | 告警条件 |
|:------|:------|:------|:------|
| 系统运行时间 | `uptime` | 无异常重启 | 频繁重启 |
| 僵尸进程 | `ps aux | grep Z` | 0个 | >0个 |
| 关键服务状态 | `systemctl status` | running | stopped/failed |
| 系统日志 | `journalctl -p err` | 无错误 | 有错误日志 |
| inode使用 | `df -i` | <70% | >90% |
| 登录用户 | `w` | 正常用户 | 异常登录 |

**系统巡检脚本示例**：
```bash
#!/bin/bash
echo "=== 系统巡检报告 ==="
echo ""

# 系统运行时间
echo "1. 系统运行时间"
uptime

# 僵尸进程
echo ""
echo "2. 僵尸进程检查"
zombie=$(ps aux | grep -E '^.*[Zz]' | wc -l)
if [ $zombie -eq 0 ]; then
    echo "✅ 无僵尸进程"
else
    echo "⚠️ 发现 $zombie 个僵尸进程"
    ps aux | grep -E '^.*[Zz]'
fi

# 关键服务状态
echo ""
echo "3. 关键服务状态"
services=("nginx" "mysql" "redis")
for service in "${services[@]}"; do
    status=$(systemctl is-active $service)
    if [ "$status" = "active" ]; then
        echo "✅ $service: 运行中"
    else
        echo "❌ $service: 已停止"
    fi
done

# 系统错误日志
echo ""
echo "4. 最近错误日志"
journalctl -p err -n 10
```

### 3.3 网络层巡检

**核心检查项**：

| 检查项 | 检查方法 | 正常状态 | 告警条件 |
|:------|:------|:------|:------|
| 网络连通性 | `ping` | 延迟<50ms | 丢包>1% |
| DNS解析 | `nslookup` | 正常解析 | 解析失败 |
| 端口监听 | `ss -tlnp` | 正常监听 | 端口未监听 |
| 网络带宽 | `iftop` | <70% | >85% |
| 防火墙规则 | `iptables -L` | 规则正常 | 异常规则 |

**网络巡检脚本示例**：
```bash
#!/bin/bash
echo "=== 网络巡检报告 ==="
echo ""

# 网络连通性测试
echo "1. 网络连通性测试"
echo "测试网关..."
ping -c 3 192.168.1.1 > /dev/null && echo "✅ 网关可达" || echo "❌ 网关不可达"

echo ""
echo "测试DNS解析..."
nslookup google.com > /dev/null && echo "✅ DNS解析正常" || echo "❌ DNS解析失败"

# 关键端口检查
echo ""
echo "2. 关键端口监听"
ports=("80" "443" "3306" "6379")
for port in "${ports[@]}"; do
    result=$(ss -tlnp | grep ":$port")
    if [ -n "$result" ]; then
        echo "✅ 端口 $port: 已监听"
    else
        echo "❌ 端口 $port: 未监听"
    fi
done
```

### 3.4 应用层巡检

**核心检查项**：

| 检查项 | 检查方法 | 正常状态 | 告警条件 |
|:------|:------|:------|:------|
| 服务可用性 | `curl`, `httpie` | 200 OK | 非200状态码 |
| 响应时间 | `curl -w` | <500ms | >1000ms |
| 应用日志 | `tail -f` | 无ERROR | ERROR日志>10条/分钟 |
| 中间件状态 | CLI命令 | 正常运行 | 异常状态 |
| 数据库连接 | 连接测试 | 正常连接 | 连接失败 |

**应用巡检脚本示例**：
```bash
#!/bin/bash
echo "=== 应用巡检报告 ==="
echo ""

# HTTP服务检查
echo "1. HTTP服务检查"
url="http://localhost:80/health"
response=$(curl -s -w "%{http_code}" -o /dev/null $url)
time=$(curl -s -w "%{time_total}s" -o /dev/null $url)
if [ "$response" = "200" ]; then
    echo "✅ HTTP服务正常，响应时间: $time"
else
    echo "❌ HTTP服务异常，状态码: $response"
fi

# 数据库连接测试
echo ""
echo "2. 数据库连接测试"
mysql -u root -psecret -e "SELECT 1" > /dev/null 2>&1 && echo "✅ 数据库连接正常" || echo "❌ 数据库连接失败"

# Redis状态检查
echo ""
echo "3. Redis状态检查"
redis-cli PING | grep -q PONG && echo "✅ Redis运行正常" || echo "❌ Redis运行异常"
```

### 3.5 安全层巡检

**核心检查项**：

| 检查项 | 检查方法 | 正常状态 | 告警条件 |
|:------|:------|:------|:------|
| 账户安全 | `last`, `w` | 正常登录 | 异常登录 |
| 权限文件 | `ls -la` | 权限正确 | 权限过宽 |
| 恶意进程 | `ps aux` | 正常进程 | 可疑进程 |
| 异常连接 | `netstat` | 正常连接 | 异常外部连接 |
| 日志完整性 | 日志检查 | 日志完整 | 日志缺失/篡改 |

---

## 四、巡检频率与执行流程

### 4.1 巡检频率建议

| 巡检类型 | 频率 | 覆盖范围 | 负责人 |
|:------|:------|:------|:------|
| **日常巡检** | 每日2次（早8:00、晚8:00） | 核心指标（CPU、内存、磁盘、关键服务） | 运维工程师 |
| **深度巡检** | 每周1次 | 全量检查项 | 资深工程师 |
| **专项巡检** | 每月1次 | 安全、备份、性能专项 | 技术主管 |
| **全面巡检** | 每季度1次 | 所有检查项+硬件体检 | 运维团队 |

### 4.2 巡检执行流程

```
┌─────────────────────────────────────────────────────────────┐
│                      巡检执行流程                           │
├─────────────────────────────────────────────────────────────┤
│                                                           │
│  1. 准备阶段                                               │
│     ├─ 确认巡检清单                                        │
│     ├─ 准备检查工具                                        │
│     └─ 确认账号权限                                        │
│                                                           │
│  2. 执行阶段                                               │
│     ├─ 硬件层检查                                          │
│     ├─ 系统层检查                                          │
│     ├─ 网络层检查                                          │
│     ├─ 应用层检查                                          │
│     └─ 安全层检查                                          │
│                                                           │
│  3. 分析阶段                                               │
│     ├─ 记录检查结果                                        │
│     ├─ 识别异常项                                          │
│     └─ 评估影响程度                                        │
│                                                           │
│  4. 处理阶段                                               │
│     ├─ 轻微问题：立即修复                                   │
│     ├─ 严重问题：隔离上报                                   │
│     └─ 复杂问题：按流程处理                                 │
│                                                           │
│  5. 归档阶段                                               │
│     ├─ 生成巡检报告                                        │
│     ├─ 记录处理过程                                        │
│     └─ 数据归档分析                                        │
│                                                           │
└─────────────────────────────────────────────────────────────┘
```

### 4.3 异常处理流程

```bash
# 异常分级标准
- P0（紧急）：服务不可用、数据丢失、安全漏洞
- P1（严重）：性能严重下降、关键服务异常
- P2（中等）：非关键服务异常、资源使用率偏高
- P3（提示）：配置问题、日志警告

# 处理流程
1. 发现异常 → 2. 确认问题 → 3. 评估级别 → 4. 处理问题 → 5. 记录归档

# 处理时限
- P0：立即响应（5分钟内）
- P1：1小时内处理
- P2：4小时内处理
- P3：工作时间内处理
```

---

## 五、巡检工具推荐

### 5.1 命令行工具

| 工具 | 用途 | 示例 |
|:------|:------|:------|
| `top/htop` | CPU/内存监控 | `top -bn1` |
| `free` | 内存使用 | `free -h` |
| `df` | 磁盘空间 | `df -h` |
| `iostat` | 磁盘IO | `iostat -x 1 1` |
| `ss/netstat` | 网络连接 | `ss -tlnp` |
| `ping` | 连通性测试 | `ping -c 3 host` |
| `curl` | HTTP测试 | `curl -I url` |
| `journalctl` | 系统日志 | `journalctl -p err` |

### 5.2 自动化工具

| 工具 | 类型 | 特点 | 适用场景 |
|:------|:------|:------|:------|
| **Zabbix** | 综合监控 | 功能全面，支持告警 | 企业级监控 |
| **Prometheus** | 指标监控 | 云原生，灵活查询 | 云环境监控 |
| **Nagios** | 服务监控 | 老牌工具，插件丰富 | 传统运维 |
| **Ansible** | 批量执行 | 自动化运维 | 多节点管理 |
| **Grafana** | 可视化 | 图表展示，仪表盘 | 数据可视化 |

### 5.3 巡检脚本示例

**综合巡检脚本**：
```bash
#!/bin/bash
# 综合巡检脚本
# 输出格式：时间戳、服务器、检查项、状态、详情

timestamp=$(date "+%Y-%m-%d %H:%M:%S")
hostname=$(hostname)

echo "=== $timestamp $hostname 巡检报告 ==="

# CPU检查
cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
echo "CPU使用率: $cpu_usage%"
if (( $(echo "$cpu_usage > 80" | bc -l) )); then
    echo "⚠️ CPU使用率超过阈值"
fi

# 内存检查
mem_total=$(free -m | grep Mem | awk '{print $2}')
mem_available=$(free -m | grep Mem | awk '{print $7}')
mem_usage=$(echo "scale=2; ($mem_total - $mem_available) / $mem_total * 100" | bc)
echo "内存使用率: $mem_usage%"
if (( $(echo "$mem_usage > 85" | bc -l) )); then
    echo "⚠️ 内存使用率超过阈值"
fi

# 磁盘检查
disk_usage=$(df -h / | grep / | awk '{print $5}' | sed 's/%//g')
echo "根目录使用率: $disk_usage%"
if (( disk_usage > 90 )); then
    echo "⚠️ 磁盘空间不足"
fi

echo "=== 巡检完成 ==="
```

---

## 六、生产环境最佳实践

### 6.1 自动化巡检

**定时任务配置**：
```bash
# 每日早8点执行日常巡检
0 8 * * * /usr/local/bin/daily_check.sh >> /var/log/daily_check.log 2>&1

# 每周日凌晨执行深度巡检
0 0 * * 0 /usr/local/bin/weekly_check.sh >> /var/log/weekly_check.log 2>&1

# 每月1号执行专项巡检
0 0 1 * * /usr/local/bin/monthly_check.sh >> /var/log/monthly_check.log 2>&1
```

**告警配置**：
```yaml
# Prometheus告警规则示例
groups:
- name: server.rules
  rules:
  - alert: HighCPUUsage
    expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "CPU使用率过高"
      description: "实例 {{ $labels.instance }} CPU使用率超过80%"

  - alert: HighMemoryUsage
    expr: 100 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100) > 85
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "内存使用率过高"
      description: "实例 {{ $labels.instance }} 内存使用率超过85%"

  - alert: DiskSpaceLow
    expr: 100 - (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"} * 100) > 90
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "磁盘空间不足"
      description: "实例 {{ $labels.instance }} 磁盘空间使用率超过90%"
```

### 6.2 巡检报告模板

**日报模板**：
```
====================================
        服务器巡检日报
====================================
日期：2026-06-15
巡检时间：08:00
巡检范围：生产环境（10台服务器）

一、资源使用概况
┌──────────┬───────┬───────┬───────┐
│ 服务器   │ CPU   │ 内存  │ 磁盘  │
├──────────┼───────┼───────┼───────┤
│ server-1 │ 45%   │ 62%   │ 68%   │
│ server-2 │ 52%   │ 71%   │ 75%   │
│ ...      │ ...   │ ...   │ ...   │
└──────────┴───────┴───────┴───────┘

二、服务状态
- Nginx: ✅ 全部正常
- MySQL: ✅ 全部正常
- Redis: ✅ 全部正常

三、异常汇总
今日无异常 ✅

四、备注
无

====================================
```

### 6.3 阈值管理

**阈值设置原则**：
```bash
# 根据业务特点设置阈值
- CPU：70%警告，85%紧急（数据库服务器可设60%/75%）
- 内存：70%警告，85%紧急（应用服务器可设65%/80%）
- 磁盘：80%警告，90%紧急（日志服务器可设75%/85%）
- 响应时间：500ms警告，1000ms紧急
- 错误率：1%警告，5%紧急
```

---

## 七、常见问题与解决方案

### 问题一：巡检遗漏关键项

**现象**：人工巡检经常遗漏某些检查项

**解决方案**：
```bash
# 建立标准化巡检清单
# 使用自动化工具代替人工
# 设置检查项优先级，确保核心项必查
```

### 问题二：告警风暴

**现象**：阈值设置过低导致频繁告警

**解决方案**：
```bash
# 设置合理的告警阈值
# 使用持续时间判断（for: 5m）
# 建立告警分级，夜间静默非紧急告警
```

### 问题三：巡检结果无法追溯

**现象**：巡检结果没有记录，问题无法追溯

**解决方案**：
```bash
# 输出巡检报告到日志文件
# 使用版本控制管理巡检记录
# 定期汇总分析巡检数据
```

### 问题四：多服务器巡检效率低

**现象**：服务器数量多，逐台巡检效率低

**解决方案**：
```bash
# 使用Ansible批量执行巡检脚本
# 使用Prometheus统一监控
# 建立巡检代理节点
```

---

## 八、总结

### 核心要点

1. **巡检内容**：覆盖硬件、系统、网络、应用、安全五个层面
2. **巡检频率**：根据检查项重要程度制定不同频率
3. **工具选择**：命令行工具快速检查，自动化工具持续监控
4. **异常处理**：建立分级处理流程，及时响应问题
5. **最佳实践**：自动化巡检、标准化流程、定期分析

### 实施建议

| 阶段 | 任务 | 时间 |
|:------|:------|:------|
| 第一阶段 | 建立巡检清单 | 1周 |
| 第二阶段 | 编写巡检脚本 | 1周 |
| 第三阶段 | 配置自动化工具 | 2周 |
| 第四阶段 | 建立告警体系 | 1周 |
| 第五阶段 | 持续优化 | 持续 |

> 本文对应的面试题：[日常巡检，主要是巡检哪些东西？]({% post_url 2026-04-15-sre-interview-questions %})

---

## 附录：常用巡检命令

```bash
# 系统资源
top -bn1 | head -5        # CPU使用概览
free -h                   # 内存使用
df -h                     # 磁盘空间
iostat -x 1 1             # 磁盘IO
vmstat 1 3                # 系统状态

# 网络
ping -c 3 host            # 连通性测试
nslookup domain           # DNS解析
ss -tlnp                  # 端口监听
iftop -n -t -s 10         # 带宽使用

# 服务
systemctl status service  # 服务状态
ps aux --sort=-%mem | head -10  # 内存TOP进程

# 日志
journalctl -p err -n 20   # 错误日志
tail -f /var/log/app.log  # 应用日志
```
