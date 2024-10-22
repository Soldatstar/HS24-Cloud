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
  tenant_name = var.USER_EMAIL             # OS_PROJECT_NAME
  user_name   = var.USER_EMAIL              # OS_USERNAME
  password    = var.OPENSTACK_KEY  # OS_PASSWORD
  domain_name = "Default"                                   # OS_USER_DOMAIN_NAME
}

resource "openstack_blockstorage_volume_v3" "myvol" {
  name     = "myvol"
  size     = 5
  image_id = "<image-id>"
}


resource "openstack_compute_instance_v2" "instance" {
  name            = "my-instance"
  image_id        = "c9d0280a-71dd-428c-9011-cbfd39bf9dc1"  # Image ID für Debian Bookworm 12
  flavor_name     = "m1.small"                              # Flavor muss entsprechend gewählt werden
  key_pair        = "my_ssh_key"                            # Dein SSH-Key
  security_groups = [openstack_networking_secgroup_v2.secgroup.name]
  network {
    uuid = openstack_networking_network_v2.net.id
  }
}
resource "openstack_compute_instance_v2" "boot-from-volume" {
  name      = "bootfromvolume"
  flavor_id = "3"
  key_pair  = var.SSH_KEYPAIR
  security_groups = ["default"]

  block_device {
    uuid                  = openstack_blockstorage_volume_v3.myvol.id
    source_type           = "volume"
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }

  network {
    name = "my_network"
  }
}

resource "openstack_compute_flavor_v2" "container-flavor" {
  name  = "my-flavor"
  ram   = "4048"
  vcpus = "2"
  disk  = "50"

}
