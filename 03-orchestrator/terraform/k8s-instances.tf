
variable "k8s_instance_names" {
  type    = list(string)
  default = ["k8smain01", "k8smain02", "k8sworker01"]
}

resource "openstack_blockstorage_volume_v3" "k8s_volumes" {
  for_each = toset(var.k8s_instance_names)

  name        = "${each.key}-volume"
  size        = 50
  description = "50GB volume for ${each.key}"
  availability_zone = "nova"
  image_id           = data.openstack_images_image_v2.debian12.id  # Use the dynamic image ID
}

resource "openstack_compute_instance_v2" "k8s_instances" {
  for_each = toset(var.k8s_instance_names)

  name        = each.key
  flavor_id   = "3" # m1.medium
  key_pair    = var.SSH_KEYPAIR
  security_groups = [openstack_networking_secgroup_v2.security_group.name,
    openstack_networking_secgroup_v2.monitoring_security_group.name,
    openstack_networking_secgroup_v2.k8s_control_plane_security_group.name,
    openstack_networking_secgroup_v2.k8s_worker_security_group.name]

  network {
    name = "private"  # Privates Netzwerk
  }

  block_device {
    uuid                  = openstack_blockstorage_volume_v3.k8s_volumes[each.key].id
    source_type          = "volume"
    destination_type     = "volume"
    boot_index           = 0
    delete_on_termination = true
  }

    lifecycle {
    ignore_changes = [
      key_pair,  # Ignore changes to the key_pair attribute
    ]
  }
}

resource "openstack_networking_floatingip_v2" "k8s_floating_ips" {
  for_each = toset(var.k8s_instance_names)

  pool = "public"
}

data "openstack_networking_port_v2" "k8s_ports" {
  for_each = toset(var.k8s_instance_names)

  fixed_ip = openstack_compute_instance_v2.k8s_instances[each.key].access_ip_v4
}

resource "openstack_networking_floatingip_associate_v2" "fip_assoc_k8s" {
  for_each = toset(var.k8s_instance_names)

  floating_ip = openstack_networking_floatingip_v2.k8s_floating_ips[each.key].address
  port_id     = data.openstack_networking_port_v2.k8s_ports[each.key].id
}
output "floating_ips_k8s" {
  value = [for fip in openstack_networking_floatingip_v2.k8s_floating_ips : fip.address]
}

output "private_ips_k8s" {
  value = [for instance in openstack_compute_instance_v2.k8s_instances : instance.network[0].fixed_ip_v4]
}