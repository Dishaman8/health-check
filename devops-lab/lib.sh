#! /usr/bin/env bash
# lib.sh - library functions for bash scripts
#Author: Mustafa Ismail | Date: 25-sep-2025

LOG_FILE="${LOG_FILE:-/var/log/devops-toolkit.log}"

log_info() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] $*" >> "$LOG_FILE"; }
log_warn() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [WARN] $*" >> "$LOG_FILE"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $*" | tee -a "$LOG_FILE" >&2; }

check_root() { 
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root."
        exit 1
    fi
}

command_exists() { command -v "$1" >/dev/null 2>&1; }
