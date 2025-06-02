#!/bin/bash

# Source common functions
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Required environment variables
required_vars=("VCD_ORG" "DC" "VCD_VDC" "ENV")

# Load configuration
load_config

# Validate required variables
validate_required_vars "${required_vars[@]}"

# Create the destination directory if necessary
readonly CONFIG_DIR="bastion-env"
ensure_directory "${CONFIG_DIR}"

# Define configuration files and their specific keys
declare -A CONFIG_FILES=(
    ["${CONFIG_DIR}/${VCD_ORG}-${DC}-${VCD_VDC}.config"]="terraform-${VCD_ORG}-${CIRRUS_DC}-${VCD_VDC}.tfstate"
    ["${SCRIPT_DIR}/../${VCD_ORG}-${DC}-${VCD_VDC}.config"]="terraform-flatcar-${VCD_ORG}-${CIRRUS_DC}-${VCD_VDC}.tfstate"
)

# Generate configuration files
for file in "${!CONFIG_FILES[@]}"; do
    log_info "Generating configuration file: ${file}"

    # Backup existing file
    backup_file "${file}"

    # Write the configuration file
    cat <<EOF > "${file}"
# Configuration automatically generated on $(date '+%Y-%m-%d %H:%M:%S')
# Do not modify manually

# Disable Terraform logs
unset TF_LOG
unset TF_LOG_PATH

# Environment variables
CIRRUS_ENV=${ENV}
VCD_ORG=${VCD_ORG}
VCD_VDC=${VCD_VDC}
CIRRUS_DC=${DC}

# S3 backend configuration
export BUCKET=openshift-terraform-${CIRRUS_ENV}
export KEY=${AWS_KEY_BUCKET}/${CONFIG_FILES[${file}]}
export AWS_REGION=${CIRRUS_DC}
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
export AWS_S3_ENDPOINT=https://cirrus-plateforme.os-qc1.cirrusproject.ca

# Terraform variables
export TF_VAR_vcd_pass='${VCD_PASSWORD}'
export TF_CLI_ARGS_plan="-var-file=${VAR_FILE}"
export TF_CLI_ARGS_apply="-var-file=${VAR_FILE}"
export TF_CLI_ARGS_destroy="-var-file=${VAR_FILE}"
export TF_CLI_ARGS_import="-var-file=${VAR_FILE}"
EOF

    if [[ $? -eq 0 ]]; then
        log_success "Configuration file ${file} generated successfully"
    else
        handle_error 1 "Failed to generate configuration file ${file}"
    fi
done

# Generate Flatcar installation script from bastion
LAUNCH_SCRIPT="${SCRIPT_DIR}/../run-flatcar-kube.sh"
log_info "Generating execution script: ${LAUNCH_SCRIPT}"

cat <<EOF > "${LAUNCH_SCRIPT}"
#!/bin/bash
# Automatically generated script to source configuration

PUB_KEY=\$(cat ~/.ssh/id_rsa.pub)

for rep in workers controllers; do
  if [ -f "\$rep/install.ign" ]; then
    # Replace sshAuthorizedKeys line in JSON file
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
    log_success "Execution script ${LAUNCH_SCRIPT} generated successfully"
else
    handle_error 1 "Failed to generate execution script"
fi

# Generate Flatcar uninstallation script
DESTROY_SCRIPT="${SCRIPT_DIR}/../destroy-flatcar-kube.sh"
log_info "Generating script: ${DESTROY_SCRIPT}"

cat <<EOF > "${DESTROY_SCRIPT}"
#!/bin/bash
# Automatically generated script to source configuration

source "\$(dirname "\$0")/${VCD_ORG}-${DC}-${VCD_VDC}.config"
sh init.sh
tofu destroy -auto-approve
EOF

chmod +x "${DESTROY_SCRIPT}"

if [[ $? -eq 0 ]]; then
    log_success "Uninstallation script ${DESTROY_SCRIPT} generated successfully"
else
    handle_error 1 "Failed to generate uninstallation script"
fi
