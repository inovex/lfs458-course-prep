provider "openstack" {
  cloud = var.cloud
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
}

module "wetty_server" {
  source       = "./modules/wetty_server"
  network      = openstack_networking_network_v2.network.id
  machine_type = var.machine_type
  course_type  = var.course_type
  trainer      = var.trainer
  sec_groups   = [openstack_networking_secgroup_v2.sec.name]
  instances    = module.student_workspace.instance_info
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

output "wetty_server_address" {
  value = module.wetty_server.wetty_server_address
}
