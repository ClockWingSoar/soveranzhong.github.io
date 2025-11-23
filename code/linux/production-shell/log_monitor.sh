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
