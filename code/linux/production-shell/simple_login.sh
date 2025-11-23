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
