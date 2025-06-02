# This section pulls down the current version of the vcd provider
terraform {
  required_providers {
    vcd = {
      source  = "vmware/vcd"
      version = "~> 3.14.0"
    }
  }
  #required_version = ">= 1.3.0"
}

terraform {
  backend "s3" {
    use_path_style              = true
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
  }
}

# Configure the VMware vCloud Director Provider
provider "vcd" {
  user                 = var.vcd.user
  password             = var.vcd_pass
  org                  = var.vcd.org
  vdc                  = var.vcd.vdc
  url                  = var.vcd.url
  allow_unverified_ssl = var.vcd.allow_unverified_ssl
  logging              = false
  max_retry_timeout    = "120"
}
