#!/bin/bash

# Configuring strict bash options
set -x -euo pipefail
IFS=$'\n\t'

# Configuring colors for messages
readonly COLOR_INFO="\033[0;35m"
readonly COLOR_SUCCESS="\033[0;32m"
readonly COLOR_ERROR="\033[0;31m"
readonly COLOR_RESET="\033[0m"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Utility functions for messages
info() {
    printf "${COLOR_INFO}INFO: %s${COLOR_RESET}\n" "$1"
}

success() {
    printf "${COLOR_SUCCESS}SUCCESS: %s${COLOR_RESET}\n" "$1"
}

error() {
    printf "${COLOR_ERROR}ERROR: %s${COLOR_RESET}\n" "$1" >&2
}

# Checking for required environment variables
check_required_vars() {
    local required_vars=(
        "VCD_ORG" "DC" "VCD_VDC" "VCD_USER" "VCD_PASSWORD" "VCD_URL"
        "VCD_ALLOW_UNVERIFIED_SSL" "VCD_EXTERNAL_NETWORK_IP" "VCD_EXTERNAL_NETWORK_NAME"
        "EDGE_GATEWAY" "NETWORK_NAME" "KUBERNETES_SUBNET" "KUBERNETES_GATEWAY"
        "KUBERNETES_PREFIX" "KUBERNETES_DNS1" "KUBERNETES_DNS2" "SHARED_SUBNET"
        "SHARED_GATEWAY" "SHARED_PREFIX" "SHARED_DNS1" "SHARED_DNS2" "JUMPBOX_IP"
        "NS_IP" "TRANSIT_SUBNET" "TRANSIT_GATEWAY" "TRANSIT_PREFIX" "TRANSIT_DNS1"
        "TRANSIT_DNS2" "HELPER_ENABLED" "HELPER_TEMPLATE" "LBVIP_IP" "LB_IPS"
        "CATALOG_PaaS"
    )
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            error "La variable ${var} n'est pas définie dans config.sh"
            exit 1
        fi
    done
}

# Checking for the existence of the config.sh file
if [[ ! -f "${SCRIPT_DIR}/config.sh" ]]; then
    error "Le fichier config.sh n'existe pas"
    exit 1
fi

# Loading variables from config.sh
info "Chargement des variables depuis config.sh..."
source ${SCRIPT_DIR}/config.sh || {
    error "Erreur lors du chargement de config.sh"
    exit 1
}


# Checking the required variables
check_required_vars

# Path configuration
readonly TFVARS_DIR="bastion-env"
readonly TFVARS_FILE="${TFVARS_DIR}/${VCD_ORG}-${DC}-${VCD_VDC}.tfvars"

# Create directory if necessary
if [[ ! -d "${TFVARS_DIR}" ]]; then
    info "Création du répertoire ${TFVARS_DIR}..."
    mkdir -p "${TFVARS_DIR}" || {
        error "Impossible de créer le répertoire ${TFVARS_DIR}"
        exit 1
    }
fi

# Backup the old file if it exists
if [[ -f "${TFVARS_FILE}" ]]; then
    readonly BACKUP_FILE="${TFVARS_FILE}.$(date +%Y%m%d_%H%M%S).bak"
    info "Sauvegarde de l'ancien fichier tfvars..."
    cp "${TFVARS_FILE}" "${BACKUP_FILE}" || {
        error "Impossible de sauvegarder l'ancien fichier tfvars"
        exit 1
    }
fi

# Generating the tfvars file
info "Génération du fichier tfvars ${TFVARS_FILE}..."

# Generating the list of allowed SSH sources
joined_fw=$(printf '"%s", ' "${FW_ALLOW_SSH_SOURCE[@]}")
joined_fw=${joined_fw%, }

cat <<EOF > "${TFVARS_FILE}"
# Fichier généré automatiquement le $(date '+%Y-%m-%d %H:%M:%S')
# Ne pas modifier manuellement

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
    success "Le fichier tfvars a été généré avec succès"
    info "Fichier généré : ${TFVARS_FILE}"
else
    error "Erreur lors de la génération du fichier tfvars"
    exit 1
fi

# Génération dynamique du nom de fichier tfvars pour init_env
TFVARS_INITENV_DIR="init_env"
TFVARS_INITENV_FILE="${TFVARS_INITENV_DIR}/${VCD_ORG}-${DC}-${VCD_VDC}.tfvars"

# Création du répertoire si besoin
if [[ ! -d "${TFVARS_INITENV_DIR}" ]]; then
    info "Création du répertoire ${TFVARS_INITENV_DIR}..."
    mkdir -p "${TFVARS_INITENV_DIR}" || {
        error "Impossible de créer le répertoire ${TFVARS_INITENV_DIR}"
        exit 1
    }
fi

info "Génération du fichier tfvars ${TFVARS_INITENV_FILE}..."

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
    success "Le fichier ${TFVARS_INITENV_FILE} a été généré avec succès"
else
    error "Erreur lors de la génération du fichier ${TFVARS_INITENV_FILE}"
    exit 1
fi