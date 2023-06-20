resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "local_file" "private_key_pem" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "${path.cwd}/keys/${var.student_name}"

  provisioner "local-exec" {
    command = "chmod 600 ${path.cwd}/keys/${var.student_name}"
  }
}

resource "openstack_compute_instance_v2" "instance" {
  for_each    = toset(var.instances)
  name        = "${var.student_name}-${each.value}"
  flavor_name = var.machine_type
  user_data = templatefile(
    "${path.module}/cloudinit.yaml",
    {
      DEFAULT_USER    = "student"
      SSH_PUB_KEY     = trimspace(tls_private_key.ssh_key.public_key_openssh)
      SOLUTIONS_URL   = var.solutions_url
      SOLUTIONS_PATCH = var.solutions_patch
    }
  )

  tags = [
    var.student_name,
    var.course_type,
    format("trainer-%s", var.trainer)
  ]

  block_device {
    uuid                  = data.openstack_images_image_v2.ubuntu.id
    source_type           = "image"
    volume_size           = 10
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }

  network {
    port = openstack_networking_port_v2.instance[each.value].id
  }

  lifecycle {
    create_before_destroy = true
    // Ignore newer images during a training session
    ignore_changes = [
      block_device,
    ]
  }

  depends_on = [
    openstack_networking_subnet_v2.subnet, openstack_networking_secgroup_v2.this
  ]
}

resource "openstack_networking_port_v2" "instance" {
  for_each           = toset(var.instances)
  name               = "${each.value}_port"
  network_id         = openstack_networking_network_v2.network.id
  admin_state_up     = "true"
  security_group_ids = [openstack_networking_secgroup_v2.this.id]
  fixed_ip {
    subnet_id  = openstack_networking_subnet_v2.subnet.id
    ip_address = cidrhost(var.network, index(var.instances, each.value) + 100)
  }
}

resource "openstack_networking_floatingip_v2" "instance" {
  for_each    = openstack_compute_instance_v2.instance
  pool        = data.openstack_networking_network_v2.public.name
  description = each.value.name
  tags = [
    var.student_name,
    each.value.name,
    var.course_type,
    format("trainer-%s", var.trainer)
  ]
}

resource "openstack_compute_floatingip_associate_v2" "instance" {
  for_each    = openstack_networking_floatingip_v2.instance
  floating_ip = each.value.address
  instance_id = openstack_compute_instance_v2.instance[each.key].id
}

resource "local_file" "public_ips" {
  content  = format("%s\n", join("\n", [for i in values(openstack_networking_floatingip_v2.instance).* : format("%s: %s", i.description, i.address)]))
  filename = "${path.cwd}/ips/${var.student_name}.txt"
}

resource "openstack_dns_recordset_v2" "instance" {
  for_each = openstack_compute_instance_v2.instance
  zone_id  = data.openstack_dns_zone_v2.dns_domain.id
  # name must be <= 64 chars, otherwise certbot will fail
  name        = "${each.value.name}.${data.openstack_dns_zone_v2.dns_domain.name}"
  ttl         = 60
  type        = "A"
  records     = [openstack_networking_floatingip_v2.instance[each.key].address]
  description = "DNS entry for ${var.course_type} by ${var.trainer}"
}