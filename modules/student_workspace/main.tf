provider "tls" {
  version = "~> 1.1.0"
}

provider "local" {
  version = "~> 1.1.0"
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "local_file" "private_key_pem" {
  content  = "${tls_private_key.ssh_key.private_key_pem}"
  filename = "${path.cwd}/keys/${var.student}"

  provisioner "local-exec" {
    command = "chmod 600 ${path.cwd}/keys/${var.student}"
  }
}

module "master" {
  source                 = "../student_node"
  student                = "${var.student}"
  name                   = "master"
  public_ssh_key         = "${tls_private_key.ssh_key.public_key_openssh}"
  azurerm_resource_group = "${var.azurerm_resource_group}"
  azurerm_subnet         = "${var.azurerm_subnet}"
  virtual_network_name   = "${var.virtual_network_name}"
}

module "node0" {
  source                 = "../student_node"
  student                = "${var.student}"
  name                   = "node0"
  public_ssh_key         = "${tls_private_key.ssh_key.public_key_openssh}"
  azurerm_resource_group = "${var.azurerm_resource_group}"
  azurerm_subnet         = "${var.azurerm_subnet}"
  virtual_network_name   = "${var.virtual_network_name}"
}

# TODO write public ips in extra file
