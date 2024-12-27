


resource "openstack_networking_secgroup_v2" "security_group" {
  name        = "default_security_group_ceph"
  description = "Security group for SSH and all egress traffic"
}

resource "openstack_networking_secgroup_rule_v2" "ICMP" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  security_group_id = openstack_networking_secgroup_v2.security_group.id
  remote_ip_prefix  = "0.0.0.0/0"
}

  resource "openstack_networking_secgroup_rule_v2" "Docker-Swarm" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  security_group_id = openstack_networking_secgroup_v2.security_group.id
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "ingress_ipv4" {
  direction         = "ingress"
  ethertype         = "IPv4"
  security_group_id = openstack_networking_secgroup_v2.security_group.id
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "ingress_ipv6" {
  direction         = "ingress"
  ethertype         = "IPv6"
  security_group_id = openstack_networking_secgroup_v2.security_group.id
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "::/0"
}
