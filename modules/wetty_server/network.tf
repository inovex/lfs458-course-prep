resource "openstack_networking_network_v2" "network" {
  name           = "${var.trainer}-wetty"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet" {
  name       = "${var.trainer}-wetty-subnet"
  network_id = openstack_networking_network_v2.network.id
  cidr       = var.network
  ip_version = 4

  tags = [
    var.course_type,
    format("trainer-%s", var.trainer),
    "wetty"
  ]
}

resource "openstack_networking_router_interface_v2" "router_interface_internal" {
  router_id = var.router
  subnet_id = openstack_networking_subnet_v2.subnet.id
}
