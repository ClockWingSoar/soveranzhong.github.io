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
