variable "proxmox_endpoint" {
  type        = string
  default     = "https://192.168.1.1:8006"
  description = "API Endpoint for PVE"
}

variable "proxmox_iac_username" { 
  type        = string 
  description = "IAC Username for PVE"
  sensitive   = true
}

variable "proxmox_iac_password" { 
  type        = string 
  description = "IAC Password for PVE"
  sensitive   = true
}

variable "proxmox_node" {
  type        = string
  default     = "ares"
}

variable "vm_k3s_node_definitions" {
  type = map(object({
    vm_name        = string
    vm_description = string
    vm_id          = number
    net_ip_cidr    = string
  })) 
  default = {
    "k3s-node-01" = {
      vm_name        = "k3s-node-01",
      vm_description = "K3S Combined Node 01",
      vm_id          = 901,
      net_ip_cidr    = "192.168.30.51/24"
    },
    "k3s-node-02" = {
      vm_name        = "k3s-node-02",
      vm_description = "K3S Combined Node 02",
      vm_id          = 902,
      net_ip_cidr    = "192.168.30.52/24"
    },
    "k3s-node-03" = {
      vm_name        = "k3s-node-03",
      vm_description = "K3S Combined Node 03",
      vm_id          = 903,
      net_ip_cidr    = "192.168.30.53/24"
    }
  }
}

variable "vm_tags" {
  type = list(string)
  default = [
    "terraform",
    "ubuntu-26.04.01",
    "k3s",
  ]
}

variable "vm_agent_enabled" {
  type    = bool
  default = true
}

variable "vm_cpu_cores" {
  type    = number
  default = 4
}

variable "vm_memory_size" {
  type    = number
  default = 8192
}

variable "vm_disk_size" {
  type    = number
  default = 50
}

variable "net_dns_servers" {
  type    = list(string)
  default = ["192.168.30.1"]
}

variable "net_gateway" {
  type    = string
  default = "192.168.30.1"
}

variable "net_bridge" {
  type    = string
  default = "vmbr3"
}

variable "net_mtu" {
  type    = number
  default = 1400
}

variable "net_vlan_id" {
  type    = number
  default = 30
}

variable "os_username" {
  type = string
  default = "ubuntu"
}

variable "ssh_key_path" {
  type   = string
  default = "~/ares-infra/packer/.secrets/resolute-ed25519"

}
