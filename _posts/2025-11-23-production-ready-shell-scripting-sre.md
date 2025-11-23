---
layout: post
title: "Production-Ready Shell Scripting for SREs"
date: 2025-11-23 00:00:00 +0800
categories: [Linux, SRE, DevOps]
tags: [shell, bash, automation, best-practices]
---

作为一名 SRE 或 AIOps 工程师，Shell 脚本是我们日常工作中不可或缺的工具。然而，很多时候我们接手的脚本往往是"一次性"代码——缺乏错误处理、日志混乱、难以维护。

在面试中，能够写出健壮、规范的 Shell 脚本，是区分初级运维和高级 SRE 的关键细节之一。本文将从生产环境的角度出发，探讨如何编写高质量的 Shell 脚本。

## 1. 情境 (Situation)

在现代运维体系中，尽管 Ansible、Terraform 等自动化工具已经非常普及，但 Shell 脚本依然是服务器底层操作、容器启动脚本以及胶水代码的首选。它的优势在于：
- **原生支持**：所有 Linux 发行版默认可用。
- **执行效率**：直接与内核交互，启动速度快。
- **灵活性**：能够快速处理文本流和系统调用。

## 2. 冲突 (Conflict)

然而，Shell 语言本身非常宽松。默认情况下：
- 变量未定义也能运行（可能导致 `rm -rf /${UNDEFINED_VAR}` 这种灾难）。
- 命令报错后继续执行后续代码（导致连锁故障）。
- 缺乏标准的日志和参数解析机制。

这种"宽松"在生产环境中是致命的。一个不严谨的脚本可能会导致数据丢失、服务中断，甚至引发严重的线上事故。

## 3. 问题 (Question)

如何才能写出像 Python 或 Go 一样健壮、可维护且安全的 Shell 脚本？我们需要引入哪些工程化实践？

## 4. 答案 (Answer)

要编写生产级的 Shell 脚本，我们需要遵循以下核心原则：**防御性编程**、**结构化日志**、**标准化模版**。

### 4.1 防御性编程：三大法宝

在脚本开头加入以下配置，可以避免 90% 的低级错误：

```bash
set -o errexit   # 遇到错误立即退出 (等同于 set -e)
set -o nounset   # 使用未定义变量时报错 (等同于 set -u)
set -o pipefail  # 管道中任意命令失败则整个管道失败
```

### 4.2 结构化日志

不要只使用 `echo`。定义标准的日志函数，包含时间戳和日志级别，方便后续接入 ELK 或 Loki 等日志系统。

```bash
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" >&2
}

log_info() { log "INFO" "$@"; }
log_error() { log "ERROR" "$@"; }
```

### 4.3 资源清理 (Trap)

使用 `trap` 确保脚本退出（无论是正常结束还是异常中断）时，都能清理临时文件或释放锁。

```bash
cleanup() {
    rm -f /tmp/temp_file
    log_info "Cleanup completed."
}
trap cleanup EXIT
```

### 4.4 浮点数运算 (bc 工具)

Shell 的内置算术运算 `$(( ))` 只支持整数运算。当需要进行浮点数计算时（如计算资源使用率、性能指标等），我们需要使用 `bc` 命令。

#### 关键参数：`scale`

`scale` 是 `bc` 中控制**除法运算精度**的关键变量，它决定了结果保留几位小数。默认情况下 `scale=0`，会导致除法结果被截断为整数。

#### 实战案例：计算表达式优先级

假设我们需要计算 CPU 负载的归一化值，表达式为：`9 - 8 * 2 / 5^2`

```bash
# 设置精度为2位小数，然后执行运算
$ echo "scale=2; 9 - 8 * 2 / 5^2" | bc
8.36
```

**执行过程解析**（遵循数学运算优先级）：

1. **指数运算** `5^2 = 25` → `9 - 8 * 2 / 25`
2. **乘法运算** `8 * 2 = 16` → `9 - 16 / 25`
3. **除法运算** `16 / 25 = 0.64` *（此时 scale=2 生效，保留2位小数）*
4. **减法运算** `9 - 0.64 = 8.36`

#### 生产环境应用场景

```bash
#!/bin/bash
# 计算磁盘使用率百分比
used=$(df -h / | awk 'NR==2 {print $3}' | sed 's/G//')
total=$(df -h / | awk 'NR==2 {print $2}' | sed 's/G//')

# 使用 bc 进行浮点数除法，保留2位小数
usage_percent=$(echo "scale=2; ($used / $total) * 100" | bc)

echo "磁盘使用率: ${usage_percent}%"

# 告警阈值判断（bc 支持布尔运算，返回1或0）
if [[ $(echo "$usage_percent > 80" | bc) -eq 1 ]]; then
    log_error "磁盘使用率超过 80%，当前: ${usage_percent}%"
fi
```

**最佳实践**：
- 始终显式设置 `scale` 值，避免精度丢失
- 对于百分比计算，通常 `scale=2` 已足够
- 注意 `bc` 的运算符优先级：`^` > `*` `/` > `+` `-`

### 4.5 实战：通用脚本模版

为了规范团队的脚本编写风格，我整理了一个通用的 Shell 脚本模版。它包含了上述的所有最佳实践，以及标准的参数解析逻辑。

**代码位置**：[`code/linux/production-shell/script_template.sh`](/code/linux/production-shell/script_template.sh)

<details>
<summary>点击查看完整代码</summary>

```bash
#!/bin/bash
#
# Script Name: script_template.sh
# Description: A production-ready shell script template for SREs.
# Author: SRE Team
# Date: 2025-11-23
# Version: 1.0
#
# Usage: ./script_template.sh [options]
# Options:
#   -h, --help      Show help message
#   -v, --verbose   Enable verbose logging
#   -d, --dry-run   Simulate execution without making changes

# -----------------------------------------------------------------------------
# Safety Settings
# -----------------------------------------------------------------------------
set -o errexit   # Exit on error
set -o nounset   # Exit on undefined variable
set -o pipefail  # Exit if any command in a pipe fails
# set -o xtrace  # Uncomment for debugging (print commands)

# -----------------------------------------------------------------------------
# Global Variables
# -----------------------------------------------------------------------------
readonly SCRIPT_NAME=$(basename "$0")
readonly LOG_FILE="/var/log/${SCRIPT_NAME%.*}.log"
VERBOSE=false
DRY_RUN=false

# -----------------------------------------------------------------------------
# Logging Functions
# -----------------------------------------------------------------------------
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}" >&2
}

log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------
usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [options]

Options:
  -h, --help      Show this help message and exit
  -v, --verbose   Enable verbose logging
  -d, --dry-run   Enable dry-run mode (no changes applied)

Example:
  ${SCRIPT_NAME} --verbose --dry-run
EOF
}

cleanup() {
    # Add cleanup logic here (e.g., removing temp files)
    if [[ "${VERBOSE}" == "true" ]]; then
        log_info "Cleaning up..."
    fi
}
trap cleanup EXIT

# -----------------------------------------------------------------------------
# Main Logic
# -----------------------------------------------------------------------------
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    log_info "Starting script execution..."

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_warn "Dry-run mode enabled. No changes will be made."
    fi

    # Your business logic goes here
    if [[ "${VERBOSE}" == "true" ]]; then
        log_info "Verbose mode is on. Detailed logs will be shown."
    fi
    
    # Example operation
    log_info "Performing critical operation..."
    # command_to_run

    log_info "Script finished successfully."
}

# -----------------------------------------------------------------------------
# Entry Point
# -----------------------------------------------------------------------------
main "$@"
```
</details>

### 4.6 案例分析：日志监控脚本

下面我们来看一个具体的案例：编写一个脚本，监控指定的日志文件，当发现特定关键字（如 "ERROR"）时触发告警。

这个脚本演示了如何：
1. 使用 `getopts` 解析命令行参数。
2. 检查文件是否存在。
3. 结合 `grep` 进行逻辑判断。

**代码位置**：[`code/linux/production-shell/log_monitor.sh`](/code/linux/production-shell/log_monitor.sh)

<details>
<summary>点击查看完整代码</summary>

```bash
#!/bin/bash
#
# Script Name: log_monitor.sh
# Description: Monitors a log file for specific keywords and triggers an alert.
# Author: SRE Team
# Date: 2025-11-23
# Version: 1.0
#
# Usage: ./log_monitor.sh -f <logfile> -k <keyword>

set -o errexit
set -o nounset
set -o pipefail

readonly SCRIPT_NAME=$(basename "$0")
LOG_FILE="./monitor.log" # Local log for demo purposes

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}" >&2
}

log_info() { log "INFO" "$@"; }
log_error() { log "ERROR" "$@"; }

usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} -f <logfile> -k <keyword>

Options:
  -f, --file      Path to the log file to monitor
  -k, --keyword   Keyword to search for (e.g., "ERROR", "Exception")
  -h, --help      Show help message
EOF
}

send_alert() {
    local message="$1"
    # In a real scenario, this would call an API (e.g., Slack, PagerDuty)
    log_info "ALERT TRIGGERED: ${message}"
}

main() {
    local target_file=""
    local keyword=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--file)
                target_file="$2"
                shift 2
                ;;
            -k|--keyword)
                keyword="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown argument: $1"
                usage
                exit 1
                ;;
        esac
    done

    if [[ -z "${target_file}" || -z "${keyword}" ]]; then
        log_error "Missing required arguments."
        usage
        exit 1
    fi

    if [[ ! -f "${target_file}" ]]; then
        log_error "File not found: ${target_file}"
        exit 1
    fi

    log_info "Scanning ${target_file} for keyword '${keyword}'..."

    # Count occurrences
    local count
    count=$(grep -c "${keyword}" "${target_file}" || true)

    if [[ "${count}" -gt 0 ]]; then
        send_alert "Found ${count} occurrences of '${keyword}' in ${target_file}"
    else
        log_info "No issues found."
    fi
}

main "$@"
```
</details>

## 总结

编写 Shell 脚本不仅仅是把命令堆砌在一起。作为 SRE，我们需要像对待应用程序代码一样对待脚本：
1. **安全性优先**：默认开启严格模式。
2. **可观测性**：输出标准化的日志。
3. **可维护性**：使用函数封装逻辑，提供清晰的帮助文档。

掌握这些技巧，不仅能让你的日常工作更轻松，也能在面试中展示你对生产环境稳定性的深刻理解。
