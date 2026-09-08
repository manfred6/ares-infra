packer {
  required_plugins {
    proxmox = {
      version = "~> 1.2"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "ubuntu-resolute" {
  proxmox_url = var.proxmox_url
  username    = var.proxmox_iac_username
  password    = var.proxmox_iac_password

  node = var.proxmox_node

  vm_name       = "packer-build-ubuntu-resolute"
  template_name = "ubuntu-resolute-base" # wtf is this even for?

  cores  = 2
  memory = 2048

  disks {
    type         = "scsi"
    disk_size    = "20G"
    storage_pool = "local-lvm"
  }

  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }
  
  boot_iso {
    type     = "scsi"
    iso_file = "local:iso/ubuntu-26.04.1-live-server-amd64.iso"
    unmount  = true
  }

  http_directory = "http"
  boot_wait = "5s"
  boot_command = [
    "e<wait>",
    "<down><down><down><end>",
    " autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
    "<f10>"
  ]

  http_content = {
    "/user-data" = templatefile(
      "${path.root}/http/user-data.yaml",
      {
        ssh_public_key = local.ssh_public_key
      }
    )

    "/meta-data" = file("${path.root}/http/meta-data.yaml")
  }

  ssh_username = "packer"
  ssh_private_key_file = var.ssh_private_key_file
  ssh_timeout  = "10m"

  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"
}

build {
  sources = [
    "source.proxmox-iso.ubuntu"
  ]
}
