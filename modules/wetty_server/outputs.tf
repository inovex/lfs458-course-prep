output "wetty_server_address" {
  value = "https://${trimsuffix(openstack_dns_recordset_v2.wetty.name, ".")}"
}
