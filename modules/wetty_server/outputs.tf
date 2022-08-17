output "wetty_server_address" {
  value = "https://${trimsuffix(openstack_dns_recordset_v2.wetty.name, ".")}"
}

output "student_passwords_hash" {
  value = [for entry in random_password.student_password : sha256(entry.result)]
}