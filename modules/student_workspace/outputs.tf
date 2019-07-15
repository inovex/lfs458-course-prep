output "keys" {
  value = "${local_file.public_ips.*.filename}"
}
