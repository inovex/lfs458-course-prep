terraform {
  required_version = "~>0.12.7"

  required_providers {
    openstack = ">= 1.28"
  }
}

provider "openstack" {
  cloud = var.cloud
}

provider "null" {
  version = "~> 2.1"
}

module "student_workspace" {
  source       = "./modules/student_workspace"
  students     = var.students
  instances    = var.instances
  network      = openstack_networking_network_v2.network.id
  machine_type = var.machine_type
  course_type  = var.course_type
  trainer      = var.trainer
  sec_groups   = [openstack_networking_secgroup_v2.sec.name]
  zone_id      = openstack_dns_zone_v2.project-zone.id
  dns_domain   = var.dns_domain
}

resource "null_resource" "cluster" {
  triggers = {
    ips  = "${module.student_workspace.ips_checksum}"
    keys = "${module.student_workspace.keys_checksum}"
  }

  provisioner "local-exec" {
    command = "./scripts/create_package.sh"
  }
}
