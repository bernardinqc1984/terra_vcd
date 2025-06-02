#!/usr/bin/env bash

# Configuration des options strictes
set -x -euo pipefail
IFS=$'\n\t'

# Variables en lecture seule
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_FILE="${SCRIPT_DIR}/scripts/config.sh"
readonly TERRAFORM_DIR="${SCRIPT_DIR}/bastion-env"
readonly ANSIBLE_DIR="${TERRAFORM_DIR}/ansible"
#readonly VCD_CONFIG_FILE="${TERRAFORM_DIR}/${VCD_ORG}-${DC}-${VCD_VDC}.config"


# Configuration des couleurs
readonly COLOR_INFO="\033[0;35m"
readonly COLOR_SUCCESS="\033[0;32m"
readonly COLOR_ERROR="\033[0;31m"
readonly COLOR_DIVIDER="\033[0;1m"
readonly COLOR_RESET="\033[0m"

# Configuration des outils requis
readonly REQUIRED_TOOLS=("tofu" "sed" "curl" "jq" "ansible-playbook")

# Gestion des signaux
interrupt_count=0
interrupt_handler() {
  ((interrupt_count++))
  echo ""
  if [[ ${interrupt_count} -eq 1 ]]; then
    error "Interruption détectée. Appuyez à nouveau sur Ctrl-C pour forcer l'arrêt."
  else
    error "Arrêt forcé. Au revoir !"
    exit 1
  fi
}
trap interrupt_handler SIGINT SIGTERM

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

divider() {
  printf "${COLOR_DIVIDER}============================================================================${COLOR_RESET}\n"
}

verify_last_command() {
  if [[ $? -ne 0 ]]; then
    error "Échec de la commande précédente"
    exit 1
  fi
}

check_required_tools() {
  info "Vérification des outils requis..."
  for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "${tool}" &> /dev/null; then
      error "${tool} est requis mais n'est pas installé."
      exit 1
    fi
  done
  success "Tous les outils requis sont présents."
}

cleanup_terraform() {
  local lock_file="../.terraform.lock.hcl"
  if [[ -d "../.terraform" && -f "${lock_file}" ]]; then
    info "Nettoyage des artefacts Terraform..."
    rm -rf "../.terraform" "${lock_file}"
    verify_last_command
    success "Nettoyage Terraform terminé."
  fi
}

run_step() {
  local message="$1"
  local command="$2"
  divider
  info "${message}"
  read -rsp $'Appuyez sur Entrée pour continuer (Ctrl-C pour annuler)...\n'
  eval "${command}"
  verify_last_command
  success "Étape terminée avec succès."
}

generate_configuration() {
  if [[ ! -f "${CONFIG_FILE}" ]]; then
    error "Le fichier ${CONFIG_FILE} n'existe pas"
    exit 1
  fi
    run_step "Génération du fichier de configuration" \
    "source ${CONFIG_FILE} && bash scripts/generate_config_file.sh"
}

generate_tfvars() {
  run_step "Génération des fichiers TFVARS" \
    "bash scripts/generate_terraform_tfvars.sh"
}

generate_flatcar_tfvars() {
  run_step "Génération des fichiers TFVARS" \
    "bash scripts/generate_flatcar_terraform_tfvars.sh"
}

generate_template() {
  run_step "Génération des fichiers de configuration Terraform" \
    "bash scripts/generate_install_templates.sh"
}

generate_inventory() {
  run_step "Génération du fichier d'inventaire Ansible" \
    "bash scripts/generate_inventory.sh"
}

generate_yaml() {
  run_step "Génération des fichiers YAML de configuration" \
    "bash scripts/generate_yaml.sh"
}

generate_ansible_vars_main_file() {
  run_step "Génération du fichier de variables Ansible" \
    "bash scripts/generate_ansible_vars_main_file.sh"
}

generate_flatcar_inventory() {
  run_step "Génération du fichier d'inventaire Ansible pour Flatcar" \
    "bash scripts/generate_flatcar_inventory.sh"
}

initialize_tofu() {
  source "${CONFIG_FILE}"
  if [[ ! -f "${CONFIG_FILE}" ]]; then
    error "Le fichier ${CONFIG_FILE} n'existe pas"
    exit 1
  fi
  readonly VCD_CONFIG_FILE="${TERRAFORM_DIR}/${VCD_ORG}-${DC}-${VCD_VDC}.config"
  run_step "Initialisation d'OpenTofu" \
    "cd ${TERRAFORM_DIR} && source ${VCD_CONFIG_FILE} && bash ${TERRAFORM_DIR}/init.sh"
}

plan_infrastructure() {
  run_step "Exécution du plan Terraform" \
    "tofu -chdir=${TERRAFORM_DIR} plan -var-file="${TERRAFORM_DIR}/${VCD_ORG}-${DC}-${VCD_VDC}.tfvars""
}

apply_infrastructure() {
  run_step "Application de la configuration Terraform" \
    "tofu -chdir=${TERRAFORM_DIR} apply -var-file="${TERRAFORM_DIR}/${VCD_ORG}-${DC}-${VCD_VDC}.tfvars" --auto-approve"
}

destroy_infrastructure() {
  run_step "Application de la configuration Terraform" \
    "tofu -chdir=${TERRAFORM_DIR} destroy -var-file="${TERRAFORM_DIR}/${VCD_ORG}-${DC}-${VCD_VDC}.tfvars" --auto-approve"
}

configure_bastion() {
  sleep 45
  run_step "Configuration du serveur Bastion" \
    "(cd ${ANSIBLE_DIR} && ansible-playbook -e @vars/${DNS_CLUSTER_ID}/config.yaml -i inventory/${DNS_CLUSTERID}-inventory bastion-vm.yml -e 'ansible_python_interpreter=/usr/bin/python3.9' -vvv)"
}

configure_loadbalancer() {
  run_step "Configuration du Load Balancer" \
    "(cd ${ANSIBLE_DIR} && ansible-playbook -e @vars/${DNS_CLUSTER_ID}/config.yaml -i inventory/${DNS_CLUSTERID}-inventory lb.yml -e 'ansible_python_interpreter=/usr/bin/python3.9' -vvv)"
}

transfert_archive() {
  run_step "Configuration du Load Balancer" \
    "(cd ${ANSIBLE_DIR} && ansible-playbook -e @vars/main.yml -i inventory/${DNS_CLUSTERID}-inventory archive_and_transfer_full_directory.yml -vvv)"
}

apply_init_env() {
  run_step "Application de la configuration Terraform (init_env)" \
    "tofu -chdir=${SCRIPT_DIR}/init_env init" 
    #tofu -chdir=${SCRIPT_DIR}/init_env apply --auto-approve
    tofu -chdir=${SCRIPT_DIR}/init_env destroy --auto-approve
}


main() {
  #check_required_tools
  #cleanup_terraform
  #generate_configuration
  #generate_tfvars
  #generate_flatcar_tfvars
  #generate_flatcar_inventory
  #generate_template
  #generate_inventory
  #generate_yaml
  # generate_ansible_vars_main_file
  apply_init_env
  #initialize_tofu
  #plan_infrastructure
  #apply_infrastructure
  #configure_bastion
  #configure_loadbalancer
  #transfert_archive
  #destroy_infrastructure
  success "Installation terminée avec succès !"
  info "Accès Bastion : ssh -J $(whoami)@${EXTERNAL_NETWORK_IP}:8446 $(whoami)@${JUMPBOX_IP}"
}

# Point d'entrée
main "$@"
