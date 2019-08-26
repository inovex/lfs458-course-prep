output "ips" {
  value = "${local_file.public_ips.*.filename}"
}

output "keys" {
  value = "${local_file.private_key_pem.*.filename}"
}
