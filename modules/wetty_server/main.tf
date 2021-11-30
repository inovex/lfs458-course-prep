resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "local_file" "private_key_pem" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "${path.cwd}/keys/wetty-server"

  provisioner "local-exec" {
    command = "chmod 600 ${path.cwd}/keys/wetty-server"
  }
}

locals {
  # the ellipsis (...) allows us to have values merged by resulting key,
  # meaning we have a list of SSH Keys (currently always the same) per student
  student_ssh_keys = {
    for instance, info in var.instances :
    info["student"] => trimspace(info["ssh_key"])...
  }
}

resource "openstack_compute_instance_v2" "wetty_server" {
  name            = "wetty-server-${var.course_type}-${var.trainer}"
  flavor_name     = var.machine_type
  security_groups = var.sec_groups
  user_data       = templatefile(
      "${path.module}/cloudinit.yaml",
      {
        DEFAULT_USER = "student"
        SSH_PUB_KEY  = trimspace(tls_private_key.ssh_key.public_key_openssh)
        INSTANCES    = var.instances
      }
  )

  tags = [
    "wetty-server",
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

resource "openstack_networking_floatingip_v2" "wetty_server" {
  pool        = data.openstack_networking_network_v2.public.name
  description = "wetty-server"
  tags = [
    "wetty-server",
    var.course_type,
    format("trainer-%s", var.trainer)
  ]
}

resource "openstack_compute_floatingip_associate_v2" "wetty_server" {
  floating_ip = openstack_networking_floatingip_v2.wetty_server.address
  instance_id = openstack_compute_instance_v2.wetty_server.id
}

resource "random_password" "student_password" {
  for_each = local.student_ssh_keys

  length = 55
  special = true
  override_special = "_%@"
}

resource "local_file" "student_password" {
  for_each = random_password.student_password
  content  = each.value.result
  filename = "${path.cwd}/passwords/${each.key}"
}

resource "null_resource" "setup_dirs" {
  triggers = {
    instance = openstack_compute_instance_v2.wetty_server.id
  }

  depends_on = [
    openstack_compute_floatingip_associate_v2.wetty_server
  ]

  provisioner "remote-exec" {

    inline = [
      "mkdir -p /home/student/keys/ /home/student/htpasswd/"
    ]

    connection {
      type        = "ssh"
      user        = "student"
      host        = openstack_networking_floatingip_v2.wetty_server.address
      private_key = tls_private_key.ssh_key.private_key_pem
    }
  }
}

resource "null_resource" "student_credentials" {

  for_each = local.student_ssh_keys

  triggers = {
    instance = openstack_compute_instance_v2.wetty_server.id
  }

  depends_on = [
    openstack_compute_floatingip_associate_v2.wetty_server,
    null_resource.setup_dirs
  ]

  provisioner "file" {
    content     = each.value[0]
    destination = "/home/student/keys/${each.key}"

    connection {
      type        = "ssh"
      user        = "student"
      host        = openstack_networking_floatingip_v2.wetty_server.address
      private_key = tls_private_key.ssh_key.private_key_pem
    }
  }

  provisioner "file" {
    content     = "${each.key}:${bcrypt(random_password.student_password[each.key].result)}"
    destination = "/home/student/htpasswd/${each.key}"

    connection {
      type        = "ssh"
      user        = "student"
      host        = openstack_networking_floatingip_v2.wetty_server.address
      private_key = tls_private_key.ssh_key.private_key_pem
    }
  }
}

resource "null_resource" "configs" {
  triggers = {
    instance = openstack_compute_instance_v2.wetty_server.id
  }

  depends_on = [
    openstack_compute_floatingip_associate_v2.wetty_server
  ]

  provisioner "file" {
    content = templatefile(
      "${path.module}/nginx.conf",
      {
        INSTANCES = var.instances
      }
    )
    destination = "/home/student/nginx.conf"

    connection {
      type        = "ssh"
      user        = "student"
      host        = openstack_networking_floatingip_v2.wetty_server.address
      private_key = tls_private_key.ssh_key.private_key_pem
    }
  }

  provisioner "file" {
    content = templatefile(
      "${path.module}/docker-compose.yaml",
      {
        INSTANCES = var.instances
      }
    )
    destination = "/home/student/docker-compose.yaml"

    connection {
      type        = "ssh"
      user        = "student"
      host        = openstack_networking_floatingip_v2.wetty_server.address
      private_key = tls_private_key.ssh_key.private_key_pem
    }
  }
}
