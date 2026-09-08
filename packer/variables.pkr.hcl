variable "proxmox_url" {
  type = string
  default = "https://192.168.1.1:8006/api2/json"
}

variable "proxmox_iac_username" {
  type = string
}

variable "proxmox_iac_password" {
  type      = string
  sensitive = true
}

variable "proxmox_node" {
  type    = string
  default = "ares"
}

variable "ssh_private_key_file" {
  type = string
}

variable "ssh_public_key_file" {
  type = string
}

#variable "build_ip" {
#  type    = string
#  default = "192.168.3.232/24"
#}
#
#variable "build_gateway" {
#  type    = string
#  default = "192.168.3.1"
#}

#variable "ssh_private_key_file" {
#  type    = string
#  default = "~/.ssh/packer"
#}
