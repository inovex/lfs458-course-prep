output "network_id" {
  value = openstack_networking_network_v2.network.id
}

output "secgroup_name" {
  value = openstack_networking_secgroup_v2.sec.name
}

output "secgroup_rules" {
  value = [ openstack_networking_secgroup_rule_v2.sec-all, openstack_networking_secgroup_rule_v2.secgroup_node_rule_allow_inside ]
}
