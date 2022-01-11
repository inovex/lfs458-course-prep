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
  user_data = templatefile(
    "${path.module}/cloudinit.yaml",
    {
      USER        = var.user
      SSH_PUB_KEY = trimspace(tls_private_key.ssh_key.public_key_openssh)
      INSTANCES   = var.instances
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

data "openstack_dns_zone_v2" "terraform" {
  name = var.dns_domain
}

resource "openstack_dns_recordset_v2" "wetty" {
  zone_id = data.openstack_dns_zone_v2.terraform.id
  # name must be <= 64 chars, otherwise certbot will fail
  name    = "wetty-${var.trainer}.${data.openstack_dns_zone_v2.terraform.name}"
  ttl     = 300
  type    = "A"
  records = [openstack_networking_floatingip_v2.wetty_server.address]
}

resource "random_password" "student_password" {
  for_each = local.student_ssh_keys

  length           = 55
  special          = true
  override_special = "_-"
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
      "mkdir -p /home/${var.user}/keys/",
      "mkdir -p /home/${var.user}/htpasswd/",
      "mkdir -p /home/${var.user}/html/",
      "mkdir -p /home/${var.user}/data/certbot/conf",
      "mkdir -p /home/${var.user}/data/certbot/www"
    ]

    connection {
      type        = "ssh"
      user        = var.user
      host        = openstack_networking_floatingip_v2.wetty_server.address
      private_key = tls_private_key.ssh_key.private_key_pem
    }
  }
}

resource "null_resource" "student_credentials" {

  for_each = local.student_ssh_keys

  triggers = {
    instance = openstack_compute_instance_v2.wetty_server.id
    password = each.value[0]
  }

  depends_on = [
    openstack_compute_floatingip_associate_v2.wetty_server,
    null_resource.setup_dirs
  ]

  provisioner "file" {
    content     = each.value[0]
    destination = "/home/${var.user}/keys/${each.key}"

    connection {
      type        = "ssh"
      user        = var.user
      host        = openstack_networking_floatingip_v2.wetty_server.address
      private_key = tls_private_key.ssh_key.private_key_pem
    }
  }

  provisioner "file" {
    content     = "${each.key}:${bcrypt(random_password.student_password[each.key].result)}"
    destination = "/home/${var.user}/htpasswd/${each.key}"

    connection {
      type        = "ssh"
      user        = var.user
      host        = openstack_networking_floatingip_v2.wetty_server.address
      private_key = tls_private_key.ssh_key.private_key_pem
    }
  }
}

resource "null_resource" "configs" {
  triggers = {
    instance            = openstack_compute_instance_v2.wetty_server.id
    nginx_conf          = sha1(file("${path.module}/nginx.conf"))
    index_html          = sha1(file("${path.module}/index.html"))
    docker_compose_yaml = sha1(file("${path.module}/docker-compose.yaml"))
    init_letsencrypt_sh = sha1(file("${path.module}/init-letsencrypt.sh"))
    htpasswd            = sha1(file("${path.module}/.htpasswd"))
    student_instances   = join(" ", keys(var.instances))
    hostname            = openstack_dns_recordset_v2.wetty.name
    nginx_image         = var.nginx_image
    certbot_image       = var.certbot_image
    wetty_image         = var.wetty_image
    trainer_email       = var.trainer_email
  }

  depends_on = [
    openstack_compute_floatingip_associate_v2.wetty_server,
    null_resource.setup_dirs
  ]

  provisioner "file" {
    content = templatefile(
      "${path.module}/nginx.conf",
      {
        INSTANCES = var.instances
        HOST_NAME = trimsuffix(openstack_dns_recordset_v2.wetty.name, ".")
      }
    )
    destination = "/home/${var.user}/nginx.conf"

    connection {
      type        = "ssh"
      user        = var.user
      host        = openstack_networking_floatingip_v2.wetty_server.address
      private_key = tls_private_key.ssh_key.private_key_pem
    }
  }

  provisioner "file" {
    content = templatefile(
      "${path.module}/index.html",
      {
        INSTANCES = var.instances
      }
    )
    destination = "/home/${var.user}/html/index.html"

    connection {
      type        = "ssh"
      user        = var.user
      host        = openstack_networking_floatingip_v2.wetty_server.address
      private_key = tls_private_key.ssh_key.private_key_pem
    }
  }

  provisioner "file" {
    content = templatefile(
      "${path.module}/docker-compose.yaml",
      {
        INSTANCES     = var.instances
        NGINX_IMAGE   = var.nginx_image
        CERTBOT_IMAGE = var.certbot_image
        WETTY_IMAGE   = var.wetty_image
      }
    )
    destination = "/home/${var.user}/docker-compose.yaml"

    connection {
      type        = "ssh"
      user        = var.user
      host        = openstack_networking_floatingip_v2.wetty_server.address
      private_key = tls_private_key.ssh_key.private_key_pem
    }
  }

  provisioner "file" {
    content = templatefile(
      "${path.module}/init-letsencrypt.sh",
      {
        HOST_NAME     = trimsuffix(openstack_dns_recordset_v2.wetty.name, ".")
        TRAINER_EMAIL = var.trainer_email
      }
    )
    destination = "/home/${var.user}/init-letsencrypt.sh"

    connection {
      type        = "ssh"
      user        = var.user
      host        = openstack_networking_floatingip_v2.wetty_server.address
      private_key = tls_private_key.ssh_key.private_key_pem
    }
  }

  provisioner "file" {
    content = templatefile(
      "${path.module}/.htpasswd",
      {
        PASSWORDS = random_password.student_password
      }
    )
    destination = "/home/${var.user}/htpasswd/.htpasswd"

    connection {
      type        = "ssh"
      user        = var.user
      host        = openstack_networking_floatingip_v2.wetty_server.address
      private_key = tls_private_key.ssh_key.private_key_pem
    }
  }
}
