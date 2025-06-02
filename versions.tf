terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
    }
    tls = {
      source = "hashicorp/tls"
    }
    vsphere = {
      source = "hashicorp/vsphere"
    }
    vcd = {
      source  = "vmware/vcd"
      version = "3.14.0"
    }
  }
  required_version = ">= 1.3.0"
}
