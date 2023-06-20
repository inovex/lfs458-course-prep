output "ips_checksum" {
  value = sha1(local_file.public_ips.content)
}

output "keys_checksum" {
  value = sha1(local_file.private_key_pem.content)
}

output "security_group" {
  value = openstack_networking_secgroup_v2.this.name
}

output "instance_info" {
  value = {
    for name, instance in openstack_compute_instance_v2.instance :
    instance.name => (
      {
        "ip"      = instance.access_ip_v4,
        "student" = var.student_name,
        "ssh_key" = tls_private_key.ssh_key.private_key_pem
      }
    )
  }
}
