data "openstack_networking_network_v2" "public" {
  name = "public"
}


resource "openstack_networking_router_v2" "router" {
  name                = "${var.trainer}_gateway"
  external_network_id = data.openstack_networking_network_v2.public.id
  tags = [
    var.course_type,
    format("trainer-%s", var.trainer)
  ]
}



