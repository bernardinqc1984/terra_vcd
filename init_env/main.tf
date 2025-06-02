provider "vcd" {
  user                 = var.vcd_user
  password             = var.vcd_password
  org                  = var.vcd_org
  url                  = var.vcd_url
  max_retry_timeout    = 30
  allow_unverified_ssl = true
  logging              = true
}


data "vcd_org_vdc" "vdc" {
  org = var.vcd_org
  name = var.vcd_vdc
}

data "vcd_nsxt_edgegateway" "mygateway" {
  org      = var.vcd_org
  owner_id = data.vcd_org_vdc.vdc.id
  name     = var.edge_gateway_name
}

# Profils de ports natifs
data "vcd_nsxt_app_port_profile" "http" {
  context_id = data.vcd_org_vdc.vdc.id
  scope = "SYSTEM"
  name  = "HTTP"
}

data "vcd_nsxt_app_port_profile" "https" {
  context_id = data.vcd_org_vdc.vdc.id
  scope = "SYSTEM"
  name  = "HTTPS"
}

data "vcd_nsxt_app_port_profile" "ssh" {
  context_id = data.vcd_org_vdc.vdc.id
  scope = "SYSTEM"
  name  = "SSH"
}



resource "vcd_nsxt_app_port_profile" "dhcp" {

  org = var.vcd_org
  

  context_id = data.vcd_org_vdc.vdc.id
  scope = "TENANT"
  name  = "DHCP"

  app_port {
    protocol = "UDP"
    port     = ["67", "68"]
  }

  description = "DHCP Application Port Profile"
}

resource "vcd_nsxt_app_port_profile" "dns" {

  org = var.vcd_org

  context_id = data.vcd_org_vdc.vdc.id
  scope = "TENANT"
  name  = "DNS"

  app_port {
    protocol = "UDP"
    port     = ["53"]
  }

  description = "DNS Application Port Profile"
}


resource "vcd_nsxt_app_port_profile" "ntp" {

  org = var.vcd_org

  context_id = data.vcd_org_vdc.vdc.id
  scope = "TENANT"
  name  = "NTP"

  app_port {
    protocol = "UDP"
    port     = ["123"]
  }

  description = "NTP Application Port Profile"
}


# Custom app port profile for non-standard services (e.g., HTTP on port 8080)
resource "vcd_nsxt_app_port_profile" "http_8080" {

  org = var.vcd_org
  
  scope = "TENANT"
  name  = "HTTP-8080-Custom"

  context_id = data.vcd_org_vdc.vdc.id
  #context_id = data.vcd_nsxt_edgegateway.mygw.id

  app_port {
    protocol = "TCP"
    port     = ["8080"]
  }

  description = "Custom HTTP service on port 8080"
}

# Profils personnalisés
resource "vcd_nsxt_app_port_profile" "haproxyadmin" {
  org = var.vcd_org
  
  name  = "HAProxy admin Port"
  
  context_id = data.vcd_org_vdc.vdc.id
  #context_id = data.vcd_nsxt_edgegateway.mygw.id
  description = "Port for HAProxy admin access"

  scope = "TENANT"

  app_port {
    protocol = "TCP"
    port     = ["9000"]
  }
}

resource "vcd_nsxt_app_port_profile" "api" {
  org = var.vcd_org

  name  = "Custom_api_6443"

  context_id = data.vcd_org_vdc.vdc.id
  #context_id = data.vcd_nsxt_edgegateway.mygw.id
  description = "Port for API access"

  scope = "TENANT"

  app_port {
    protocol = "TCP"
    port     = ["6443"]
  }
}

resource "vcd_nsxt_app_port_profile" "custom_ssh_8446" {
  org = var.vcd_org
  
  name  = "Custom_ssh_8446"

  context_id = data.vcd_org_vdc.vdc.id
  #context_id = data.vcd_nsxt_edgegateway.mygw.id
  description = "Custom SSH Port"

  scope = "TENANT"
  
  app_port {
    protocol = "TCP"
    port     = ["8446"]
  }
  
}