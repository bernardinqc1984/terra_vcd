# config.sh

# Ansible USER
export ansible_ser="czogbelemou"

# General Configuration
export VCD_USER="api-platform"
export VCD_ORG="openshift_dev"
export VCD_VDC="vdc-openshift_dev_nsxt-other"
export VCD_URL="https://vcloud-qbc1.cirrusproject.ca/api"
export DC="qbc1"
export ENV="dev"
export CIRRUS_ENV="${ENV}"
export CIRRUS_DC="${DC}"
export VAR_FILE=""
export VCD_PASSWORD='cvF?hx!pKfee})r9?l%.'
export VCD_ALLOW_UNVERIFIED_SSL=true
export VCD_EXTERNAL_NETWORK_IP="ISP-67.217.232.0"

# S3 Configuration
export AWS_ACCESS_KEY_ID="c845719"
export AWS_SECRET_ACCESS_KEY="80VKjCotzJy9VlNjt8gXgMdmlMgF/tDFjz0C8E7w"
export AWS_REGION="${DC}"
export AWS_S3_ENDPOINT="https://cirrus-plateforme.os-qc1.cirrusproject.ca"
export AWS_KEY_BUCKET="flatcar-dev"
# External Network Configuration
export EXTERNAL_NETWORK_IP="67.217.232.5"
export VCD_EXTERNAL_NETWORK_NAME="ISP-67.217.232.0"

# Edge Gateway Configuration
export EDGE_GATEWAY="openshift_dev_nsxt T1 Edge"
export NETWORK_NAME="net-kubernetes" # example : vnet-kubernetes

# Terraform Configuration
export VAR_FILE="${VCD_ORG}-${CIRRUS_DC}-${VCD_VDC}.tfvars"

# Networks Configuration
export KUBERNETES_SUBNET="172.16.1.0/24"
export KUBERNETES_GATEWAY="172.16.1.1"
export KUBERNETES_PREFIX=24
export KUBERNETES_DNS1="1.1.1.1"
export KUBERNETES_DNS2="1.0.0.1"
export KUBERNETES_NET="net-kubernetes"
export NFS_STORAGE_NET="net-nfs"

# Shared Configuration
export SHARED_SUBNET="172.16.0.0/26"
export SHARED_GATEWAY="172.16.0.1"
export SHARED_PREFIX=24
export SHARED_DNS1="1.1.1.1"
export SHARED_DNS2="1.0.0.1"
export JUMPBOX_IP="172.16.0.15"
export NS_IP="${JUMPBOX_IP}"

# Transit (LB) Configuration
export TRANSIT_SUBNET="172.16.255.0/24"
export TRANSIT_GATEWAY="172.16.255.1"
export TRANSIT_PREFIX=26
export TRANSIT_DNS1="1.1.1.1"
export TRANSIT_DNS2="1.0.0.1"
export LBVIP_IP="172.16.255.2"
export LB_IPS="172.16.255.2"

# Helper Configuration
export HELPER_ENABLED=false
export HELPER_TEMPLATE="helper-vapp"

# Firewall Configuration
FW_ALLOW_SSH_SOURCE=(64.187.176.220 24.201.161.72 130.41.67.101)

# Catalog Configuration
export CATALOG_PaaS="Projet Cirrus - Rocky Linux 9.5 - EN - Template"

# Variables for Ansible playbook
export DISK="sda"
export HELPER_NAME="bastion-vm"
export HELPER_IPADDR="172.16.0.15"
export DNS_DOMAIN="cirrus.appcirrus.ca"
export DNS_CLUSTER_ID="kube-stab"
export DNS_FORWARDER1="1.1.1.1"
export DNS_FORWARDER2="1.0.0.1"
export DNS_SERVER_NAME="ns-cirrus-kube"
export DNS_EMAIL="czogbelemou@micrologic.ca"
export LB_NAME="lb-cirrus-kube"
export LB_IPADDR="172.16.255.2"
export DNS_CLUSTERID="kube-stab"
export DNS_NAME="ns-cirrus-kube"
export DNS_IPPADDR="${JUMPBOX_IP}"

# DHCP Configuration
export DHCP_NETWORKIFACENAME="en192"
export DHCP_ROUTER="172.16.1.1"
export DHCP_BCAST="172.16.0.255"
export DHCP_NETMASK="255.255.255.0"
export DHCP_POOLSTART="172.16.1.19"
export DHCP_POOLSEND="172.16.1.50"
export DHCP_IPID="172.16.1.0"
export DHCP_NETMASKID="255.255.255.0"
export DHCP_DNS="${JUMPBOX_IP}"

# Flatcar Configuration
export FLATCAR_VERSION="stable"
export FLATCAR_TEMPLATE="flatcar_production_vmware_ova"
export FLATCAR_CATALOG="Projet Cirrus - Catalogue Okd"
export MACHINE_CIDR="172.16.1.0/24"
export KUBERNETES_CLUSTER_CIDR="172.24.0.0/14"
export KUBERNETES_SERVICE_CIDR="172.30.0.0/16"
export FLATCAR_DNS_ADDRESSES=("${JUMPBOX_IP}" "${KUBERNETES_DNS1}")
export CONTROL_PLANE_COUNT=3
export CONTROL_DISK=50
export COMPUTE_COUNT=3
export COMPUTE_DISK=50
export NFS_COMPUTE_IP_ADDRESSES=("172.16.20.106" "172.16.20.107" "172.16.20.108")
export FLATCAR_PUBLIC_KEY=""

# Masters Configuration (arrays)
export MASTERS_NAME=("k8s-cp01" "k8s-cp02" "k8s-cp03")
export MASTERS_IPADDR=("172.16.1.20" "172.16.1.21" "172.16.1.22")
export MASTERS_MACADDR=("00:50:56:1f:03:a4" "00:50:56:1f:03:a8" "00:50:56:1f:03:a6")

# Worker configuration (arrays)
export WORKERS_NAME=("k8s-worker01" "k8s-worker02" "k8s-worker03")
export WORKERS_IPADDR=("172.16.1.40" "172.16.1.41" "172.16.1.42")
export WORKERS_MACADDR=("00:50:56:1f:03:a1" "00:50:56:1f:03:9b" "00:50:56:1f:03:a2")