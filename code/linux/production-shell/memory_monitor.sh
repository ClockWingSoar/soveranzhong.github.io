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
