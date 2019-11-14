data "google_compute_zones" "available" {}

resource "google_compute_instance" "node" {
  count          = "${length(var.students)}"
  name           = "${var.students[count.index]}-${var.name}"
  machine_type   = "${var.machine_type}"
  zone           = "${data.google_compute_zones.available.names[0]}"
  can_ip_forward = "true"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  network_interface {
    network = "${var.network}"

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
    ssh-keys = "student:${trimspace(var.public_ssh_keys[count.index])} student"
  }

  service_account {
    scopes = []
  }

  labels = {
    environment = "lfs458"
    student     = "${var.students[count.index]}"
  }
}
