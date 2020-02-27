provider "tls" {
  version = "~> 2.1.0"
}

provider "local" {
  version = "~> 1.3.0"
}

data "google_compute_zones" "available" {}

locals {
  student_instances = setproduct(var.students, var.instances)
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
resource "google_compute_instance" "node" {
  count          = length(local.student_instances)
  name           = "${element(local.student_instances, count.index)[0]}-${element(local.student_instances, count.index)[1]}"
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

  metadata_startup_script = <<EOF
  apt-get update && apt-get install -y python
  modprobe br_netfilter && echo '1' > /proc/sys/net/ipv4/ip_forward
  echo -ne 'filetype plugin indent on\nset expandtab\nset tabstop=2\nset softtabstop=2\nset shiftwidth=2\nset softtabstop=2\n' > /home/student/.vimrc
  echo 'alias tailf="tail -f"' >> /home/student/.bashrc
  touch /home/student/.rnd"
EOF

  metadata = {
    ssh-keys = "student:${trimspace(tls_private_key.ssh_key[element(local.student_instances, count.index)[0]].public_key_openssh)} student"
  }

  service_account {
    scopes = []
  }

  labels = {
    environment = var.course_type
    student     = "${element(local.student_instances, count.index)[0]}"
  }
}

resource "local_file" "public_ips" {
  for_each = toset(var.students)
  content  = join("\n", [for i in google_compute_instance.node.* : i.network_interface.0.access_config.0.nat_ip if i.labels.student == each.value])
  filename = "${path.cwd}/ips/${each.value}"
}
