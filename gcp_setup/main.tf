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

provider "google" {
  credentials = file("account.json")
  project     = var.project
  region      = var.region
}


resource "google_compute_network" "vpc_network" {
  name                    = "lfs458-network"
  auto_create_subnetworks = "true"
  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}

resource "google_compute_firewall" "allow_all" {
  name    = "allow-all"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "all"
  }
  source_ranges = [ "0.0.0.0/0" ]
}

module "student_workspace" {
  source       = "./modules/student_workspace"
  students     = var.students
  instances    = var.instances
  network      = google_compute_network.vpc_network.name
  machine_type = var.machine_type
  course_type  = var.course_type
}

resource "null_resource" "cluster" {
  triggers = {
    ips  = "${module.student_workspace.ips_checksum}"
    keys = "${module.student_workspace.keys_checksum}"
  }

  provisioner "local-exec" {
    command = "./create_package.sh"
  }
}
