#!/bin/bash

# Source common functions
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Load configuration
load_config

# Path configuration
readonly VARIABLES_DIR="bastion-env/ansible/vars"
readonly VARIABLE_MAIN_FILE="${VARIABLES_DIR}/main.yml"

# Create directory and backup file if necessary
ensure_directory "${VARIABLES_DIR}"
backup_file "${VARIABLE_MAIN_FILE}"

# Generate main.yml file
log_info "Generating main.yml file: ${VARIABLE_MAIN_FILE}"

cat <<EOF > "${VARIABLE_MAIN_FILE}"
---
# Configuration automatically generated on $(date '+%Y-%m-%d %H:%M:%S')
# Do not modify manually

cirrus_admin:
  - $(whoami)
EOF

if [[ $? -eq 0 ]]; then
    log_success "Main.yml file generated successfully"
else
    handle_error 1 "Failed to generate main.yml file"
fi