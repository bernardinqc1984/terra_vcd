# Add IP set for Kubernetes
resource "vcd_nsxt_ip_set" "kubernetes_net" {
  name        = "kubernetes_net"
  description = "IP set for Kubernetes"
  org         = var.vcd.org
  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id

  ip_addresses = [var.networking.kubernetes.subnet]
}

# Add IP set for Transit
resource "vcd_nsxt_ip_set" "transit_net" {
  name        = "transit_net"
  description = "IP set for Transit"
  org         = var.vcd.org
  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id

  ip_addresses = [var.networking.transit.subnet]
}

# Kubernetes Network Configuration
resource "vcd_network_routed_v2" "kubernetes_net_routed" {
  name            = "vnet-kubernetes" 
  org             = var.vcd.org
  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id

  gateway       = var.networking.kubernetes.gateway
  prefix_length = var.networking.kubernetes.prefix
  dns1          = var.networking.kubernetes.dns_server[0]
  dns2          = var.networking.kubernetes.dns_server[1]
}


# Firewall Rules
resource "vcd_nsxt_firewall" "kubernetes_to_transit" {
  org             = var.vcd.org
  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id

  rule {
    name        = "kubernetes-to-transit"
    direction   = "IN_OUT"
    ip_protocol = "IPV4"
    action      = "ALLOW"

    source_ids      = [vcd_nsxt_ip_set.kubernetes_net.id]
    destination_ids = [vcd_nsxt_ip_set.transit_net.id]
    enabled        = true
    logging        = false

    app_port_profile_ids = [
      data.vcd_nsxt_app_port_profile.http.id,  # native profile
      data.vcd_nsxt_app_port_profile.https.id, # native profile
      data.vcd_nsxt_app_port_profile.api.id         # custom profile
    ]
  }
}

# DHCP Relay
resource "vcd_nsxt_edgegateway_dhcp_forwarding" "relay_config" {
  org             = var.vcd.org

  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id

  enabled         = true
  dhcp_servers    = [var.networking.shared.ns_ips[0]]
}

# DHCP Relay for Kubernetes Network
resource "vcd_nsxt_network_dhcp" "kubernetes_dhcp" {
  org = var.vcd.org

  org_network_id = vcd_network_routed_v2.kubernetes_net_routed.id
  # DHCP forwarding must be configured on NSX-T Edge Gateway
  # for RELAY mode
  mode = "RELAY"
}



# DNS Forwarding
/*
resource "vcd_nsxt_edgegateway_dns" "k8s_dns" {
  org             = var.vcd.org

  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id

  enabled         = true

  default_forwarder_zone {
    name = "k8s-default"

    upstream_servers = [
      var.networking.shared.ns_ips[0],
    ]
  }

  conditional_forwarder_zone {
    name = "conditional_testing"

    upstream_servers = [
      var.networking.kubernetes.dns_server[0],
    ]

    domain_names = [
      "kube-stab.cirrus.appcirrus.ca",
      "cirrus.appcirrus.ca",
    ]
  }
}
*/

# vApp Kubernetes 
resource "vcd_vapp" "kubernetes_vapp" {
  name        = "vapp-kubernetes"
  description = "K8s vApp"
  org         = var.vcd.org
}

# Network Attachment
resource "vcd_vapp_org_network" "kubernetes_vapp_org_net" {
  vapp_name        = vcd_vapp.kubernetes_vapp.name
  org_network_name = vcd_network_routed_v2.kubernetes_net_routed.name
}

# VM Helper
resource "vcd_vapp_vm" "kubernetes_helper" {
  count = var.networking.shared.helper.enabled ? 1 : 0

  vapp_name     = vcd_vapp.kubernetes_vapp.name
  name          = "kubernetes-helper"
  org           = var.vcd.org
  catalog_name  = var.services.catalog
  template_name = var.networking.shared.helper.template
  memory        = 8192
  cpus          = 4
  cpu_cores     = 2
  power_on      = true

  network {
    type               = "org"
    name               = vcd_network_routed_v2.kubernetes_net_routed.name
    ip_allocation_mode = "MANUAL"
    ip                 = var.networking.shared.helper.ip
    is_primary         = true
    adapter_type       = "VMXNET3"
  }
}