terraform {
  required_version = "~>1"
  required_providers {
    google = {
      source = "google"
      version = "~> 4.0.0"
    }

    null = {
      source = "null"
      version = "~> 3.1"
    }

    tls = {
      source = "tls"
      version = "~> 3.1.0"
    }

    local = {
      source = "local"
      version = "~> 2.1.0"
    }
  }
}

data "google_compute_zones" "available" {}

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
// We use for_each here becase count would destroy machines if we change the number of instances
resource "google_compute_instance" "node" {
  for_each       = local.student_instances
  name           = each.value
  machine_type   = var.machine_type
  zone           = data.google_compute_zones.available.names[0]
  can_ip_forward = "true"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  network_interface {
    network = var.network

    access_config {
      // Ephemeral IP
    }
  }

  metadata_startup_script = file("${path.module}/cloudinit.yaml")

  metadata = {
    ssh-keys = "student:${trimspace(tls_private_key.ssh_key[split("-", each.value)[0]].public_key_openssh)} student"
  }

  service_account {
    scopes = []
  }

  labels = {
    environment = var.course_type
    student     = split("-", each.value)[0]
  }
}

resource "local_file" "public_ips" {
  for_each = toset(var.students)
  content  = join("\n", [for i in values(google_compute_instance.node).* : i.network_interface.0.access_config.0.nat_ip if i.labels.student == each.value])
  filename = "${path.cwd}/ips/${each.value}.txt"
}
