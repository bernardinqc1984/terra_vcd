#!/bin/bash

# Configuring strict bash options
set -euo -x pipefail
IFS=$'\n\t'

# Configuring colors for messages
readonly COLOR_INFO="\033[0;35m"
readonly COLOR_SUCCESS="\033[0;32m"
readonly COLOR_ERROR="\033[0;31m"
readonly COLOR_RESET="\033[0m"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Fonctions utilitaires
info() {
    printf "${COLOR_INFO}INFO: %s${COLOR_RESET}\n" "$1"
}

success() {
    printf "${COLOR_SUCCESS}SUCCESS: %s${COLOR_RESET}\n" "$1"
}

error() {
    printf "${COLOR_ERROR}ERROR: %s${COLOR_RESET}\n" "$1" >&2
}

# Verifying the last command
verify_last_command() {
    if [[ $? -ne 0 ]]; then
        error "Échec de la commande précédente"
        exit 1
    fi
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

# Path configuration
readonly VARIABLES_DIR="bastion-env/ansible/vars"
readonly VARIABLE_MAIN_FILE="${VARIABLES_DIR}/main.yml"

# Create the destination directory if necessary 
if [[ ! -d "${VARIABLES_DIR}" ]]; then
    info "Création du répertoire de variables..."
    mkdir -p "${VARIABLES_DIR}"
fi
# Check if the main.yml file already exists 
if [[ -f "${VARIABLE_MAIN_FILE}" ]]; then
    info "Le fichier ${VARIABLE_MAIN_FILE} existe déjà. Il sera écrasé."
fi

# Create the main.yml file
info "Création du fichier ${VARIABLE_MAIN_FILE}..."
generate_main_file() {
    cat <<EOF > "${VARIABLE_MAIN_FILE}"
---
# Configuration générée automatiquement le $(date '+%Y-%m-%d %H:%M:%S')
# Ne pas modifier manuellement

cirrus_admin:
  - $(whoami)
EOF
}

# Generate the main.yml file
generate_main_file
verify_last_command
success "Fichier ${VARIABLE_MAIN_FILE} créé avec succès."