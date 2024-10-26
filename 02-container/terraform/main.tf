terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "2.0.0"
    }
  }
}
provider "openstack" {
  auth_url    = "https://keystone.cloud.switch.ch:5000/v3"  # OS_AUTH_URL
  region      = "LS"                                        # OS_REGION_NAME
  tenant_name = "cloud_hs24_06"             # OS_PROJECT_NAME
  user_name   = var.USER_EMAIL              # OS_USERNAME
  password    = var.OPENSTACK_KEY  # OS_PASSWORD
  domain_name = "Default"                                   # OS_USER_DOMAIN_NAME
}

resource "openstack_compute_instance_v2" "container-lxc-host" {
  name        = "container-lxc-host"
  flavor_id   = "3" # m1.medium
  key_pair    = var.SSH_KEYPAIR
  security_groups = ["default","SSH","monitoring"]

    block_device {
    uuid                  = openstack_blockstorage_volume_v3.my_volume.id
    source_type          = "volume"
    destination_type     = "volume"
    boot_index           = 0
    delete_on_termination = true
  }


  network {
  name = "private"  # Privates Netzwerk
}

}
resource "openstack_networking_floatingip_v2" "floating_ip" {
  pool = "public"
}
resource "openstack_networking_floatingip_v2" "floating_ip_for_Damjan" {
  pool = "public"
}

data "openstack_networking_port_v2" "terraform-vm" {
  fixed_ip = openstack_compute_instance_v2.container-lxc-host.access_ip_v4
}

resource "openstack_networking_floatingip_associate_v2" "fip_assoc" {
  floating_ip = openstack_networking_floatingip_v2.floating_ip.address
  port_id     = data.openstack_networking_port_v2.terraform-vm.id

}

resource "openstack_blockstorage_volume_v3" "my_volume" {
  name        = "my-volume"
  size        = 50
  description = "50GB volume for container-lxc-host"
  availability_zone = "nova"
  image_id    = "c9d0280a-71dd-428c-9011-cbfd39bf9dc1"  # Image ID für Debian Bookworm 12
}

output "floating_ip" {
  value = openstack_networking_floatingip_v2.floating_ip.address
}
