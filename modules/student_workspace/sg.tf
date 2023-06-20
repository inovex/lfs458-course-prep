resource "openstack_networking_secgroup_v2" "this" {
  name        = "sec-${var.student_name}"
  description = "security-group for ${var.trainer} training (${var.student_name})"
  tags = [
    var.course_type,
    format("trainer-%s", var.trainer),
    var.student_name
  ]
}

resource "openstack_networking_secgroup_rule_v2" "allow_nodeport" {
  #for_each          = var.public_ip_ranges
  direction      = "ingress"
  ethertype      = "IPv4"
  protocol       = "tcp"
  port_range_min = 32000
  port_range_max = 32767
  #remote_ip_prefix  = each.value
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.this.id
}

resource "openstack_networking_secgroup_rule_v2" "allow_ssh" {
  #for_each          = var.public_ip_ranges
  direction      = "ingress"
  ethertype      = "IPv4"
  protocol       = "tcp"
  port_range_min = 22
  port_range_max = 22
  #remote_ip_prefix  = each.value
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.this.id
}

resource "openstack_networking_secgroup_rule_v2" "allow_icmp" {
  #for_each          = var.public_ip_ranges
  direction = "ingress"
  ethertype = "IPv4"
  protocol  = "icmp"
  #remote_ip_prefix  = each.value
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.this.id
}

// Allow all internal traffic
resource "openstack_networking_secgroup_rule_v2" "allow_inside_traffic" {
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_group_id   = openstack_networking_secgroup_v2.this.id
  security_group_id = openstack_networking_secgroup_v2.this.id
}
