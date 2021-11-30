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

data "cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "cloudinit.yaml"
    content_type = "text/cloud-config"
    content = templatefile(
      "${path.module}/cloudinit.yaml",
      {
        DEFAULT_USER = "student"
        SSH_PUB_KEY  = trimspace(tls_private_key.ssh_key.public_key_openssh)
        INSTANCES    = var.instances
      }
    )
  }
}

resource "openstack_compute_instance_v2" "wetty_server" {
  name            = "wetty-server-${var.course_type}-${var.trainer}"
  flavor_name     = var.machine_type
  security_groups = var.sec_groups
  user_data       = data.cloudinit_config.config.rendered

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

# resource "local_file" "public_ips" {
#   // The format is required to end the file with a \n
#   // otherwise we have a non POSIX compliant file
#   content  = format("%s\n", openstack_networking_floatingip_v2.wetty_server.address)
#   filename = "${path.cwd}/ips/wetty_server.txt"
# }

resource "null_resource" "setup_keys_dir" {
  triggers = {
    instance = openstack_compute_instance_v2.wetty_server.id
  }

  depends_on = [
    openstack_compute_floatingip_associate_v2.wetty_server
  ]

  provisioner "remote-exec" {

    inline = [
      "mkdir -p /home/student/keys/"
    ]

    connection {
      type        = "ssh"
      user        = "student"
      host        = openstack_networking_floatingip_v2.wetty_server.address
      private_key = tls_private_key.ssh_key.private_key_pem
    }
  }
}

resource "null_resource" "student_ssh_keys" {

  for_each = local.student_ssh_keys

  triggers = {
    instance = openstack_compute_instance_v2.wetty_server.id
  }

  depends_on = [
    openstack_compute_floatingip_associate_v2.wetty_server,
    null_resource.setup_keys_dir
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
