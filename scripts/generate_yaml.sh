#!/bin/bash

# Source common functions
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Required environment variables
required_vars=(
    "DNS_CLUSTER_ID" "DISK" "HELPER_NAME" "HELPER_IPADDR"
    "DNS_DOMAIN" "DNS_CLUSTERID" "DNS_FORWARDER1" "DNS_FORWARDER2"
    "DNS_NAME" "DNS_IPPADDR" "DNS_EMAIL" "LB_NAME" "LB_IPADDR"
    "DHCP_ROUTER" "DHCP_BCAST" "DHCP_NETMASK" "DHCP_POOLSTART"
    "DHCP_POOLSEND" "DHCP_IPID" "DHCP_NETMASKID" "DHCP_DNS"
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
readonly GROUP_VARS_DIR="bastion-env/ansible/inventory/group_vars"
readonly HOST_VARS_DIR="bastion-env/ansible/inventory/host_vars"
readonly VARS_DIR="bastion-env/ansible/vars/${DNS_CLUSTER_ID}"
readonly YAML_FILE="${GROUP_VARS_DIR}/${DNS_CLUSTER_ID}.yaml"
readonly HOST_VARS_FILE="${HOST_VARS_DIR}/${DNS_CLUSTER_ID}.yaml"
readonly VARS_YAML_FILE="${VARS_DIR}/config.yaml"

# Create necessary directories
for dir in "${GROUP_VARS_DIR}" "${VARS_DIR}"; do
    ensure_directory "${dir}"
done

# YAML content generation function
generate_yaml_content() {
    local file="$1"
    log_info "Generating YAML file: ${file}"

    # Backup existing file
    backup_file "${file}"

    # Generate YAML content
    cat <<EOF > "${file}"
---
# File automatically generated on $(date '+%Y-%m-%d %H:%M:%S')
# Do not modify manually

disk: ${DISK}
helper:
  name: "${HELPER_NAME}"
  ipaddr: "${HELPER_IPADDR}"
dns:
  domain: "${DNS_DOMAIN}"
  clusterid: "${DNS_CLUSTERID}"
  forwarder1: "${DNS_FORWARDER1}"
  forwarder2: "${DNS_FORWARDER2}"
  name: "${DNS_NAME}"
  ipaddr: "${DNS_IPPADDR}"
  email: "${DNS_EMAIL}"
lb:
  name: "${LB_NAME}"
  ipaddr: "${LB_IPADDR}"
dhcp:
  networkifacename: "ens160"
  router: "${DHCP_ROUTER}"
  bcast: "${DHCP_BCAST}"
  netmask: "${DHCP_NETMASK}"
  poolstart: "${DHCP_POOLSTART}"
  poolend: "${DHCP_POOLSEND}"
  ipid: "${DHCP_IPID}"
  netmaskid: "${DHCP_NETMASKID}"
  dns: "${DHCP_DNS}"
masters:
EOF

    # Generate Control Plane nodes
    for i in "${!MASTERS_NAME[@]}"; do
        cat <<EOF >> "${file}"
  - name: "${MASTERS_NAME[$i]}"
    ipaddr: "${MASTERS_IPADDR[$i]}"
    macaddr: "${MASTERS_MACADDR[$i]}"
EOF
    done

    # Generate Worker nodes
    cat <<EOF >> "${file}"
workers:
EOF
    for i in "${!WORKERS_NAME[@]}"; do
        cat <<EOF >> "${file}"
  - name: "${WORKERS_NAME[$i]}"
    ipaddr: "${WORKERS_IPADDR[$i]}"
    macaddr: "${WORKERS_MACADDR[$i]}"
EOF
    done
}

# Generate YAML files
generate_yaml_content "${YAML_FILE}"
generate_yaml_content "${VARS_YAML_FILE}"
generate_yaml_content "${HOST_VARS_FILE}"

log_success "YAML files generated successfully"
log_info "Generated files:"
log_info "  - ${YAML_FILE}"
log_info "  - ${VARS_YAML_FILE}"
log_info "  - ${HOST_VARS_FILE}"