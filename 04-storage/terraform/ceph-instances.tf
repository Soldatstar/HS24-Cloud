variable "storage_instance_names" {
  type    = list(string)
  default = ["monitor01", "osd01", "osd02", "osd03"]
}

resource "openstack_blockstorage_volume_v3" "root_volumes" {
  for_each = toset(var.storage_instance_names)

  name              = "${each.key}-root-volume"
  size              = 10  # Set the root disk size to 10GB
  description       = "10GB root volume for ${each.key}"
  availability_zone = "nova"
  image_id          = data.openstack_images_image_v2.debian12.id  # Use the dynamic image ID
}

resource "openstack_blockstorage_volume_v3" "storage_volumes" {
  for_each = toset(var.storage_instance_names)

  name              = "${each.key}-storage-volume"
  size              = 40
  description       = "40GB volume for ${each.key}"
  availability_zone = "nova"
}

resource "openstack_compute_instance_v2" "storage_instances" {
  for_each = toset(var.storage_instance_names)

  name        = each.key
  flavor_id   = "3" # m1.medium
  key_pair    = var.SSH_KEYPAIR
  security_groups = [
    openstack_networking_secgroup_v2.security_group.name
  ]

  network {
    name = "private"  # Private network
  }

  block_device {
    uuid                  = openstack_blockstorage_volume_v3.root_volumes[each.key].id
    source_type           = "volume"
    destination_type      = "volume"
    boot_index            = 0
    delete_on_termination = true
  }

  block_device {
    uuid                  = openstack_blockstorage_volume_v3.storage_volumes[each.key].id
    source_type           = "volume"
    destination_type      = "volume"
    boot_index            = 1
    delete_on_termination = false
  }

  lifecycle {
    ignore_changes = [
      key_pair,  # Ignore changes to the key_pair attribute
    ]
  }
}

resource "openstack_networking_floatingip_v2" "k8s_floating_ips" {
  for_each = toset(var.storage_instance_names)

  pool = "public"
}

data "openstack_networking_port_v2" "k8s_ports" {
  for_each = toset(var.storage_instance_names)

  fixed_ip = openstack_compute_instance_v2.storage_instances[each.key].access_ip_v4
}

resource "openstack_networking_floatingip_associate_v2" "fip_assoc_k8s" {
  for_each = toset(var.storage_instance_names)

  floating_ip = openstack_networking_floatingip_v2.k8s_floating_ips[each.key].address
  port_id     = data.openstack_networking_port_v2.k8s_ports[each.key].id
}

output "floating_ips_k8s" {
  value = [for fip in openstack_networking_floatingip_v2.k8s_floating_ips : fip.address]
}

output "private_ips_k8s" {
  value = [for instance in openstack_compute_instance_v2.storage_instances : instance.network[0].fixed_ip_v4]
}
