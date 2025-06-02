#!/bin/bash

# Source common functions
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Required environment variables
required_vars=(
    "DNS_CLUSTER_ID" "DNS_DOMAIN" "VCD_VDC" "VCD_USER" "VCD_ORG" "VCD_URL"
    "EDGE_GATEWAY" "VCD_EXTERNAL_NETWORK_IP" "VCD_ALLOW_UNVERIFIED_SSL"
    "FLATCAR_CATALOG" "MACHINE_CIDR" "KUBERNETES_CLUSTER_CIDR" "KUBERNETES_SERVICE_CIDR"
    "FLATCAR_DNS_ADDRESSES" "CONTROL_PLANE_COUNT" "CONTROL_DISK" "MASTERS_IPADDR"
    "COMPUTE_COUNT" "COMPUTE_DISK" "WORKERS_IPADDR" "NFS_COMPUTE_IP_ADDRESSES"
    "FLATCAR_VERSION" "FLATCAR_TEMPLATE" "MASTERS_MACADDR" "WORKERS_MACADDR"
)

# Load configuration
load_config

# Validate required variables
validate_required_vars "${required_vars[@]}"

# Path configuration
readonly TFVARS_FILE="${SCRIPT_DIR}/../${VCD_ORG}-${DC}-${VCD_VDC}.tfvars"

# Backup existing file
backup_file "${TFVARS_FILE}"

# Generate IP addresses and MAC addresses for control plane and compute nodes
control_plane_ip_addresses=$(array_to_string MASTERS_IPADDR ", ")
compute_ip_addresses=$(array_to_string WORKERS_IPADDR ", ")
nfs_compute_ip_addresses=$(array_to_string NFS_COMPUTE_IP_ADDRESSES ", ")
dns_addresses=$(array_to_string FLATCAR_DNS_ADDRESSES ", ")
control_plane_mac_addresses=$(array_to_string MASTERS_MACADDR ", ")
compute_mac_addresses=$(array_to_string WORKERS_MACADDR ", ")

# Generate tfvars file
log_info "Generating tfvars file: ${TFVARS_FILE}"

cat <<EOF > "${TFVARS_FILE}"
# File automatically generated on $(date '+%Y-%m-%d %H:%M:%S')
# Do not modify manually

// ID identifying the cluster to create. Use your username so that resources created can be tracked back to you.
cluster_name = "${DNS_CLUSTER_ID}"

// Domain name for the cluster. This is used to create the DNS records for the cluster.
base_domain = "${DNS_DOMAIN}"

// Name of the VDC in which the cluster will be created.
vcd_vdc = "${VCD_VDC}"

// User name for the VCD account.
vcd_user = "${VCD_USER}"

// Organization name for the VCD account.
vcd_org = "${VCD_ORG}"

// URL of the VCD API endpoint.
vcd_url = "${VCD_URL}"

// Name of the edge gateway to use for the cluster.
edge_gateway = "${EDGE_GATEWAY}"

// IP address of the external network to use for the cluster.
vcd_external_network_ip = "${EXTERNAL_NETWORK_IP}"

// Allow unverified SSL connections to the VCD API. Set to true for testing purposes only.
vcd_allow_unverified_ssl = ${VCD_ALLOW_UNVERIFIED_SSL}

// Catalog name in VCD where the Flatcar images are stored.
vcd_catalog = "${FLATCAR_CATALOG}"

// CIDR block for the machine network. This is used to create the network for the cluster.
machine_cidr = "${MACHINE_CIDR}"

// DNS addresses for the cluster. This is used to create the DNS records for the cluster.
dns_addresses = [${dns_addresses}]

// CIDR block for the Kubernetes cluster network. This is used to create the network for the cluster.
kubernetes_cluster_cidr = "${KUBERNETES_CLUSTER_CIDR}"

// CIDR block for the Kubernetes service network. This is used to create the network for the cluster.
kubernetes_service_cidr = "${KUBERNETES_SERVICE_CIDR}"

// Number of control plane nodes to create. This is used to create the control plane for the cluster.
control_plane_count = ${CONTROL_PLANE_COUNT}

// Disk size for the control plane nodes. This is used to create the disks for the control plane.
control_disk = "${CONTROL_DISK}"

// IP addresses for the control plane nodes. This is used to create the control plane for the cluster.
control_plane_ip_addresses=[${control_plane_ip_addresses}]

// Number of compute nodes to create. This is used to create the compute nodes for the cluster.
compute_count = ${COMPUTE_COUNT}

// Disk size for the compute nodes. This is used to create the disks for the compute nodes.
compute_disk = "${COMPUTE_DISK}"

// IP addresses for the compute nodes. This is used to create the compute nodes for the cluster.
compute_ip_addresses = [${compute_ip_addresses}]

// IP addresses for the NFS compute nodes. This is used to create the NFS compute nodes for the cluster.
nfs_compute_ip_addresses = [${nfs_compute_ip_addresses}]

// Flatcar version to use for the cluster. This is used to create the Flatcar images for the cluster.
flatcar_version = "${FLATCAR_VERSION}"

// Template name for the Flatcar images. This is used to create the Flatcar images for the cluster.
flatcar_template = "${FLATCAR_TEMPLATE}"

// MAC addresses for the control plane nodes. This is used to create the MAC addresses for the control plane.
control_plane_mac_address = [${control_plane_mac_addresses}]

// MAC addresses for the compute nodes. This is used to create the MAC addresses for the compute nodes.
compute_compute_mac_addresses = [${compute_mac_addresses}]
EOF

if [[ $? -eq 0 ]]; then
    log_success "Tfvars file generated successfully"
    log_info "Generated file: ${TFVARS_FILE}"
else
    handle_error 1 "Failed to generate tfvars file"
fi
