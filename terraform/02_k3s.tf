resource "proxmox_virtual_environment_vm" "ubuntu_vm" {
  for_each    = var.vm_k3s_node_definitions
  name        = each.value.vm_name
  description = each.value.vm_description 
  tags        = var.vm_tags 
  node_name   = var.proxmox_node
  vm_id       = each.value.vm_id

  agent {
    enabled = var.vm_agent_enabled
  }

  stop_on_destroy = true

  cpu {
    cores        = var.vm_cpu_cores
    //type         = "x86-64-v2-AES" not compatible with fleet server 9.x due to glibc version cpu flag reqs
    type         = "host"
  }

  memory {
    dedicated = var.vm_memory_size
    floating  = var.vm_memory_size
  }

  clone {
    datastore_id = "local"
    vm_id        = 109 # id of packer-ubuntu-resolute-base template
    full         = true
  }

  disk {
    datastore_id = "local"
    interface    = "scsi0"
    size         = var.vm_disk_size
  }

  initialization {
    datastore_id = "local"
    dns {
      servers = var.net_dns_servers
    }
    ip_config {
      ipv4 {
        address = each.value.net_ip_cidr 
        gateway = var.net_gateway 
      }
    }

    user_account {
      password = random_password.ubuntu_vm_password.result
      username = var.os_username
      keys = [
        trimspace(tls_private_key.k3s.public_key_openssh)
      ]
    }
  }

  network_device {
    bridge  = var.net_bridge 
    mtu     = var.net_mtu 
    vlan_id = var.net_vlan_id 
  }

  operating_system {
    type = "l26"
  }

  tpm_state {
    version      = "v2.0"
    datastore_id = "local"
  }

  serial_device {}

  startup {
    order = -1 # no specific order
  }
}

