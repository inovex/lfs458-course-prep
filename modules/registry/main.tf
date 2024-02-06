resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "local_file" "private_key_pem" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "${path.cwd}/keys/registry"

  provisioner "local-exec" {
    command = "chmod 600 ${path.cwd}/keys/registry"
  }
}

resource "openstack_blockstorage_volume_v3" "registry_data" {
  name = "registry-${var.course_type}-${var.trainer}-data"
  size = var.registry_data_size
}

resource "openstack_compute_instance_v2" "registry" {
  name            = "registry-${var.course_type}-${var.trainer}"
  flavor_name     = var.machine_type
  security_groups = var.sec_groups
  user_data = templatefile(
    "${path.module}/cloudinit.yaml",
    {
      USER        = var.user
      SSH_PUB_KEY = trimspace(tls_private_key.ssh_key.public_key_openssh)
    }
  )

  tags = [
    "registry",
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

  block_device {
    uuid             = openstack_blockstorage_volume_v3.registry_data.id
    source_type      = "volume"
    destination_type = "volume"
    boot_index       = 1
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
