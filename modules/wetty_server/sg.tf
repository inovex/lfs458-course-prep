resource "openstack_networking_secgroup_v2" "wetty_self" {
  name        = "sec-wetty-server"
  description = "security-group for ${var.trainer} training (wetty-server)"
  tags = [
    var.course_type,
    format("trainer-%s", var.trainer),
    "wetty"
  ]
}

resource "openstack_networking_secgroup_rule_v2" "allow_ssh" {
  for_each          = toset(["80", "443"])
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = each.value
  port_range_max    = each.value
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.wetty_self.id
}
