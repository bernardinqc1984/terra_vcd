#!/bin/bash

# Source common functions
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Script to generate install.yaml.tmpl files for controllers and workers
# This script should be run from the root directory of the project

# Determine the absolute path of the script
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONTROLLERS_DIR="${SCRIPT_DIR}/../controllers"
readonly WORKERS_DIR="${SCRIPT_DIR}/../workers"

# Function to generate the template content
generate_template() {
    local type=$1
    local output_file=$2
    
    log_info "Generating template for ${type}: ${output_file}"
    
    cat > "$output_file" << 'EOL'
---
variant: flatcar
version: 1.0.0
passwd:
  users:
    - name: core
      password_hash: $2y$10$GTZ/1rQpCgeKL39qy4un6.IM3bag86TnjUlsX0PXTQgBqljfNpZse
      groups:
        - docker
        - sudo
      ssh_authorized_keys:
        - "ssh-rsa PUBLIC_KEY"
storage:
  files:
    # Configure automatic updates without rebooting
    - path: /etc/flatcar/update.conf
      overwrite: true
      contents:
        inline: |
          REBOOT_STRATEGY=off
      mode: 0420 # Read-only for root
EOL

    cat >> "$output_file" << 'EOL'
    - path: /etc/motd.d/pi.conf
      mode: 0644
      contents:
        inline: This machine is dedicated to computing kubernetes

systemd:
  units:
    - name: getty@.service
      dropins:
        - name: 10-autologin.conf
          contents: |
            [Service]
            ExecStart=
            ExecStart=-/sbin/agetty --noclear %I $TERM
EOL

    # Generate ignition file from template
    log_info "Generating ignition file for ${type}"
    if ! docker run -i --rm quay.io/coreos/fcct --pretty --strict <"${output_file}" > "$(dirname "${output_file}")/install.ign"; then
        handle_error 1 "Failed to generate ignition file for ${type}"
    fi
}

# Main script execution
log_info "Generating install.yaml.tmpl files..."

# Create directories if they don't exist
ensure_directory "${CONTROLLERS_DIR}"
ensure_directory "${WORKERS_DIR}"

# Generate controller template
generate_template "controllers" "${CONTROLLERS_DIR}/install.yaml.tmpl"
log_success "Generated ${CONTROLLERS_DIR}/install.yaml.tmpl"

# Generate worker template
generate_template "workers" "${WORKERS_DIR}/install.yaml.tmpl"
log_success "Generated ${WORKERS_DIR}/install.yaml.tmpl"

log_success "Template generation completed successfully!" 
