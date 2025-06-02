# Transit Network NSX-T
resource "vcd_network_routed_v2" "vnet_routed_transit" {
  org  = var.vcd.org
  name = "vnet-transit"

  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id
  gateway         = var.networking.transit.gateway
  prefix_length   = var.networking.transit.prefix
  dns1            = var.networking.transit.dns_server[0]
  dns2            = var.networking.transit.dns_server[1]
}

# vApp LB
resource "vcd_vapp" "vapp_lb" {
  name        = "vapp-lb"
  description = "LB vApp"
  org         = var.vcd.org
}

# Network Attachment
resource "vcd_vapp_org_network" "vapp_org_vnet_transit" {
  vapp_name              = vcd_vapp.vapp_lb.name
  org_network_name       = vcd_network_routed_v2.vnet_routed_transit.name
  reboot_vapp_on_removal = true
}

# Module VM LB
module "vm_lb" {
  source = "./modules/vm"

  vapp_name    = vcd_vapp.vapp_lb.name
  name         = "lb"
  network_name = vcd_network_routed_v2.vnet_routed_transit.name
  memory       = var.lb_memory
  cpus         = var.lb_cpus
  power_on     = true
  ip           = var.services.lb.ips
  temp_pass    = var.temp_pass
  initscript   = templatefile("${path.module}/files/linux-initscript.sh", {})
}