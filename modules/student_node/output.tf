# TODO how to know which student has which ips?
output "public_ip" {
  value = "${azurerm_public_ip.pub_ip.*.ip_address}"
}
