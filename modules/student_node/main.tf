resource "google_compute_instance" "node" {
  count          = "${length(var.students)}"
  name           = "${var.students[count.index]}-${var.name}"
  machine_type   = "${var.machine_type}"
  zone           = "${var.zone}"
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

  metadata_startup_script = "modprobe br_netfilter && echo '1' > /proc/sys/net/ipv4/ip_forward"

  metadata {
    ssh-keys = "student:${trimspace(var.public_ssh_keys[count.index])} student"
  }

  service_account {
    scopes = []
  }

  labels {
    environment = "lfs458"
    student     = "${var.students[count.index]}"
  }
}
