terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "HS24-Cloud"

    workspaces {
      name = "04-storage"
    }
  }

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
  tenant_name = "cloud_hs24_06"                             # OS_PROJECT_NAME
  user_name   = var.USER_EMAIL                              # OS_USERNAME
  password    = var.OPENSTACK_KEY                           # OS_PASSWORD
  domain_name = "Default"                                   # OS_USER_DOMAIN_NAME
}

