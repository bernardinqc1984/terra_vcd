variable "temp_pass" {}
variable "vapp_name" {}
variable "name" {}
variable "catalog_name" {
  type    = string
  default = "Projet Cirrus - Rocky Linux 9.5 - EN - Template"
}
variable "template_name" {
  type    = string
  default = "Rocky Linux 9.5 - EN - Template 2025"
}
variable "network_name" {}
variable "os_type" {
  type    = string
  default = "centos9_64Guest"
}
variable "memory" {
  type    = number
  default = 1 * 1024
}
variable "cpus" {
  type    = number
  default = 1
}
variable "power_on" {
  type    = bool
  default = false
}
variable "ip" {
  type    = list(any)
  default = []
}
variable "initscript" {}

variable "vm_count" {
  type    = number
  default = 1
}