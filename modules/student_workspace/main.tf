locals {
  student_instances = {for pair in setproduct(var.students, var.instances):format("%s-%s", pair[0], pair[1]) => pair}
  join_token = "${random_password.join_token_1.result}.${random_password.join_token_2.result}"
}

resource "random_password" "join_token_1" {
  length           = 6
  special          = false
  upper            = false
}

resource "random_password" "join_token_2" {
  length           = 16
  special          = false
  upper            = false
}

resource "tls_private_key" "ssh_key" {
  for_each  = toset(var.students)
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "local_file" "private_key_pem" {
  for_each = toset(var.students)
  content  = tls_private_key.ssh_key[each.value].private_key_pem
  filename = "${path.cwd}/keys/${each.value}"

  provisioner "local-exec" {
    command = "chmod 600 ${path.cwd}/keys/${each.value}"
  }
}

// We iterate over the product of students * instances e.g.
// -> student0-cp, student0-worker and so on.
resource "openstack_compute_instance_v2" "instance" {
  for_each        = local.student_instances
  name            = each.key
  flavor_name     = var.machine_type
  security_groups = var.sec_groups
  user_data = templatefile(
    "${path.module}/cloudinit.yaml",
    {
      DEFAULT_USER    = "student"
      SSH_PUB_KEY     = trimspace(tls_private_key.ssh_key[each.value[0]].public_key_openssh)
      SOLUTIONS_URL   = var.solutions_url
      SOLUTIONS_PATCH = var.solutions_patch
      K8S_VERSION     = "1.26.1"
      CALICO_VERSION  = "v3.25.0"
      HELM_VERSION    = "v3.12.0"
      CRI_VERSION     = "v1.26.0"
      PODMAN_VERSION  = "v4.6.1"
      CP_NODE         = "${each.value[0]}-cp"
      REGISTRY_HOST   = "registry-${var.course_type}-${var.trainer}"
      IS_CP           = each.value[1] == "cp"
      JOIN_TOKEN      = local.join_token
    }
  )

  tags = [
    each.value[0],
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
    uuid = var.network
  }

  lifecycle {
    // Ignore newer images during a training session
    ignore_changes = [
      block_device,
    ]
  }
}

resource "openstack_networking_floatingip_v2" "instance" {
  for_each    = local.student_instances
  pool        = data.openstack_networking_network_v2.public.name
  description = each.key
  tags = [
    each.value[0],
    var.course_type,
    format("trainer-%s", var.trainer)
  ]
}

resource "openstack_compute_floatingip_associate_v2" "instance" {
  for_each    = local.student_instances
  floating_ip = openstack_networking_floatingip_v2.instance[each.key].address
  instance_id = openstack_compute_instance_v2.instance[each.key].id
}

resource "local_file" "public_ips" {
  for_each = toset(var.students)
  // The format is required to end the file with a \n
  // otherwise we have a non POSIX compliant file
  content  = format("%s\n", join("\n", [for i in values(openstack_networking_floatingip_v2.instance).* : format("%s: %s", i.description, i.address) if contains(i.tags, each.value)]))
  filename = "${path.cwd}/ips/${each.value}.txt"
}

resource "openstack_dns_recordset_v2" "instance" {
  for_each = openstack_compute_instance_v2.instance
  zone_id  = data.openstack_dns_zone_v2.dns_domain.id
  # name must be <= 64 chars, otherwise certbot will fail
  name        = "${each.value.name}.${data.openstack_dns_zone_v2.dns_domain.name}"
  ttl         = 60
  type        = "A"
  records     = [openstack_networking_floatingip_v2.instance[each.value.name].address]
  description = "DNS entry for ${var.course_type} by ${var.trainer}"
}