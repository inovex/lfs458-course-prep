output "ips_checksum" {
  value = "${sha1(join(" ", local_file.public_ips.*.content))}"
}

output "keys_checksum" {
  value = "${sha1(join(" ", local_file.private_key_pem.*.content))}"
}
