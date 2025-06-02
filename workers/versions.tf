terraform {
  required_providers {
    vsphere = {
      source = "hashicorp/vsphere"
    }
    ignition = {
      source = "community-terraform-providers/ignition"
    }
     vcd = {
      source  = "vmware/vcd"
      version = "~> 3.14.0"
    }
  }
  required_version = ">= 0.13"
}
