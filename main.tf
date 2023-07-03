provider "openstack" {
  cloud = var.cloud
}

## REMOTE STATE
# terraform {
#     backend "swift" {}
# }

# Run this to set the required backend options:
#-------------------------------------------------
# terraform init \
# -backend-config="cloud=training-lf-kubernetes" \
# -backend-config="container=training-lf-kubernetes-terraform-state" \
# -backend-config="archive_container=training-lf-kubernetes-terraform-state-archive" \
# -backend-config="state_name=terraform-$TRAINER_NAME.stat"

module "network" {
  source        = "./modules/network"
  trainer       = var.trainer
  course_type   = var.course_type
  network_range = var.network_range
}


module "student_workspace" {
  source          = "./modules/student_workspace"
  students        = var.students
  instances       = var.instances
  network         = module.network.network_id
  machine_type    = var.machine_type
  course_type     = var.course_type
  trainer         = var.trainer
  dns_domain      = var.dns_domain
  sec_groups      = [module.network.secgroup_name]
  solutions_url   = var.solutions_url
  solutions_patch = fileexists("${path.module}/solutions.patch") ? filebase64("${path.module}/solutions.patch") : ""

  depends_on = [ module.network ]
}

module "wetty_server" {
  count = var.wetty_config.enabled ? 1 : 0

  source        = "./modules/wetty_server"
  network       = module.network.network_id
  machine_type  = var.machine_type
  course_type   = var.course_type
  trainer       = var.trainer
  sec_groups    = [module.network.secgroup_name]
  instances     = module.student_workspace.instance_info
  dns_domain    = var.dns_domain
  trainer_email = var.wetty_config.trainer_email
}

resource "null_resource" "cluster" {
  triggers = {
    ips       = "${module.student_workspace.ips_checksum}"
    keys      = "${module.student_workspace.keys_checksum}"
    passwords = join(",", flatten(module.wetty_server.*.student_passwords_hash))
  }

  provisioner "local-exec" {
    command = "./scripts/create_package.sh"
  }
}

output "wetty_server_address" {
  value = module.wetty_server.*.wetty_server_address
}
