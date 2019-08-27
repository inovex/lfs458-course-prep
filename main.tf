terraform {
  required_version = "~>0.11.14"
}

provider "google" {
  version     = "~> v1.19.1"
  credentials = "${file("account.json")}"
  project     = "${var.project}"
  region      = "${var.region}"
}

provider "null" {
  version = "~> 2.1"
}

resource "google_compute_network" "vpc_network" {
  name                    = "lfs458-network"
  auto_create_subnetworks = "true"
}

resource "google_compute_firewall" "allow_all" {
  name    = "allow-all"
  network = "${google_compute_network.vpc_network.name}"

  allow {
    protocol = "all"
  }
}

module student_workspace {
  source       = "./modules/student_workspace"
  students     = "${var.students}"
  network      = "${google_compute_network.vpc_network.name}"
  machine_type = "${var.machine_type}"
}

resource "null_resource" "cluster" {
  triggers = {
    ips  = "${ module.student_workspace.ips_checksum}"
    keys = "${module.student_workspace.keys_checksum}"
  }

  provisioner "local-exec" {
    command = "./create_package.sh"
  }
}
