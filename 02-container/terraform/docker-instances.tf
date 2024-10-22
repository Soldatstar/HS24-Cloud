
variable "docker_instance_names" {
  type    = list(string)
  default = ["docker-mgr-01", "docker-wrk-01", "docker-wrk-02"]
}

resource "openstack_blockstorage_volume_v3" "docker_volumes" {
  for_each = toset(var.docker_instance_names)

  name        = "${each.key}-volume"
  size        = 50
  description = "50GB volume for ${each.key}"
  availability_zone = "nova"
  image_id    = "c9d0280a-71dd-428c-9011-cbfd39bf9dc1"  # Image ID für Debian Bookworm 12
}

resource "openstack_compute_instance_v2" "docker_instances" {
  for_each = toset(var.docker_instance_names)

  name        = each.key
  flavor_id   = "3" # m1.medium
  key_pair    = var.SSH_KEYPAIR
  security_groups = ["default","SSH","monitoring"]

  network {
    name = "private"  # Privates Netzwerk
  }

  block_device {
    uuid                  = openstack_blockstorage_volume_v3.docker_volumes[each.key].id
    source_type          = "volume"
    destination_type     = "volume"
    boot_index           = 0
    delete_on_termination = true
  }
}

resource "openstack_networking_floatingip_v2" "floating_ips" {
  for_each = toset(var.docker_instance_names)

  pool = "public"
}

data "openstack_networking_port_v2" "docker_ports" {
  for_each = toset(var.docker_instance_names)

  fixed_ip = openstack_compute_instance_v2.docker_instances[each.key].access_ip_v4
}

resource "openstack_networking_floatingip_associate_v2" "fip_assoc_docker" {
  for_each = toset(var.docker_instance_names)

  floating_ip = openstack_networking_floatingip_v2.floating_ips[each.key].address
  port_id     = data.openstack_networking_port_v2.docker_ports[each.key].id
}
output "floating_ips" {
  value = [for fip in openstack_networking_floatingip_v2.floating_ips : fip.address]
}