#!/bin/bash
# Script généré automatiquement pour sourcer la configuration

source "$(dirname "$0")/openshift_dev-qbc1-vdc-openshift_dev_nsxt-other.config"
sh init.sh
tofu destroy -auto-approve
