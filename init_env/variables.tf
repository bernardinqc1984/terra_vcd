//////
// vSphere variables
//////


variable "vcd_vdc" {
  type        = string
  description = "This is the vcd vdc for the environment."
  default     = ""
}
variable "vcd_user" {
  type        = string
  description = "This is the vcd user."
  default = ""
}
variable "vcd_password" {
  type        = string
  description = "This is the vcd password for the environment."
  sensitive   = true
  default     = ""
}

variable "vcd_org" {
  type        = string
  description = "This is the vcd org string from the console for the environment."
  default     = "openshift_dev"
}
variable "vcd_url" {
  type        = string
  description = "This is the vcd url for the environment."
  default     = ""
}

variable "edge_gateway_name" {
  description = "The name of the NSX-T Edge Gateway"
  type        = string
  default     = ""
}