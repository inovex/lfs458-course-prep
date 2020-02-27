output "ips_checksum" {
  value = "${sha1(join(" ", values(local_file.public_ips).*.content))}"
}

output "keys_checksum" {
  value = "${sha1(join(" ", values(local_file.private_key_pem).*.content))}"
}
