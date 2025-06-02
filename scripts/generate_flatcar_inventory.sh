#!/bin/bash
# filepath: scripts/generate_flatcar_inventory.sh

# This script generates inventory.ini for Flatcar nodes using hostnames and IPs from scripts/config.sh

CONFIG_FILE="scripts/config.sh"
INVENTORY_FILE="inventory.ini"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Config file $CONFIG_FILE not found!"
  exit 1
fi

# Source the config file to get variables
source "$CONFIG_FILE"

# Example expected variables in config.sh:
# MASTERS_NAME=("k8s-master01" "k8s-master02" "k8s-master03")
# MASTERS_IPADDR=("172.16.1.20" "172.16.1.21" "172.16.1.22")
# WORKERS_NAME=("k8s-worker01" "k8s-worker02" "k8s-worker03" "k8s-worker04")
# WORKERS_IPADDR=("172.16.1.40" "172.16.1.41" "172.16.1.42" "172.16.1.43")

echo "# ## Configure 'ip' variable to bind kubernetes services on a" > "$INVENTORY_FILE"
echo "# ## different ip than the default iface" >> "$INVENTORY_FILE"
echo "# ## We should set etcd_member_name for etcd cluster. The node that is not a etcd member do not need to set the value, or can set the empty string value." >> "$INVENTORY_FILE"
echo "[all]" >> "$INVENTORY_FILE"

# Masters
for i in "${!MASTERS_NAME[@]}"; do
  etcd_member="etcd$((i+1))"
  echo "${MASTERS_NAME[$i]} ansible_host=${MASTERS_IPADDR[$i]} etcd_member_name=$etcd_member ansible_user=core" >> "$INVENTORY_FILE"
done

# Workers
for i in "${!WORKERS_NAME[@]}"; do
  echo "${WORKERS_NAME[$i]} ansible_host=${WORKERS_IPADDR[$i]} etcd_member_name= ansible_user=core" >> "$INVENTORY_FILE"
done

echo "" >> "$INVENTORY_FILE"
echo "[kube_control_plane]" >> "$INVENTORY_FILE"
for h in "${MASTERS_NAME[@]}"; do
  echo "$h" >> "$INVENTORY_FILE"
done

echo "" >> "$INVENTORY_FILE"
echo "[etcd]" >> "$INVENTORY_FILE"
for h in "${MASTERS_NAME[@]}"; do
  echo "$h" >> "$INVENTORY_FILE"
done

echo "" >> "$INVENTORY_FILE"
echo "[kube_node]" >> "$INVENTORY_FILE"
for h in "${WORKERS_NAME[@]}"; do
  echo "$h" >> "$INVENTORY_FILE"
done

echo "" >> "$INVENTORY_FILE"
echo "[calico_rr]" >> "$INVENTORY_FILE"
echo "" >> "$INVENTORY_FILE"
echo "[k8s_cluster:children]" >> "$INVENTORY_FILE"
echo "kube_control_plane" >> "$INVENTORY_FILE"
echo "kube_node" >> "$INVENTORY_FILE"

echo "Inventory generated at $INVENTORY_FILE"
