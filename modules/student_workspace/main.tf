locals {
  student_instances = toset([for i in setproduct(var.students, var.instances) : format("%s-%s", i[0], i[1])])
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
// -> student0-master, student0-node and so on.
// We use for_each here because count would destroy machines if we change the number of instances
resource "openstack_compute_instance_v2" "instance" {
  for_each        = local.student_instances
  name            = each.value
  flavor_name     = var.machine_type
  security_groups = var.sec_groups
  user_data = templatefile(
    "${path.module}/cloudinit.yaml",
    {
      DEFAULT_USER = "student"
      SSH_PUB_KEY  = trimspace(tls_private_key.ssh_key[split("-", each.value)[0]].public_key_openssh)
    }
  )

  tags = [
    split("-", each.value)[0],
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
    create_before_destroy = true
    // Ignore newer images during a training session
    ignore_changes = [
      block_device,
    ]
  }
}

resource "openstack_networking_floatingip_v2" "instance" {
  for_each    = local.student_instances
  pool        = data.openstack_networking_network_v2.public.name
  description = each.value
  tags = [
    split("-", each.value)[0],
    var.course_type,
    format("trainer-%s", var.trainer)
  ]
}

resource "openstack_compute_floatingip_associate_v2" "instance" {
  for_each    = local.student_instances
  floating_ip = openstack_networking_floatingip_v2.instance[each.value].address
  instance_id = openstack_compute_instance_v2.instance[each.value].id
}

resource "local_file" "public_ips" {
  for_each = toset(var.students)
  // The format is required to end the file with a \n
  // otherwise we have a non POSIX compliant file
  content  = format("%s\n", join("\n", [for i in values(openstack_networking_floatingip_v2.instance).* : format("%s: %s", i.description, i.address) if contains(i.tags, each.value)]))
  filename = "${path.cwd}/ips/${each.value}.txt"
}
