output "ips_checksum" {
  value = sha1(join(" ", values(local_file.public_ips).*.content))
}

output "keys_checksum" {
  value = sha1(join(" ", values(local_file.private_key_pem).*.content))
}

output "instance_info" {
  value = {
    for name, instance in openstack_compute_instance_v2.instance:
    name => ({
      "ip" = instance.access_ip_v4,
      "student" = split("-", name)[0],
      "ssh_key" = tls_private_key.ssh_key[split("-", name)[0]].private_key_pem
    })
  }
}
