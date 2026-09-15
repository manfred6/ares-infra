terraform {
  required_version = ">= 1.6"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.111"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.9.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.4.0"
    }
    local = {
      source = "hashicorp/local"
    }
  }
}

provider "random" {}
provider "tls" {}
#provier  "local" {}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = var.proxmox_iac_username
  password = var.proxmox_iac_password
  insecure = true
}
