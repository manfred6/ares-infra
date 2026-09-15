resource "random_password" "ubuntu_vm_password" {
  length           = 64
  override_special = "_%@"
  special          = true
}

resource "tls_private_key" "k3s" {
  algorithm = "ED25519"
}

resource "local_sensitive_file" "k3s_private_key" {
  filename = "${path.module}/.secrets/k3s_ed25519"
  content  = tls_private_key.k3s.private_key_openssh

  file_permission = "0600"
}

resource "local_file" "k3s_public_key" {
  filename = "${path.module}/.secrets/k3s_ed25519.pub"
  content  = tls_private_key.k3s.public_key_openssh

  file_permission = "0644"
}
