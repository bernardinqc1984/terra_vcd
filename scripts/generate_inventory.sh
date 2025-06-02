#!/bin/bash

# Configuring strict bash options
set -euo pipefail
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
    local required_vars=("DNS_CLUSTERID" "EXTERNAL_NETWORK_IP")
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
readonly INVENTORY_DIR="bastion-env/ansible/inventory"
readonly INVENTORY_FILE="${INVENTORY_DIR}/${DNS_CLUSTERID}-inventory"

# Create the destination directory if necessary
if [[ ! -d "${INVENTORY_DIR}" ]]; then
    info "Création du répertoire d'inventaire..."
    mkdir -p "${INVENTORY_DIR}" || {
        error "Impossible de créer le répertoire d'inventaire"
        exit 1
    }
fi

# Backup the old file if it exists
if [[ -f "${INVENTORY_FILE}" ]]; then
    readonly BACKUP_FILE="${INVENTORY_FILE}.$(date +%Y%m%d_%H%M%S).bak"
    info "Sauvegarde de l'ancien fichier d'inventaire..."
    cp "${INVENTORY_FILE}" "${BACKUP_FILE}" || {
        error "Impossible de sauvegarder l'ancien fichier d'inventaire"
        exit 1
    }
fi

# Checking for SSH key existence
if [[ ! -f "${HOME}/.ssh/id_rsa" ]]; then
    error "La clé SSH ${HOME}/.ssh/id_rsa n'existe pas"
    exit 1
fi

# Generating the inventory file
info "Génération du fichier d'inventaire ${INVENTORY_FILE}..."

cat <<EOF > "${INVENTORY_FILE}"
# Inventaire généré automatiquement le $(date '+%Y-%m-%d %H:%M:%S')
# Ne pas modifier manuellement

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
    success "Le fichier d'inventaire a été généré avec succès"
else
    error "Erreur lors de la génération du fichier d'inventaire"
    exit 1
fi