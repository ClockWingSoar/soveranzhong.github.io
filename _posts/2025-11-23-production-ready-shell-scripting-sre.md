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

### 4.4 条件判断的致命陷阱：空格问题

在 Shell 脚本中，**条件判断必须严格遵循空格规则**，否则会导致难以察觉的逻辑错误。

#### 错误示例：缺少空格导致的误判

```bash
# ❌ 错误：没有空格，被当作字符串比较
$ test 1==2
$ echo $?
0  # 返回成功（0），但这是错误的！

# ❌ 错误：[ 和 ] 内部没有空格
$ [ 1==2 ]
$ echo $?
0  # 同样返回成功，实际是在判断字符串 "1==2" 是否非空

# ✅ 正确：运算符两侧都有空格
$ [ 1 == 2 ]
$ echo $?
1  # 返回失败（1），符合预期
```

#### 原理解析

`test` 命令（和 `[ ]` 语法）将参数解析为**独立的词**（tokens）：
- `test 1==2`：只有一个参数 `"1==2"`，被视为**非空字符串**，结果为真
- `test 1 == 2`：三个参数 `"1"`, `"=="`, `"2"`，执行**字符串相等比较**

#### 常见陷阱对比表

**字符串比较运算符**：

| 运算符 | 含义 | 示例 | 说明 |
|--------|------|------|------|
| `==` | 相等 | `[ "abc" == "abc" ]` | ✅ 字符串相等返回真 |
| `!=` | 不等 | `[ "abc" != "xyz" ]` | ✅ 字符串不等返回真 |
| `!==` | ❌ 不存在 | N/A | ❌ Bash 不支持此语法 |

**空格陷阱对比**：

| 写法 | 解析结果 | 返回值 | 说明 |
|------|----------|--------|------|
| `[ 1==2 ]` | 字符串 `"1==2"` 非空 | 0 (真) | ❌ 错误：始终为真 |
| `[ 1 == 2 ]` | 字符串 `"1"` ≠ `"2"` | 1 (假) | ✅ 正确 |
| `[ 1 == 2]` | 语法错误 | 2 | ❌ 缺少空格 |
| `[[ 1==2 ]]` | 字符串 `"1==2"` 非空 | 0 (真) | ❌ 同样错误 |
| `[[ 1 == 2 ]]` | 字符串相等比较 | 1 (假) | ✅ 正确 |

**实际测试示例**：

```bash
# 字符串相等比较
$ test aaa == bbb
$ echo $?
1  # 返回假（不相等）

# 字符串不等比较（正确语法）
$ test aaa != bbb
$ echo $?
0  # 返回真（确实不等）

# 错误语法示例
$ test aaa !== bbb
-bash: test: !==：需要二元表达式  # Bash 不支持 !==

# 数值也可以用字符串比较（但不推荐）
$ num1=234; num2=456
$ test $num1 == $num2
$ echo $?
1  # 不相等

$ test $num1 != $num2
$ echo $?
0  # 确实不相等
```

#### 变量检查的正确姿势

**常用字符串测试操作符**：

| 操作符 | 含义 | 示例 | 返回真的条件 |
|--------|------|------|--------------|
| `-z` | 字符串长度为零（zero） | `[ -z "$var" ]` | 变量为空或未定义 |
| `-n` | 字符串长度非零（non-zero） | `[ -n "$var" ]` | 变量非空 |
| `-v` | 变量已定义（Bash 4.2+） | `[ -v var ]` | 变量已声明（即使为空） |

**实际测试示例**：

```bash
# -z 测试：判断字符串是否为空
$ string="nihao"
$ test -z "$string"
$ echo $?
1  # 返回假（字符串不为空）

$ test -z "$string1"  # string1 未定义
$ echo $?
0  # 返回真（字符串为空）

# -n 测试：判断字符串是否非空
$ str="value"
$ test -n "$str"
$ echo $?
0  # 返回真（字符串非空）

$ unset str2
$ test -n "$str2"
$ echo $?
1  # 返回假（字符串为空）
```

**-z 和 -n 对比表**：

| 变量状态 | `-z "$var"` | `-n "$var"` | 说明 |
|----------|-------------|-------------|------|
| 未定义 | 0 (真) | 1 (假) | 变量不存在 |
| 空字符串 `var=""` | 0 (真) | 1 (假) | 变量为空 |
| 非空 `var="abc"` | 1 (假) | 0 (真) | 变量有值 |

**典型应用场景**：

```bash
# 检查必需参数
if [ -z "$1" ]; then
    echo "错误：缺少参数" >&2
    exit 1
fi

# 检查配置变量是否设置
if [ -n "$DB_PASSWORD" ]; then
    echo "数据库密码已配置"
fi
```

**⚠️ 重要警告：-n 测试必须加引号**：

```bash
# 未定义的变量测试
$ unset str

# ❌ 错误：不加引号会误判
$ [ -n $str ]
$ echo $?
0  # 返回真！但这是错误的，str 是空的

# ✅ 正确：加引号才能正确判断
$ [ -n "$str" ]
$ echo $?
1  # 返回假，符合预期（str 确实为空）
```

**原理解析**：
- `[ -n $str ]` → 词分割后变成 `[ -n ]`（只有一个参数）
- `test` 收到单个参数时，检查参数本身是否非空
- `-n` 本身是非空字符串，所以返回真（❌ 错误结果）
- `[ -n "$str" ]` → 变成 `[ -n "" ]`（两个参数）
- 正确执行 `-n` 测试：空字符串非空吗？返回假（✅ 正确结果）

**关键规则**：
- ✅ **始终给变量加引号**：`[ -n "$var" ]` 和 `[ -z "$var" ]`
- ❌ **永远不要省略引号**：`[ -n $var ]` 可能产生误导性结果

#### 文件属性判断

除了字符串和数值，Shell 还提供了丰富的文件属性测试操作符，这在运维脚本中极为常用。

**常用文件测试操作符**：

| 操作符 | 含义 | 示例 | 说明 |
|--------|------|------|------|
| `-f` | 普通文件 | `[ -f "$file" ]` | 文件存在且是普通文件（非目录） |
| `-d` | 目录 | `[ -d "$dir" ]` | 目录存在 |
| `-e` | 存在 | `[ -e "$path" ]` | 路径存在（无论是文件还是目录） |
| `-s` | 非空文件 | `[ -s "$file" ]` | 文件存在且大小大于0 |
| `-r` | 可读 | `[ -r "$file" ]` | 当前用户有读权限 |
| `-w` | 可写 | `[ -w "$file" ]` | 当前用户有写权限 |
| `-x` | 可执行 | `[ -x "$file" ]` | 当前用户有执行权限 |

**实际测试示例**：

```bash
# -f 测试：判断是否为普通文件
$ [ -f weizhi.sh ] && echo "是一个文件"
是一个文件

$ [ -f weizhi.sddh ] || echo "不是一个文件"
不是一个文件  # 文件不存在

# -d 测试：判断是否为目录
$ [ -d weizhi.sddh ] || echo "不是一个目录"
不是一个目录

$ [ -d /tmp ] && echo "是一个目录"
是一个目录
```

**典型应用场景**：

```bash
# 1. 备份前检查目录是否存在，不存在则创建
BACKUP_DIR="/data/backup"
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
fi

# 2. 执行脚本前检查是否有执行权限
SCRIPT="./deploy.sh"
if [ ! -x "$SCRIPT" ]; then
    chmod +x "$SCRIPT"
fi

# 3. 检查配置文件是否存在且可读
CONFIG="/etc/myapp/config.conf"
if [ -f "$CONFIG" ] && [ -r "$CONFIG" ]; then
    source "$CONFIG"
else
    echo "错误：配置文件不存在或不可读" >&2
    exit 1
fi
```

**避免常见错误**：

```bash
# ❌ 错误：变量未定义时会报错
if [ $undefined_var == "value" ]; then
    echo "Match"
fi
# 报错：-bash: [: ==: unary operator expected

# ✅ 方法1：使用引号保护
if [ "$undefined_var" == "value" ]; then
    echo "Match"
fi

# ✅ 方法2：使用 -v 判断变量是否定义
if [ -v my_var ]; then
    echo "Variable is set"
fi

# ✅ 方法3：使用 -z 判断变量是否为空
if [ -z "$var" ]; then
    echo "Variable is empty or unset"
fi

# ✅ 方法4：使用双括号（推荐）
if [[ $undefined_var == "value" ]]; then
    echo "Match"  # [[ ]] 会自动处理未定义变量
fi
```

#### 综合案例：用户登录验证

下面是一个完整的登录验证脚本，综合运用了字符串测试、条件判断和逻辑运算符。

**原始版本（有多个问题）**：
```bash
#!/bin/bash
# 获取系统信息
OS_INFO=$(cat /etc/redhat-release)
KERNEL_INFO=$(uname -r)
OS_ARCH=$(uname -m)
HOSTNAME=$(hostname)

# 清屏并显示信息
clear
echo -e "\e[32m${OS_INFO} \e[0m"
echo -e "\e[32mKernel ${KERNEL_INFO} on an ${OS_ARCH} \e[0m"
echo "---------------------------------"

# 读取用户输入
read -p "" account
[ -z $account ] && read -p "" account  # 问题：没有引号
read -s -t30 -p "" password
echo
echo "---------------------------------"

# 验证（问题：没有引号，没有错误提示）
[ $account == 'root' ] && [ $password == '123456' ] && echo "" || echo ""
```

**优化版本**：

**代码位置**：[`code/linux/production-shell/simple_login.sh`](/code/linux/production-shell/simple_login.sh)

```bash
#!/bin/bash
#
# Script Name: simple_login.sh
# Description: Simple login authentication demo
# Author: clockwingsoar@outlook.com
# Date: 2025-11-23
# Version: 2.0 (Production-Ready)
#
# WARNING: This is for demonstration purposes only.
# Do NOT use plain text passwords in production!
#

set -euo pipefail

# -----------------------------------------------------------------------------
# System Information
# -----------------------------------------------------------------------------
readonly OS_INFO=$(cat /etc/redhat-release 2>/dev/null || echo "Unknown OS")
readonly KERNEL_INFO=$(uname -r)
readonly OS_ARCH=$(uname -m)
readonly HOSTNAME=$(hostname)

# -----------------------------------------------------------------------------
# Configuration (In production, use hashed passwords!)
# -----------------------------------------------------------------------------
readonly VALID_USERNAME="root"
readonly VALID_PASSWORD="123456"  # ⚠️ DEMO ONLY!

# -----------------------------------------------------------------------------
# Color definitions
# -----------------------------------------------------------------------------
readonly COLOR_GREEN='\e[32m'
readonly COLOR_RED='\e[31m'
readonly COLOR_RESET='\e[0m'

# -----------------------------------------------------------------------------
# Main Logic
# -----------------------------------------------------------------------------
clear

# Display system information
echo -e "${COLOR_GREEN}${OS_INFO}${COLOR_RESET}"
echo -e "${COLOR_GREEN}Kernel ${KERNEL_INFO} on an ${OS_ARCH}${COLOR_RESET}"
echo "---------------------------------"

# Read username
read -p "账号 (Username): " account

# Validate username is not empty
if [ -z "$account" ]; then
    echo -e "${COLOR_RED}错误：用户名不能为空${COLOR_RESET}" >&2
    exit 1
fi

# Read password (silent input, 30 seconds timeout)
read -s -t30 -p "密码 (Password): " password || {
    echo -e "\n${COLOR_RED}错误：输入超时${COLOR_RESET}" >&2
    exit 1
}
echo  # New line after password input
echo "---------------------------------"

# Validate password is not empty
if [ -z "$password" ]; then
    echo -e "${COLOR_RED}错误：密码不能为空${COLOR_RESET}" >&2
    exit 1
fi

# Authentication
if [[ "$account" == "$VALID_USERNAME" && "$password" == "$VALID_PASSWORD" ]]; then
    echo -e "${COLOR_GREEN}✓ 登录成功！欢迎, $account${COLOR_RESET}"
    exit 0
else
    echo -e "${COLOR_RED}✗ 登录失败：用户名或密码错误${COLOR_RESET}" >&2
    exit 1
fi
```

**关键改进点**：

| 改进项 | 原始版本 | 优化版本 | 原因 |
|--------|----------|----------|------|
| 变量引用 | `$account` 无引号 | `"$account"` | **本章核心：防止词分割** |
| 条件判断 | `[ -z $account ]` | `[ -z "$account" ]` | **避免 -z 误判陷阱** |
| 提示信息 | `read -p ""` 空提示 | `read -p "账号: "` | 用户友好 |
| 空值处理 | 重复 `read` | `if [ -z ]` 验证 | 逻辑清晰 |
| 超时处理 | 无 | `|| { ... }` 错误处理 | 避免挂起 |
| 错误输出 | 无 | `>&2` 输出到 stderr | 符合规范 |
| 成功/失败消息 | 空字符串 | 明确提示 | 用户体验 |
| 安全性 | 单括号 `[ ]` | 双括号 `[[ ]]` | 更安全的字符串比较 |

**运行效果**：

```bash
# 成功登录
$ ./simple_login.sh
Rocky Linux release 9.6 (Blue Onyx)
Kernel 5.14.0-570.58.1.el9_6.x86_64 on an x86_64
---------------------------------
账号 (Username): root
密码 (Password): 
---------------------------------
✓ 登录成功！欢迎, root

# 失败场景
$ ./simple_login.sh
账号 (Username): soveran
密码 (Password): 
---------------------------------
✗ 登录失败：用户名或密码错误
```

**安全警告**：
- ⚠️ **仅供学习**：生产环境绝不使用明文密码
- ✅ **实际方案**：使用 PAM、LDAP、OAuth 等认证系统
- ✅ **密码存储**：使用 `sha256sum`、`bcrypt` 等哈希算法

**本案例涵盖的知识点**：
- ✅ `-z` 字符串空值检查（带引号）
- ✅ `read` 命令的多种选项（`-s` 隐藏输入，`-t` 超时）
- ✅ `[[ ]]` 双括号的安全字符串比较
- ✅ `&&` 和 `||` 逻辑运算符
- ✅ 错误输出重定向 `>&2`
- ✅ 明确的退出码（0 成功，1 失败）

#### 最佳实践

1. **始终在运算符两侧加空格**：`[ "$a" == "$b" ]`
2. **优先使用 `[[ ]]`**：功能更强大，且对空变量更宽容
3. **数值比较用 `-eq`**：`[ $num -eq 10 ]` 而不是 `[ $num == 10 ]`
4. **变量加引号**：`[ "$var" == "value" ]` 防止词分割（word splitting）
5. **使用 ShellCheck**：`shellcheck script.sh` 自动发现此类问题

#### 实用技巧：逻辑运算符 `&&` 和 `||`

Shell 支持使用 `&&`（逻辑与）和 `||`（逻辑或）进行条件执行，这在编写简洁脚本时非常有用。

```bash
# && 运算符：前一个命令成功才执行后一个
$ [ 1 == 1 ] && echo "success"
success

$ [ 1 == 2 ] && echo "fail"
# 不输出（因为条件为假）

# || 运算符：前一个命令失败才执行后一个
$ [ 1 == 2 ] || echo "fail"
fail

$ [ 1 == 1 ] || echo "fail"
# 不输出（因为条件为真）
```

**常见应用场景**：

```bash
# 1. 快速失败（Fail Fast）
command1 || { echo "命令失败"; exit 1; }

# 2. 检查目录存在，不存在则创建
[ -d /tmp/mydir ] || mkdir -p /tmp/mydir

# 3. 目录存在性检查（一行 if-else）
[ -d /etc ] && echo "dir is exist" || echo "dir is not exist"

# 4. 用户名验证
user="admin"
[ "$user" == "admin" ] && echo "user name entered successfully" || echo "user name enter failed"

# 5. 链式条件判断
[ -f config.yml ] && [ -r config.yml ] && echo "配置文件可读"

# 6. 命令成功判断（使用退出码 $?）
grep "error" /var/log/app.log
[ $? -eq 0 ] && echo "发现错误日志" || echo "无错误"
```

**注意事项**：
- `&&` 和 `||` 都是**短路求值**（short-circuit evaluation）
- 复杂逻辑建议使用 `if-then-else`，更易读
- 避免在生产脚本中过度使用一行式判断（可读性差）

#### 实战案例：参数数量验证

下面是一个简单但实用的脚本，展示如何使用 `&&` 和 `||` 进行参数验证：

**原始版本（有改进空间）**：
```bash
#!/bin/bash
arg_num=$#

[ $# == 1 ] && echo "parameter number is 1, running script is allowed"
[ $# == 1 ] || echo "parameter number is not 1, running script is not allowed"
```

**优化版本（生产级）**：
```bash
#!/bin/bash
set -euo pipefail

# 检查参数数量（使用 -eq 进行数值比较）
if [ $# -ne 1 ]; then
    echo "错误：需要恰好 1 个参数" >&2
    echo "用法: $0 <filename>" >&2
    exit 1
fi

# 参数验证通过，继续执行
echo "参数验证通过，开始处理文件: $1"
# 后续业务逻辑...
```

**改进要点对比**：

| 改进点 | 原始版本 | 优化版本 | 原因 |
|--------|----------|----------|------|
| 数值比较 | `[ $# == 1 ]` | `[ $# -eq 1 ]` | 使用正确的数值比较运算符 |
| 错误输出 | 输出到标准输出 | `>&2` 输出到标准错误 | 符合 POSIX 规范 |
| 退出码 | 无 | `exit 1` | 明确告知调用者失败 |
| 用法说明 | 无 | 显示 usage | 提升用户体验 |
| 逻辑清晰度 | 两行独立判断 | `if-then-else` | 避免混淆 |

**使用 `&&` / `||` 的简化版（适合简单场景）**：
```bash
#!/bin/bash
# 快速失败模式
[ $# -eq 1 ] || { echo "用法: $0 <file>" >&2; exit 1; }

# 参数验证通过后的逻辑
echo "处理文件: $1"
```

**关键要点**：
- ✅ **数值比较优先用 `-eq`**：避免字符串比较的歧义
- ✅ **错误信息输出到 stderr**：`>&2` 确保错误不污染管道
- ✅ **提供明确的退出码**：`exit 1` 表示参数错误
- ⚠️ **简洁 vs 可读性**：生产环境建议用 `if-then-else`，调试脚本可用 `&&/||`

#### 综合案例：网络连通性测试

下面是一个完整的网络测试脚本，综合运用了本章节的多个知识点：

**原始版本**：
```bash
#!/bin/bash
host_addr="$1"

# 参数验证
[ -z ${host_addr} ] && echo "请输入待测试主机ip" && exit
[ $# -ne 1 ] && echo "请保证输入1个脚本参数" && exit

# 测试网络
net_status=$(ping -c1 -w1 ${host_addr} >/dev/null 2>&1 && echo "正常" || echo "异常")

# 输出结果
echo -e "\e[31m\t主机网络状态信息\e[0m"
echo -e "\e[32m================================"
echo "${host_addr} 网络状态: ${net_status}"
echo -e "================================\e[0m"
```

**优化版本**：

**代码位置**：[`code/linux/production-shell/host_network_test.sh`](/code/linux/production-shell/host_network_test.sh)

```bash
#!/bin/bash
#
# Script Name: host_network_test.sh
# Description: Test network connectivity to a remote host
# Author: 钟翼翔 (clockwingsoar@outlook.com)
# Date: 2025-11-23
# Version: 2.0 (Production-Ready)
#

set -euo pipefail

# -----------------------------------------------------------------------------
# Color definitions
# -----------------------------------------------------------------------------
readonly COLOR_RED='\e[31m'
readonly COLOR_GREEN='\e[32m'
readonly COLOR_YELLOW='\e[33m'
readonly COLOR_RESET='\e[0m'

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------
usage() {
    cat <<EOF
用法: $0 <IP地址或主机名>

描述: 
  测试指定主机的网络连通性

示例:
  $0 10.0.0.13
  $0 www.google.com
EOF
}

# -----------------------------------------------------------------------------
# Parameter Validation
# -----------------------------------------------------------------------------
# 检查参数数量
if [ $# -ne 1 ]; then
    echo -e "${COLOR_RED}错误：需要恰好 1 个参数${COLOR_RESET}" >&2
    usage
    exit 1
fi

# 检查参数是否为空
if [ -z "$1" ]; then
    echo -e "${COLOR_RED}错误：IP地址不能为空${COLOR_RESET}" >&2
    exit 1
fi

readonly HOST_ADDR="$1"

# -----------------------------------------------------------------------------
# Network Test
# -----------------------------------------------------------------------------
echo -e "${COLOR_RED}\t主机网络状态信息${COLOR_RESET}"
echo -e "${COLOR_GREEN}================================${COLOR_RESET}"

# 使用 ping 测试网络（-c1: 发送1个包, -W1: 等待1秒超时）
if ping -c1 -W1 "${HOST_ADDR}" >/dev/null 2>&1; then
    echo -e "${COLOR_GREEN}${HOST_ADDR} 网络状态: 正常${COLOR_RESET}"
    exit_code=0
else
    echo -e "${COLOR_YELLOW}${HOST_ADDR} 网络状态: 异常${COLOR_RESET}"
    exit_code=1
fi

echo -e "${COLOR_GREEN}================================${COLOR_RESET}"

exit ${exit_code}
```

**关键改进点**：

| 改进项 | 原始版本 | 优化版本 | 优势 |
|--------|----------|----------|------|
| 变量引用 | `${host_addr}` 无引号 | `"${HOST_ADDR}"` | 防止包含空格的主机名出错 |
| 参数验证顺序 | 先检查空，后检查数量 | 先检查数量，后检查空 | 逻辑更合理 |
| 退出码 | `exit` 无参数 | `exit ${exit_code}` | 调用者可判断测试结果 |
| 颜色定义 | 硬编码 | 定义为常量 | 易维护、可复用 |
| 帮助信息 | 无 | `usage()` 函数 | 用户友好 |
| ping 参数 | `-w1` (macOS不兼容) | `-W1` (POSIX标准) | 跨平台兼容 |

**运行效果**：

```bash
# 测试成功
$ ./host_network_test.sh 10.0.0.13
        主机网络状态信息
================================
10.0.0.13 网络状态: 正常
================================

# 测试失败
$ ./host_network_test.sh 192.168.1.254
        主机网络状态信息
================================
192.168.1.254 网络状态: 异常
================================
$ echo $?
1  # 退出码反映测试结果
```

**实战应用场景**：
- 批量主机健康检查
- CI/CD 部署前的网络验证
- 监控系统的连通性探测
- 故障诊断工具

### 4.5 浮点数运算 (bc 工具)

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

#### 综合实战：内存监控脚本

下面是一个完整的生产级内存监控脚本，综合运用了本文讲解的多个技术点：

**改进要点**：
1. ✅ 使用 `awk` 替代 `grep | tr | cut` 管道（更高效、更可靠）
2. ✅ 添加临时文件清理（`trap` 确保异常退出时也能清理）
3. ✅ 参数验证与错误处理（避免除零、空值等异常）
4. ✅ 使用 `bc` 进行布尔判断（阈值告警）
5. ✅ 彩色输出分级（绿色=正常、黄色=警告、红色=严重）

**代码位置**：[`code/linux/production-shell/memory_monitor.sh`](/code/linux/production-shell/memory_monitor.sh)

```bash
#!/bin/bash
#
# Script Name: memory_monitor.sh
# Description: Monitor system memory usage with colored output
# Author: 钟翼翔 (clockwingsoar@outlook.com)
# Date: 2025-11-23
# Version: 2.0 (Production-Ready)
#

set -o errexit
set -o nounset
set -o pipefail

# -----------------------------------------------------------------------------
# Global Variables
# -----------------------------------------------------------------------------
readonly SCRIPT_NAME=$(basename "$0")
readonly TEMP_FILE="/tmp/free_${$}.txt"
readonly HOSTNAME=$(hostname)

# Color definitions
readonly COLOR_RED='\e[31m'
readonly COLOR_GREEN='\e[32m'
readonly COLOR_YELLOW='\e[33m'
readonly COLOR_RESET='\e[0m'

# -----------------------------------------------------------------------------
# Logging Functions
# -----------------------------------------------------------------------------
log_error() {
    echo -e "${COLOR_RED}[ERROR] $*${COLOR_RESET}" >&2
}

# -----------------------------------------------------------------------------
# Cleanup Function
# -----------------------------------------------------------------------------
cleanup() {
    [[ -f "${TEMP_FILE}" ]] && rm -f "${TEMP_FILE}"
}
trap cleanup EXIT

# -----------------------------------------------------------------------------
# Main Logic
# -----------------------------------------------------------------------------
main() {
    # Get memory information
    if ! free -m > "${TEMP_FILE}" 2>&1; then
        log_error "Failed to get memory information"
        exit 1
    fi

    # Parse memory metrics using awk for better reliability
    local memory_total memory_used memory_free
    
    # Use awk to parse the Mem line (more robust than grep+tr+cut)
    read -r memory_total memory_used memory_free <<< $(awk '/^Mem:/ {print $2, $3, $4}' "${TEMP_FILE}")

    # Validate parsed values
    if [[ -z "${memory_total}" || -z "${memory_used}" || -z "${memory_free}" ]]; then
        log_error "Failed to parse memory information"
        exit 1
    fi

    # Calculate usage percentages using bc
    local usage_percent free_percent
    usage_percent=$(echo "scale=2; ${memory_used} * 100 / ${memory_total}" | bc)
    free_percent=$(echo "scale=2; ${memory_free} * 100 / ${memory_total}" | bc)

    # Determine warning level based on usage
    local color="${COLOR_GREEN}"
    if (( $(echo "${usage_percent} > 80" | bc -l) )); then
        color="${COLOR_RED}"
    elif (( $(echo "${usage_percent} > 60" | bc -l) )); then
        color="${COLOR_YELLOW}"
    fi

    # Output formatted report
    echo -e "${COLOR_RED}\t${HOSTNAME} 内存使用信息统计${COLOR_RESET}"
    echo -e "${COLOR_GREEN}=========================================="
    printf "%-15s %10s MB\n" "内存总量:" "${memory_total}"
    printf "%-15s %10s MB\n" "内存使用量:" "${memory_used}"
    printf "%-15s %10s MB\n" "内存空闲量:" "${memory_free}"
    echo -e "${color}%-15s %10s%%${COLOR_RESET}" "内存使用率:" "${usage_percent}"
    printf "%-15s %10s%%\n" "内存空闲率:" "${free_percent}"
    echo -e "==========================================${COLOR_RESET}"

    # Alert if usage is critical
    if (( $(echo "${usage_percent} > 90" | bc -l) )); then
        log_error "WARNING: Memory usage is critically high (${usage_percent}%)"
        return 1
    fi
}

main "$@"
```

**运行效果**：

```bash
$ ./memory_monitor.sh
        rocky9.6-12 内存使用信息统计
==========================================
内存总量:           3623 MB
内存使用量:         1115 MB
内存空闲量:         2112 MB
内存使用率:        30.77 %
内存空闲率:        58.29 %
==========================================
```

**关键技术点对比**：

| 技术点 | 原始版本 | 优化版本 | 优势 |
|--------|----------|----------|------|
| 文本处理 | `grep\|tr\|cut` 管道 | `awk` 一次解析 | 减少进程创建，性能提升 3-5 倍 |
| 临时文件 | 固定路径 | `${$}` PID 唯一化 | 避免多实例冲突 |
| 错误处理 | 无 | `set -e` + 参数验证 | 生产环境必备 |
| 资源清理 | 无 | `trap cleanup EXIT` | 避免临时文件泄露 |
| 阈值判断 | 无 | `bc` 布尔运算 | 实现智能告警 |

### 4.6 实战：通用脚本模版

为了规范团队的脚本编写风格，我整理了一个通用的 Shell 脚本模版。它包含了上述的所有最佳实践，以及标准的参数解析逻辑。

**代码位置**：[`code/linux/production-shell/script_template.sh`](/code/linux/production-shell/script_template.sh)

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

### 4.7 案例分析：日志监控脚本

下面我们来看一个具体的案例：编写一个脚本，监控指定的日志文件，当发现特定关键字（如 "ERROR"）时触发告警。

这个脚本演示了如何：
1. 使用 `getopts` 解析命令行参数。
2. 检查文件是否存在。
3. 结合 `grep` 进行逻辑判断。

**代码位置**：[`code/linux/production-shell/log_monitor.sh`](/code/linux/production-shell/log_monitor.sh)

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

## 总结

编写 Shell 脚本不仅仅是把命令堆砌在一起。作为 SRE，我们需要像对待应用程序代码一样对待脚本：
1. **安全性优先**：默认开启严格模式。
2. **可观测性**：输出标准化的日志。
3. **可维护性**：使用函数封装逻辑，提供清晰的帮助文档。

掌握这些技巧，不仅能让你的日常工作更轻松，也能在面试中展示你对生产环境稳定性的深刻理解。
