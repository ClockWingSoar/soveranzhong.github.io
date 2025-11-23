#!/bin/bash
#
# Script Name: site_healthcheck.sh
# Description: Check website availability using wget or curl
# Author: clockwingsoar@outlook.com
# Date: 2025-11-23
# Version: 2.0 (Production-Ready)
#

set -euo pipefail

# -----------------------------------------------------------------------------
# Color definitions
# -----------------------------------------------------------------------------
readonly COLOR_GREEN='\e[32m'
readonly COLOR_RED='\e[31m'
readonly COLOR_RESET='\e[0m'

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------
usage() {
    echo -e "${COLOR_RED}用法: $0 <URL>${COLOR_RESET}" >&2
    echo "示例: $0 www.baidu.com" >&2
    exit 1
}

# -----------------------------------------------------------------------------
# Main Logic
# -----------------------------------------------------------------------------

# 1. Parameter Validation
if [ $# -ne 1 ]; then
    echo -e "${COLOR_RED}错误：请提供待测试站点域名${COLOR_RESET}" >&2
    usage
fi

readonly SITE_ADDR="$1"

# 2. Select Check Method
echo -e "${COLOR_GREEN}-----------检测平台支持的检测类型-----------"
echo "1: wget (推荐)"
echo "2: curl"
echo -e "----------------------------------------${COLOR_RESET}"

read -p "请输入网站的检测方法 [1/2]: " check_type

# 3. Perform Check
site_status="未知"

case "$check_type" in
    1)
        # wget: --spider (不下载), -T5 (超时5秒), -q (静默), -t2 (重试2次)
        if wget --spider -T5 -q -t2 "$SITE_ADDR"; then
            site_status="正常"
        else
            site_status="异常"
        fi
        ;;
    2)
        # curl: -s (静默), -o /dev/null (丢弃输出), --fail (HTTP错误返回非0)
        if curl -s -o /dev/null --fail "$SITE_ADDR"; then
             site_status="正常"
        else
             site_status="异常"
        fi
        ;;
    *)
        echo -e "${COLOR_RED}错误：无效的选择${COLOR_RESET}" >&2
        exit 1
        ;;
esac

# 4. Output Result
echo
echo -e "${COLOR_RED}\t站点状态信息${COLOR_RESET}"
echo -e "${COLOR_GREEN}================================${COLOR_RESET}"
echo "${SITE_ADDR} 站点状态: ${site_status}"
echo -e "${COLOR_GREEN}================================${COLOR_RESET}"
