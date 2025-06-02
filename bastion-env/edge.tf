# Configuration Edge Gateway NSX-T
data "vcd_nsxt_edgegateway" "mygw" {
  org  = var.vcd.org
  name = var.networking.edge_gateway
}

# Retrieve http app port profile
data "vcd_nsxt_app_port_profile" "http" {
  scope = "SYSTEM"
  name  = "HTTP"
}

# Retrieve https app port profile
data "vcd_nsxt_app_port_profile" "https" {
  scope = "SYSTEM"
  name  = "HTTPS"
}

# Retrieve api app port profile
data "vcd_nsxt_app_port_profile" "api" {
  scope = "TENANT"
  name  = "Custom_api_6443"
}
# Retrieve haproxyadmin app port profile
data "vcd_nsxt_app_port_profile" "haproxyadmin" {
  scope = "TENANT"
  name  = "HAProxy admin Port"
}

# Retrieve ssh app port profile
data "vcd_nsxt_app_port_profile" "ssh" {
  scope = "SYSTEM"
  name  = "SSH"
}

# Retrieve custom ssh app port profile
data "vcd_nsxt_app_port_profile" "custom_ssh_8446" {
  scope = "TENANT"
  name  = "Custom_ssh_8446"
}

# Retrieve dns app port profile
data "vcd_nsxt_app_port_profile" "dns" {
  scope = "TENANT"
  name  = "DNS"
}

# Retrieve dhcp app port profile
data "vcd_nsxt_app_port_profile" "dhcp" {
  scope = "TENANT"
  name  = "DHCP"
}

# Retrieve ntp app port profile
data "vcd_nsxt_app_port_profile" "ntp" {
  scope = "SYSTEM"
  name  = "NTP"
}

# Retrieve http 8080 app port profile
data "vcd_nsxt_app_port_profile" "http_8080" {
  scope = "TENANT"
  name  = "HTTP-8080-Custom"
}


# Add IP Set  the jumpbox
resource "vcd_nsxt_ip_set" "allow_ssh_source" {
  org = var.vcd.org

  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id

  name = "Allow SSH Sources"

  description = "IP addresses allowed to SSH into the jumpbox"
  ip_addresses = var.networking.fw_rules.allow_ssh_source
}

# Add IP Set for the External Network
resource "vcd_nsxt_ip_set" "external_network_ip" {
  org = var.vcd.org
  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id
  name = "External Network"
  description = "IP addresses of the external network"
  ip_addresses = [var.vcd.external_network.ip]
}

# Add IP Set for Any
resource "vcd_nsxt_ip_set" "any" {
  org = var.vcd.org
  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id
  name = "Any IP"
  description = "Any IP address"
  ip_addresses = ["0.0.0.0/0"] 
}

# Add IP Set for the Kubernetes Network
resource "vcd_nsxt_ip_set" "kubernetes_network_ip" {
  org = var.vcd.org
  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id
  name = "Kubernetes Network"
  description = "IP addresses of the Kubernetes network"
  ip_addresses = [var.networking.kubernetes.subnet]
}
# Add IP Set for the Transit Network
resource "vcd_nsxt_ip_set" "transit_network_ip" {
  org = var.vcd.org
  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id
  name = "Transit Network"
  description = "IP addresses of the Transit network"
  ip_addresses = [var.networking.transit.subnet]
}
# Add IP Set for the Shared Network
resource "vcd_nsxt_ip_set" "shared_network_ip" {
  org = var.vcd.org
  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id
  name = "Shared Network"
  description = "IP addresses of the Shared network"
  ip_addresses = [var.networking.shared.subnet]
}

# Firewall consolidé avec paramètres complets
resource  "vcd_nsxt_firewall" "cirrus_k8s" {
  org             = var.vcd.org

  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id

  rule {
    name        = "haproxy admin inbound"
    direction   = "IN"
    ip_protocol = "IPV4"
    action      = "ALLOW"
    enabled     = true
    logging     = true

    source_ids           = [vcd_nsxt_ip_set.allow_ssh_source.id]
    destination_ids      = [vcd_nsxt_ip_set.external_network_ip.id]
    app_port_profile_ids = [data.vcd_nsxt_app_port_profile.haproxyadmin.id]
  }

  rule {
    name        = "jumpbox ssh inbound"
    direction   = "IN"
    ip_protocol = "IPV4"
    action      = "ALLOW"
    enabled     = true
    logging     = true

    source_ids           = [vcd_nsxt_ip_set.allow_ssh_source.id]
    destination_ids      = [vcd_nsxt_ip_set.external_network_ip.id]
    app_port_profile_ids = [data.vcd_nsxt_app_port_profile.custom_ssh_8446.id]  
  }

  rule {
    name        = "transit to kubernetes"
    direction   = "IN_OUT"
    ip_protocol = "IPV4"
    action      = "ALLOW"
    enabled     = true
    logging     = true

    source_ids      = [vcd_nsxt_ip_set.transit_network_ip.id]
    destination_ids = [vcd_nsxt_ip_set.kubernetes_net.id]
    app_port_profile_ids = [
      data.vcd_nsxt_app_port_profile.http.id,
      data.vcd_nsxt_app_port_profile.https.id,
      data.vcd_nsxt_app_port_profile.api.id
    ]
  }

  rule {
    name        = "api external access"
    direction   = "IN"
    ip_protocol = "IPV4"
    action      = "ALLOW"
    enabled     = true
    logging     = true

    source_ids           = [vcd_nsxt_ip_set.allow_ssh_source.id]
    destination_ids      = [vcd_nsxt_ip_set.external_network_ip.id]
    app_port_profile_ids = [data.vcd_nsxt_app_port_profile.api.id]
  }

  rule {
    name        = "lb traffic"
    direction   = "IN"
    ip_protocol = "IPV4"
    action      = "ALLOW"
    enabled     = true
    logging     = true

    source_ids      = [vcd_nsxt_ip_set.any.id]
    destination_ids = [vcd_nsxt_ip_set.external_network_ip.id]
  }

  rule {
    name = "transit - outbound"
    direction = "OUT"
    ip_protocol = "IPV4"
    action = "ALLOW"
    enabled = true
    logging = true

    source_ids = [vcd_nsxt_ip_set.transit_net.id]
    destination_ids = [vcd_nsxt_ip_set.any.id]
  }
  
  rule {
    name = "shared - outbound"
    direction = "OUT"
    ip_protocol = "IPV4"
    action = "ALLOW"
    enabled = true
    logging = true
    source_ids = [vcd_nsxt_ip_set.shared_net.id]
    destination_ids = [vcd_nsxt_ip_set.any.id]
  }
  
  rule {
    name = "kubernetes - outbound"
    direction = "OUT"
    ip_protocol = "IPV4"
    action = "ALLOW"
    enabled = true
    logging = true
     
    source_ids = [vcd_nsxt_ip_set.kubernetes_net.id]
    destination_ids = [vcd_nsxt_ip_set.any.id]
  }

  # Rule 1: Shared to Kubernetes
  rule {
    name        = "shared to kubernetes"
    direction   = "IN_OUT"
    ip_protocol = "IPV4"
    action      = "ALLOW"
    enabled     = true
    logging     = true
    
    source_ids  = [vcd_nsxt_ip_set.shared_net.id]

    destination_ids = [vcd_nsxt_ip_set.kubernetes_net.id] 
    app_port_profile_ids = [
      data.vcd_nsxt_app_port_profile.dns.id,
      data.vcd_nsxt_app_port_profile.dhcp.id,
      data.vcd_nsxt_app_port_profile.ntp.id,
      data.vcd_nsxt_app_port_profile.http.id,
      data.vcd_nsxt_app_port_profile.http_8080.id
    ]
  }

  # Rule 3: Transit to Shared
  rule {
    name            = "transit to shared"
    direction       = "IN_OUT"
    ip_protocol     = "IPV4"
    action          = "ALLOW"
    enabled         = true
    logging         = true

    source_ids      = [vcd_nsxt_ip_set.transit_net.id]
    destination_ids = [vcd_nsxt_ip_set.shared_net.id]
    app_port_profile_ids = [
      data.vcd_nsxt_app_port_profile.dns.id,
      data.vcd_nsxt_app_port_profile.ntp.id,
      data.vcd_nsxt_app_port_profile.http.id
    ]
  }

}

# NAT Rules 
resource "vcd_nsxt_nat_rule" "snat_kubernetes" {
  org = var.vcd.org

  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id
  name            = "outbound - kubernetes"
  rule_type       = "SNAT"
  description     = "outbound - kubernetes"

  internal_address = var.networking.kubernetes.subnet
  external_address = var.vcd.external_network.ip

  firewall_match = "MATCH_INTERNAL_ADDRESS"
  enabled          = true
  logging          = true
}


resource "vcd_nsxt_nat_rule" "haproxyadmin_dnat" {
  org = var.vcd.org

  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id

  name = "haproxy admin dnat"
  rule_type = "DNAT"
  description = "HAProxy Admin DNAT"

  external_address = var.vcd.external_network.ip
  internal_address = var.services.lb.vip_ip
  app_port_profile_id = data.vcd_nsxt_app_port_profile.haproxyadmin.id
  dnat_external_port = "9000"

  firewall_match = "MATCH_EXTERNAL_ADDRESS"
  enabled = true
  logging = true
  
}


resource "vcd_nsxt_nat_rule" "ssh_dnat_jumpbox" {
  org = var.vcd.org

  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id

  name = "ssh dnat jumpbox"
  rule_type = "DNAT"
  description = "SSH DNAT Jumpbox"

  external_address = var.vcd.external_network.ip
  internal_address = var.networking.shared.jumpbox_ip
  app_port_profile_id = data.vcd_nsxt_app_port_profile.ssh.id
  dnat_external_port = "8446"

  firewall_match = "MATCH_EXTERNAL_ADDRESS"
  enabled = true
  logging = true
}

resource "vcd_nsxt_nat_rule" "http_dnat_lb" {
  org = var.vcd.org

  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id
  
  name = "http dnat load balancer"
  rule_type = "DNAT"
  description = "HTTP DNAT Load Balancer"

  external_address = var.vcd.external_network.ip
  internal_address = var.services.lb.vip_ip
  app_port_profile_id = data.vcd_nsxt_app_port_profile.http.id
  dnat_external_port = "80"

  firewall_match = "MATCH_EXTERNAL_ADDRESS"
  enabled = true
  logging = true
}

resource "vcd_nsxt_nat_rule" "https_dnat_lb" {
  org = var.vcd.org

  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id

  name = "https dnat load balancer"
  rule_type = "DNAT"
  description = "HTTPS DNAT Load Balancer"

  external_address = var.vcd.external_network.ip
  internal_address = var.services.lb.vip_ip
  app_port_profile_id = data.vcd_nsxt_app_port_profile.https.id
  dnat_external_port = "443"
  
  firewall_match = "MATCH_EXTERNAL_ADDRESS"
  enabled = true
  logging = true
}


resource "vcd_nsxt_nat_rule" "api_dnat_lb" {
  org = var.vcd.org

  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id

  name = "api dnat load balancer"
  rule_type = "DNAT"
  description = "API DNAT Load Balancer"

  external_address = var.vcd.external_network.ip
  internal_address = var.services.lb.vip_ip
  app_port_profile_id = data.vcd_nsxt_app_port_profile.api.id
  dnat_external_port = "6443"

  firewall_match = "MATCH_EXTERNAL_ADDRESS"
  enabled = true
  logging = true
}

resource "vcd_nsxt_nat_rule" "outbound_snat_kubernetes" {
  org = var.vcd.org

  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id

  name = "outbound snat kubernetes"
  rule_type = "SNAT"
  description = "Outbound SNAT Kubernetes"

  internal_address = var.networking.kubernetes.subnet
  external_address = var.vcd.external_network.ip

  firewall_match = "MATCH_INTERNAL_ADDRESS"
  enabled = true
  logging = true  
  
}

resource "vcd_nsxt_nat_rule" "outbound_snat_transit" {
  org = var.vcd.org

  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id

  name = "outbound snat transit"
  rule_type = "SNAT"
  description = "Outbound SNAT Transit"

  internal_address = var.networking.transit.subnet
  external_address = var.vcd.external_network.ip

  firewall_match = "MATCH_INTERNAL_ADDRESS"
  enabled = true
  logging = true
  
}

# NAT rule: Outbound SNAT for Shared network
resource "vcd_nsxt_nat_rule" "outbound_snat_shared" {
  org             = var.vcd.org
  edge_gateway_id = data.vcd_nsxt_edgegateway.mygw.id

  name        = "Outbound - Shared"
  rule_type   = "SNAT"
  description = "Outbound - Shared"

  internal_address = var.networking.shared.subnet
  external_address = var.vcd.external_network.ip

  firewall_match = "MATCH_INTERNAL_ADDRESS"
  enabled          = true
  logging          = true
}
