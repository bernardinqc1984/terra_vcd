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

# Utility functions
info() {
    printf "${COLOR_INFO}INFO: %s${COLOR_RESET}\n" "$1"
}

success() {
    printf "${COLOR_SUCCESS}SUCCESS: %s${COLOR_RESET}\n" "$1"
}

error() {
    printf "${COLOR_ERROR}ERROR: %s${COLOR_RESET}\n" "$1" >&2
}

# Check for required environment variables
check_required_vars() {
    local required_vars=("VCD_ORG" "DC" "VCD_VDC" "ENV")
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            error "La variable ${var} n'est pas définie dans config.sh"
            exit 1
        fi
    done
}

# Ensure config.sh exists
if [[ ! -f "${SCRIPT_DIR}/config.sh" ]]; then
    error "Le fichier config.sh n'existe pas"
    exit 1
fi

# Load variables from config.sh
info "Chargement des variables depuis config.sh..."
source "${SCRIPT_DIR}/config.sh" || {
    error "Erreur lors du chargement de config.sh"
    exit 1
}

# Check required variables
check_required_vars

# Create the destination directory if necessary
readonly CONFIG_DIR="bastion-env"
if [[ ! -d "${CONFIG_DIR}" ]]; then
    info "Création du répertoire ${CONFIG_DIR}..."
    mkdir -p "${CONFIG_DIR}" || {
        error "Impossible de créer le répertoire ${CONFIG_DIR}"
        exit 1
    }
fi

# Define configuration files and their specific keys
declare -A CONFIG_FILES=(
    ["${CONFIG_DIR}/${VCD_ORG}-${DC}-${VCD_VDC}.config"]="terraform-${VCD_ORG}-${CIRRUS_DC}-${VCD_VDC}.tfstate"
    ["${SCRIPT_DIR}/../${VCD_ORG}-${DC}-${VCD_VDC}.config"]="terraform-flatcar-${VCD_ORG}-${CIRRUS_DC}-${VCD_VDC}.tfstate"
)

# Generate configuration files
for file in "${!CONFIG_FILES[@]}"; do
    info "Génération du fichier de configuration ${file}..."

    # Backup the old file if it exists
    if [[ -f "${file}" ]]; then
        BACKUP_FILE="${file}.$(date +%Y%m%d_%H%M%S).bak"
        info "Sauvegarde de l'ancien fichier de configuration..."
        cp "${file}" "${BACKUP_FILE}" || {
            error "Impossible de sauvegarder l'ancien fichier de configuration"
            exit 1
        }
    fi

    # Write the configuration file
    cat <<EOF > "${file}"
# Configuration générée automatiquement le $(date '+%Y-%m-%d %H:%M:%S')
# Ne pas modifier manuellement

# Désactivation des logs Terraform
unset TF_LOG
unset TF_LOG_PATH

# Variables d'environnement
CIRRUS_ENV=${ENV}
VCD_ORG=${VCD_ORG}
VCD_VDC=${VCD_VDC}
CIRRUS_DC=${DC}

# Configuration du backend S3
export BUCKET=openshift-terraform-${CIRRUS_ENV}
export KEY=${AWS_KEY_BUCKET}/${CONFIG_FILES[${file}]}
export AWS_REGION=${CIRRUS_DC}
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
export AWS_S3_ENDPOINT=https://cirrus-plateforme.os-qc1.cirrusproject.ca

# Variables Terraform
export TF_VAR_vcd_pass='${VCD_PASSWORD}'
export TF_CLI_ARGS_plan="-var-file=${VAR_FILE}"
export TF_CLI_ARGS_apply="-var-file=${VAR_FILE}"
export TF_CLI_ARGS_destroy="-var-file=${VAR_FILE}"
export TF_CLI_ARGS_import="-var-file=${VAR_FILE}"
EOF

    if [[ $? -eq 0 ]]; then
        success "Le fichier de configuration ${file} a été généré avec succès"
    else
        error "Erreur lors de la génération du fichier ${file}"
        exit 1
    fi
done

# Génération du script d'installation de Flatcar a partir du bastion
LAUNCH_SCRIPT="${SCRIPT_DIR}/../run-flatcar-kube.sh"
info "Génération du script d'exécution ${LAUNCH_SCRIPT}..."

cat <<EOF > "${LAUNCH_SCRIPT}"
#!/bin/bash
# Script généré automatiquement pour sourcer la configuration

PUB_KEY=\$(cat ~/.ssh/id_rsa.pub)

for rep in workers controllers; do
  if [ -f "\$rep/install.ign" ]; then
    # Remplace la ligne sshAuthorizedKeys dans le fichier JSON
    jq --arg key "\$PUB_KEY" '
      .passwd.users[].sshAuthorizedKeys = [\$key]
    ' "\$rep/install.ign" > "\$rep/install.ign.tmp" && mv "\$rep/install.ign.tmp" "\$rep/install.ign"
  fi
done

source "\$(dirname "\$0")/${VCD_ORG}-${DC}-${VCD_VDC}.config"
sh init.sh
tofu apply -auto-approve
EOF

chmod +x "${LAUNCH_SCRIPT}"

if [[ $? -eq 0 ]]; then
    success "Le script d'exécution ${LAUNCH_SCRIPT} a été généré avec succès"
else
    error "Erreur lors de la génération du script d'exécution"
    exit 1
fi

# Génération du script de désinstallation de Flatcar
DESTROY_SCRIPT="${SCRIPT_DIR}/../destroy-flatcar-kube.sh"
info "Génération du script ${DESTROY_SCRIPT}"


cat <<EOF > "${DESTROY_SCRIPT}"
#!/bin/bash
# Script généré automatiquement pour sourcer la configuration

source "\$(dirname "\$0")/${VCD_ORG}-${DC}-${VCD_VDC}.config"
sh init.sh
tofu destroy -auto-approve
EOF

chmod +x "${LAUNCH_SCRIPT}"

if [[ $? -eq 0 ]]; then
    success "Le script d'exécution ${LAUNCH_SCRIPT} a été généré avec succès"
else
    error "Erreur lors de la génération du script d'exécution"
    exit 1
fi
