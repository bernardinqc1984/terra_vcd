#!/bin/bash

# Source common functions
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Required environment variables
required_vars=("DNS_CLUSTERID" "EXTERNAL_NETWORK_IP")

# Load configuration
load_config

# Validate required variables
validate_required_vars "${required_vars[@]}"

# Path configuration
readonly INVENTORY_DIR="bastion-env/ansible/inventory"
readonly INVENTORY_FILE="${INVENTORY_DIR}/${DNS_CLUSTERID}-inventory"

# Create directory and backup file if necessary
ensure_directory "${INVENTORY_DIR}"
backup_file "${INVENTORY_FILE}"

# Check for SSH key existence
if [[ ! -f "${HOME}/.ssh/id_rsa" ]]; then
    handle_error 1 "SSH key ${HOME}/.ssh/id_rsa does not exist"
fi

# Generate inventory file
log_info "Generating inventory file: ${INVENTORY_FILE}"

cat <<EOF > "${INVENTORY_FILE}"
# Inventory automatically generated on $(date '+%Y-%m-%d %H:%M:%S')
# Do not modify manually

[bastion-vm]
bastion-vm_nsxt  ansible_host=${EXTERNAL_NETWORK_IP} ansible_port=8446 ansible_user=$(whoami) 

[lb]
lb-dev_stab ansible_host=${LB_IPADDR} ansible_user=$(whoami)

[nodes:children]
lb

[nodes:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -o StrictHostKeyChecking=no -l $(whoami) -p 8446 -W %h:%p -q ${EXTERNAL_NETWORK_IP}"'

[kube_dev:children]
nodes
bastion-vm

[kube_dev:vars]
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_become=yes
ansible_become_user=root
ansible_connection=ssh
EOF

if [[ $? -eq 0 ]]; then
    log_success "Inventory file generated successfully"
else
    handle_error 1 "Failed to generate inventory file"
fi