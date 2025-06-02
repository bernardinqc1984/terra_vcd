
# Add IP set for Shared
resource "vcd_nsxt_ip_set" "shared_net" {
  name        = "shared_net"
  description = "IP set for Shared"
  org         = var.vcd.org
  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id

  ip_addresses = [var.networking.shared.subnet]
}

# Org Routed Network - Shared
resource "vcd_network_routed_v2" "vnet_routed_shared" {
  name = "vnet-shared"
  org  = var.vcd.org

  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id

  gateway       = var.networking.shared.gateway
  prefix_length = var.networking.shared.prefix
  dns1          = var.networking.shared.dns_server[0]
  dns2          = var.networking.shared.dns_server[1]
}


# Attach routed network to Shared vApp
resource "vcd_vapp_org_network" "vapp_org_net_shared" {
  vapp_name        = vcd_vapp.vapp_shared.name
  reboot_vapp_on_removal = true
  org_network_name = vcd_network_routed_v2.vnet_routed_shared.name
}

# Create Shared vApp
resource "vcd_vapp" "vapp_shared" {
  name        = "vapp-shared"
  description = "Shared vApp"
  org         = var.vcd.org
  vdc         = var.vcd.vdc
}

# Module: Bastion VM
module "vm_bastion" {
  source = "./modules/vm"

  vapp_name = vcd_vapp.vapp_shared.name
  name      = "bastion-vm"

  network_name = vcd_vapp_org_network.vapp_org_net_shared.org_network_name
  memory       = var.jumpbox_memory
  cpus         = var.jumpbox_cpus
  power_on     = true

  ip         = [var.networking.shared.jumpbox_ip]
  temp_pass  = var.temp_pass
  initscript = templatefile("${path.module}/files/linux-initscript.sh", {})
}