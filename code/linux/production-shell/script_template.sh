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
