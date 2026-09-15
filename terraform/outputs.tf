resource "local_sensitive_file" "ed25519_private_key" {
  content         = tls_private_key.k3s.private_key_openssh
  filename        = "${path.module}/.secrets/id_ed25519"
  file_permission = "0600"
}

resource "local_file" "ed25519_public_key" {
  content  = tls_private_key.k3s.public_key_openssh
  filename = "${path.module}/.sectets/id_ed25519.pub"
}

output "ubuntu_vm_password" {
  value     = random_password.ubuntu_vm_password.result
  sensitive = true
}

output "vm_ipv4_addresses" {
  value = {
    for name, srv in proxmox_virtual_environment_vm.ubuntu_vm:
      name => srv.ipv4_addresses
  }
}

# Ansible inventory (INI format)
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory/hosts.ini"

  content = <<-EOT
[k3s_servers]
%{ for name, srv in var.vm_k3s_node_definitions ~}
${name} ansible_host=${proxmox_virtual_environment_vm.ubuntu_vm[name].ipv4_addresses[1][0]} ansible_user=${var.os_username}
%{ endfor ~}
EOT

  file_permission = "0644"
}

resource "local_file" "ansible_config" {
  filename = "${path.module}/../ansible/ansible.cfg"

  content = <<-EOT
[defaults]
inventory = ${abspath("${path.module}/../ansible/inventory/hosts.ini")}
roles_path = ${abspath("${path.module}/../ansible/roles")}
private_key_file = ${abspath(local_sensitive_file.k3s_private_key.filename)}
host_key_checking = False
interpreter_python = auto_silent
retry_files_enabled = False

[ssh_connection]
pipelining = True
EOT

  file_permission = "0644"
}
