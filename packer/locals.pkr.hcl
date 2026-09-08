locals {
  ssh_public_key = trimspace(file(var.ssh_public_key_file))
}
