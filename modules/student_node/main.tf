data "azurerm_resource_group" "resource_group" {
  name = "${var.azurerm_resource_group}"
}

data "azurerm_subnet" "subnet" {
  name                 = "${var.azurerm_subnet}"
  virtual_network_name = "${var.virtual_network_name}"
  resource_group_name  = "${data.azurerm_resource_group.resource_group.name}"
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.student}_${var.name}_nic"
  location            = "${data.azurerm_resource_group.resource_group.location}"
  resource_group_name = "${data.azurerm_resource_group.resource_group.name}"

  ip_configuration {
    name                          = "${var.student}_${var.name}_nic_config"
    subnet_id                     = "${data.azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.pub_ip.id}"
  }

  tags {
    environment = "LFS458"
    student     = "${var.student}"
  }
}

resource "azurerm_public_ip" "pub_ip" {
  name                         = "${var.student}_${var.name}_pub_ip"
  location                     = "${data.azurerm_resource_group.resource_group.location}"
  resource_group_name          = "${data.azurerm_resource_group.resource_group.name}"
  public_ip_address_allocation = "static"

  tags {
    environment = "LFS458"
    student     = "${var.student}"
  }
}

resource "azurerm_virtual_machine" "node" {
  name                             = "${var.student}-${var.name}"
  location                         = "${data.azurerm_resource_group.resource_group.location}"
  resource_group_name              = "${data.azurerm_resource_group.resource_group.name}"
  network_interface_ids            = ["${azurerm_network_interface.nic.id}"]
  vm_size                          = "Standard_D2_v3"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  #Standard_B2ms
  storage_os_disk {
    name              = "${var.student}${var.name}osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.student}-${var.name}"
    admin_username = "ubuntu"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/ubuntu/.ssh/authorized_keys"
      key_data = "${var.public_ssh_key}"
    }
  }

  tags {
    environment = "LFS458"
    student     = "${var.student}"
  }
}
