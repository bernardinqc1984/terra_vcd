#!/bin/bash
# filepath: scripts/generate_flatcar_inventory.sh

# This script generates inventory.ini for Flatcar nodes using hostnames and IPs from scripts/config.sh

# Source common functions
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Required environment variables
required_vars=(
    "MASTERS_NAME" "MASTERS_IPADDR"
    "WORKERS_NAME" "WORKERS_IPADDR"
)

# Load configuration
load_config

# Validate required variables
validate_required_vars "${required_vars[@]}"

# Check arrays
if [[ ${#MASTERS_NAME[@]} -eq 0 ]]; then
    handle_error 1 "MASTERS_NAME array is empty"
fi
if [[ ${#WORKERS_NAME[@]} -eq 0 ]]; then
    handle_error 1 "WORKERS_NAME array is empty"
fi

# Path configuration
readonly INVENTORY_FILE="inventory.ini"

# Backup existing file
backup_file "${INVENTORY_FILE}"

# Generate inventory file
log_info "Generating inventory file: ${INVENTORY_FILE}"

{
    echo "# ## Configure 'ip' variable to bind kubernetes services on a"
    echo "# ## different ip than the default iface"
    echo "# ## We should set etcd_member_name for etcd cluster. The node that is not a etcd member do not need to set the value, or can set the empty string value."
    echo "[all]"

    # Masters
    for i in "${!MASTERS_NAME[@]}"; do
        etcd_member="etcd$((i+1))"
        echo "${MASTERS_NAME[$i]} ansible_host=${MASTERS_IPADDR[$i]} etcd_member_name=$etcd_member ansible_user=core"
    done

    # Workers
    for i in "${!WORKERS_NAME[@]}"; do
        echo "${WORKERS_NAME[$i]} ansible_host=${WORKERS_IPADDR[$i]} etcd_member_name= ansible_user=core"
    done

    echo ""
    echo "[kube_control_plane]"
    for h in "${MASTERS_NAME[@]}"; do
        echo "$h"
    done

    echo ""
    echo "[etcd]"
    for h in "${MASTERS_NAME[@]}"; do
        echo "$h"
    done

    echo ""
    echo "[kube_node]"
    for h in "${WORKERS_NAME[@]}"; do
        echo "$h"
    done

    echo ""
    echo "[calico_rr]"
    echo ""
    echo "[k8s_cluster:children]"
    echo "kube_control_plane"
    echo "kube_node"
} > "${INVENTORY_FILE}"

if [[ $? -eq 0 ]]; then
    log_success "Inventory file generated successfully at ${INVENTORY_FILE}"
else
    handle_error 1 "Failed to generate inventory file"
fi
