
variable "k3s_instance_names" {
  type    = list(string)
  default = ["benchmarkNode01"]# "k3snode02"]
}

resource "openstack_blockstorage_volume_v3" "k3s_volumes" {
  for_each = toset(var.k3s_instance_names)

  name        = "${each.key}-volume"
  size        = 50
  description = "50GB volume for ${each.key}"
  availability_zone = "nova"
  image_id           = data.openstack_images_image_v2.debian12.id
}

resource "openstack_compute_instance_v2" "k3s_instances" {
  for_each = toset(var.k3s_instance_names)

  name        = each.key
  flavor_id   = "4" # m1.medium
  key_pair    = var.SSH_KEYPAIR
  security_groups = [openstack_networking_secgroup_v2.ICMP_security_group.name,
    openstack_networking_secgroup_v2.monitoring_security_group.name]

  network {
    name = "private"  # Privates Netzwerk
  }

  block_device {
    uuid                  = openstack_blockstorage_volume_v3.k3s_volumes[each.key].id
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

resource "openstack_networking_floatingip_v2" "k3s_floating_ips" {
  for_each = toset(var.k3s_instance_names)

  pool = "public"
}

data "openstack_networking_port_v2" "k3s_ports" {
  for_each = toset(var.k3s_instance_names)

  fixed_ip = openstack_compute_instance_v2.k3s_instances[each.key].access_ip_v4
}

resource "openstack_networking_floatingip_associate_v2" "fip_assoc_k3s" {
  for_each = toset(var.k3s_instance_names)

  floating_ip = openstack_networking_floatingip_v2.k3s_floating_ips[each.key].address
  port_id     = data.openstack_networking_port_v2.k3s_ports[each.key].id
}
output "floating_ips" {
  value = [for fip in openstack_networking_floatingip_v2.k3s_floating_ips : fip.address]
}

output "private_ips" {
  value = [for instance in openstack_compute_instance_v2.k3s_instances : instance.network[0].fixed_ip_v4]
}