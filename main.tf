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

locals {
  student_workspaces = {
    for i, v in var.students : v => {
      cidrsubnet = cidrsubnet(var.network_range, 8, i + 1)
      instances  = var.instances #fixed for now
  } }
}

module "student_workspace" {
  source          = "./modules/student_workspace"
  for_each        = local.student_workspaces
  student_name    = each.key
  instances       = each.value.instances
  network         = each.value.cidrsubnet
  router          = openstack_networking_router_v2.router.id
  machine_type    = var.machine_type
  course_type     = var.course_type
  trainer         = var.trainer
  dns_domain      = var.dns_domain
  solutions_url   = var.solutions_url
  solutions_patch = fileexists("${path.module}/solutions.patch") ? filebase64("${path.module}/solutions.patch") : ""
}

locals {
  student_hosts = merge(
    [
      for value in module.student_workspace : value.instance_info
    ]...
  )
  student_ips_checksum = sha1(
    join(" ", [
      for value in module.student_workspace : value.ips_checksum
      ]
    )
  )
  student_keys_checksum = sha1(
    join(" ", [
      for value in module.student_workspace : value.keys_checksum
      ]
    )
  )
  student_secgroups = [
    for sg in module.student_workspace : sg.security_group
  ]
}

module "wetty_server" {
  count = var.wetty_config.enabled ? 1 : 0

  source        = "./modules/wetty_server"
  network       = cidrsubnet(var.network_range, 8, 0)
  machine_type  = var.machine_type
  course_type   = var.course_type
  trainer       = var.trainer
  instances     = local.student_hosts
  dns_domain    = var.dns_domain
  trainer_email = var.wetty_config.trainer_email
  sec_groups    = local.student_secgroups
  router        = openstack_networking_router_v2.router.id
}

resource "null_resource" "cluster" {
  triggers = {
    ips  = local.student_ips_checksum
    keys = local.student_keys_checksum
    #    passwords = join(",", flatten(module.wetty_server.*.student_passwords_hash))
  }

  provisioner "local-exec" {
    command = "./scripts/create_package.sh"
  }
}

output "wetty_server_address" {
  value = module.wetty_server.*.wetty_server_address
}
