provider "tls" {
  version = "~> 1.1.0"
}

provider "local" {
  version = "~> 1.1.0"
}

resource "tls_private_key" "ssh_key" {
  count     = "${length(var.students)}"
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "local_file" "private_key_pem" {
  count    = "${length(var.students)}"
  content  = "${tls_private_key.ssh_key.*.private_key_pem[count.index]}"
  filename = "${path.cwd}/keys/${var.students[count.index]}"

  provisioner "local-exec" {
    command = "chmod 600 ${path.cwd}/keys/${var.students[count.index]}"
  }
}

module "master" {
  source                 = "../student_node"
  students               = "${var.students}"
  name                   = "master"
  public_ssh_keys        = "${tls_private_key.ssh_key.*.public_key_openssh}"
  azurerm_resource_group = "${var.azurerm_resource_group}"
  azurerm_subnet         = "${var.azurerm_subnet}"
  virtual_network_name   = "${var.virtual_network_name}"
  instance_type          = "${var.instance_type}"
}

module "node0" {
  source                 = "../student_node"
  students               = "${var.students}"
  name                   = "node0"
  public_ssh_keys        = "${tls_private_key.ssh_key.*.public_key_openssh}"
  azurerm_resource_group = "${var.azurerm_resource_group}"
  azurerm_subnet         = "${var.azurerm_subnet}"
  virtual_network_name   = "${var.virtual_network_name}"
  instance_type          = "${var.instance_type}"
}

resource "local_file" "public_ips" {
  count    = "${length(var.students)}"
  content  = "master: ${module.master.public_ip[count.index]}\nnode: ${module.node0.public_ip[count.index]}\n"
  filename = "${path.cwd}/ips/${var.students[count.index]}"
}
