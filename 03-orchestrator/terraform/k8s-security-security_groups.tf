# Security group for Kubernetes control plane
resource "openstack_networking_secgroup_v2" "k8s_control_plane_security_group" {
  name        = "k8s_control_plane_security_group"
  description = "Security group for Kubernetes control plane nodes"
}

# Control Plane Security Group Rules
resource "openstack_networking_secgroup_rule_v2" "control_plane_k8s_api" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  security_group_id = openstack_networking_secgroup_v2.k8s_control_plane_security_group.id
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "control_plane_etcd_api" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 2379
  port_range_max    = 2380
  security_group_id = openstack_networking_secgroup_v2.k8s_control_plane_security_group.id
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "control_plane_kubelet_api" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10250
  port_range_max    = 10250
  security_group_id = openstack_networking_secgroup_v2.k8s_control_plane_security_group.id
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "control_plane_scheduler" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10259
  port_range_max    = 10259
  security_group_id = openstack_networking_secgroup_v2.k8s_control_plane_security_group.id
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "control_plane_controller_manager" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10257
  port_range_max    = 10257
  security_group_id = openstack_networking_secgroup_v2.k8s_control_plane_security_group.id
  remote_ip_prefix  = "0.0.0.0/0"
}

# Security group for Kubernetes worker nodes
resource "openstack_networking_secgroup_v2" "k8s_worker_security_group" {
  name        = "k8s_worker_security_group"
  description = "Security group for Kubernetes worker nodes"
}

# Worker Node Security Group Rules
resource "openstack_networking_secgroup_rule_v2" "worker_node_kubelet_api" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10250
  port_range_max    = 10250
  security_group_id = openstack_networking_secgroup_v2.k8s_worker_security_group.id
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "worker_node_kube_proxy" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10256
  port_range_max    = 10256
  security_group_id = openstack_networking_secgroup_v2.k8s_worker_security_group.id
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "worker_node_nodeport_services" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 30000
  port_range_max    = 32767
  security_group_id = openstack_networking_secgroup_v2.k8s_worker_security_group.id
  remote_ip_prefix  = "0.0.0.0/0"
}
