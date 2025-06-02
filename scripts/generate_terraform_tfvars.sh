#!/bin/bash

# Source common functions
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Required environment variables
required_vars=(
    "VCD_ORG" "DC" "VCD_VDC" "VCD_USER" "VCD_PASSWORD" "VCD_URL"
    "VCD_ALLOW_UNVERIFIED_SSL" "VCD_EXTERNAL_NETWORK_IP" "VCD_EXTERNAL_NETWORK_NAME"
    "EDGE_GATEWAY" "NETWORK_NAME" "KUBERNETES_SUBNET" "KUBERNETES_GATEWAY"
    "KUBERNETES_PREFIX" "KUBERNETES_DNS1" "KUBERNETES_DNS2" "SHARED_SUBNET"
    "SHARED_GATEWAY" "SHARED_PREFIX" "SHARED_DNS1" "SHARED_DNS2" "JUMPBOX_IP"
    "NS_IP" "TRANSIT_SUBNET" "TRANSIT_GATEWAY" "TRANSIT_PREFIX" "TRANSIT_DNS1"
    "TRANSIT_DNS2" "HELPER_ENABLED" "HELPER_TEMPLATE" "LBVIP_IP" "LB_IPS"
    "CATALOG_PaaS"
)

# Load configuration
load_config

# Validate required variables
validate_required_vars "${required_vars[@]}"

# Path configuration
readonly TFVARS_DIR="bastion-env"
readonly TFVARS_FILE="${TFVARS_DIR}/${VCD_ORG}-${DC}-${VCD_VDC}.tfvars"

# Create directory and backup file if necessary
ensure_directory "${TFVARS_DIR}"
backup_file "${TFVARS_FILE}"

# Generate the tfvars file
log_info "Generating tfvars file: ${TFVARS_FILE}"

# Generate the list of allowed SSH sources
joined_fw=$(array_to_string FW_ALLOW_SSH_SOURCE ", ")

cat <<EOF > "${TFVARS_FILE}"
# File automatically generated on $(date '+%Y-%m-%d %H:%M:%S')
# Do not modify manually

# terraform.tfvars
vcd = {
  url = "${VCD_URL}"
  user = "${VCD_USER}"
  org = "${VCD_ORG}"
  vdc = "${VCD_VDC}"
  allow_unverified_ssl = "${VCD_ALLOW_UNVERIFIED_SSL}"
  external_network = {
    name = "${VCD_EXTERNAL_NETWORK_NAME}"
    ip = "${EXTERNAL_NETWORK_IP}"
  }
}
networking = {
  edge_gateway = "${EDGE_GATEWAY}"
  kubernetes = {
    subnet = "${KUBERNETES_SUBNET}"
    gateway = "${KUBERNETES_GATEWAY}"
    prefix = "${KUBERNETES_PREFIX}"
    dns_server = ["${KUBERNETES_DNS1}", "${KUBERNETES_DNS2}"]
  }
  transit = {
    subnet = "${TRANSIT_SUBNET}"
    gateway = "${TRANSIT_GATEWAY}"
    prefix = "${TRANSIT_PREFIX}"
    dns_server = ["${TRANSIT_DNS1}", "${TRANSIT_DNS2}"]
  }
  shared = {
    subnet = "${SHARED_SUBNET}"
    gateway = "${SHARED_GATEWAY}"
    prefix = "${SHARED_PREFIX}"
    dns_server = ["${SHARED_DNS1}", "${SHARED_DNS2}"]
    jumpbox_ip = "${JUMPBOX_IP}"
    ns_ips = ["${NS_IP}"]
    helper = {
      enabled = "${HELPER_ENABLED}"
      ip = "${NS_IP}"
      template = "${HELPER_TEMPLATE}"
    }
  }
  fw_rules = {
    allow_ssh_source = [${joined_fw}]
  }
}

services = {
  catalog = "${CATALOG_PaaS}"
  lb = {
    is_primary = true
    vip_ip = "${LBVIP_IP}"
    ips = ["${LB_IPS}"]
  }
}
EOF

if [[ $? -eq 0 ]]; then
    log_success "Tfvars file generated successfully"
    log_info "Generated file: ${TFVARS_FILE}"
else
    handle_error 1 "Failed to generate tfvars file"
fi

# Generate init_env tfvars file
TFVARS_INITENV_DIR="init_env"
TFVARS_INITENV_FILE="${TFVARS_INITENV_DIR}/${VCD_ORG}-${DC}-${VCD_VDC}.tfvars"

# Create directory and backup file if necessary
ensure_directory "${TFVARS_INITENV_DIR}"
backup_file "${TFVARS_INITENV_FILE}"

log_info "Generating init_env tfvars file: ${TFVARS_INITENV_FILE}"

cat > "${TFVARS_INITENV_FILE}" <<EOF
// Name of the VDC.
vcd_vdc = "${VCD_VDC}"

// User on the vSphere server.
vcd_user = "${VCD_USER}"

// Password of the user on vcd.
vcd_password = "${VCD_PASSWORD}"

// Name of the VCD organization. Found on the VCD console, Data Centers tab
vcd_org = "${VCD_ORG}"

// url for the vcd. (this is dal)
vcd_url = "${VCD_URL}"

// Name of the NSX-T Edge Gateway
edge_gateway_name = "${EDGE_GATEWAY}"
EOF

if [[ $? -eq 0 ]]; then
    log_success "Init env tfvars file generated successfully"
else
    handle_error 1 "Failed to generate init env tfvars file"
fi