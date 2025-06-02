#!/bin/bash

# Strict bash options
set -euo pipefail
IFS=$'\n\t'

# Color definitions for output
readonly COLOR_INFO="\033[0;35m"
readonly COLOR_SUCCESS="\033[0;32m"
readonly COLOR_ERROR="\033[0;31m"
readonly COLOR_WARNING="\033[0;33m"
readonly COLOR_RESET="\033[0m"

# Script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Logging functions
log_info() {
    printf "${COLOR_INFO}INFO: %s${COLOR_RESET}\n" "$1"
}

log_success() {
    printf "${COLOR_SUCCESS}SUCCESS: %s${COLOR_RESET}\n" "$1"
}

log_error() {
    printf "${COLOR_ERROR}ERROR: %s${COLOR_RESET}\n" "$1" >&2
}

log_warning() {
    printf "${COLOR_WARNING}WARNING: %s${COLOR_RESET}\n" "$1"
}

# Error handling
handle_error() {
    local exit_code=$1
    local error_message=$2
    log_error "$error_message"
    exit "$exit_code"
}

# Directory operations
ensure_directory() {
    local dir=$1
    if [[ ! -d "$dir" ]]; then
        log_info "Creating directory: $dir"
        mkdir -p "$dir" || handle_error 1 "Failed to create directory: $dir"
    fi
}

# File backup
backup_file() {
    local file=$1
    if [[ -f "$file" ]]; then
        local backup_file="${file}.$(date +%Y%m%d_%H%M%S).bak"
        log_info "Backing up file: $file"
        cp "$file" "$backup_file" || handle_error 1 "Failed to backup file: $file"
    fi
}

# Environment variable validation
validate_required_vars() {
    local required_vars=("$@")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        handle_error 1 "Missing required environment variables: ${missing_vars[*]}"
    fi
}

# Configuration loading
load_config() {
    local config_file="${SCRIPT_DIR}/config.sh"
    if [[ ! -f "$config_file" ]]; then
        handle_error 1 "Configuration file not found: $config_file"
    fi
    
    log_info "Loading configuration from $config_file"
    source "$config_file" || handle_error 1 "Failed to load configuration from $config_file"
}

# Array to string conversion
array_to_string() {
    local -n arr=$1
    local delimiter=$2
    local result=""
    
    for item in "${arr[@]}"; do
        result+="${item}${delimiter}"
    done
    
    echo "${result%$delimiter}"
}

# IP address validation
validate_ip() {
    local ip=$1
    if [[ ! $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 1
    fi
    
    IFS='.' read -r -a ip_parts <<< "$ip"
    for part in "${ip_parts[@]}"; do
        if [[ $part -lt 0 || $part -gt 255 ]]; then
            return 1
        fi
    done
    
    return 0
}

# CIDR validation
validate_cidr() {
    local cidr=$1
    if [[ ! $cidr =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        return 1
    fi
    
    local ip=${cidr%/*}
    local prefix=${cidr#*/}
    
    if ! validate_ip "$ip"; then
        return 1
    fi
    
    if [[ $prefix -lt 0 || $prefix -gt 32 ]]; then
        return 1
    fi
    
    return 0
}

# MAC address validation
validate_mac() {
    local mac=$1
    if [[ ! $mac =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
        return 1
    fi
    return 0
}

# Export common variables
export SCRIPT_DIR
export COLOR_INFO COLOR_SUCCESS COLOR_ERROR COLOR_WARNING COLOR_RESET 