data "openstack_networking_network_v2" "public" {
  name = "public"
}

resource "openstack_networking_network_v2" "network" {
  name           = var.trainer
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet" {
  name       = "${var.trainer}_subnet"
  network_id = openstack_networking_network_v2.network.id
  cidr       = var.network_range
  ip_version = 4
}

resource "openstack_networking_router_v2" "router" {
  name                = "${var.trainer}_gateway"
  external_network_id = data.openstack_networking_network_v2.public.id
}

resource "openstack_networking_router_interface_v2" "router_interface_internal" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnet.id
}

resource "openstack_networking_secgroup_v2" "sec" {
  name        = "sec-${var.trainer}"
  description = "sec-group for ${var.trainer} training"
}

resource "openstack_networking_secgroup_rule_v2" "sec-all" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.sec.id
}

// Allow all internal traffic
resource "openstack_networking_secgroup_rule_v2" "secgroup_node_rule_allow_inside" {
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_group_id   = openstack_networking_secgroup_v2.sec.id
  security_group_id = openstack_networking_secgroup_v2.sec.id
}

resource "openstack_dns_zone_v2" "project-zone" {
  name  = var.dns_domain
  email = "hostmaster@inovex.io"
  type  = "PRIMARY"
  ttl   = 60
}
