terraform {
  required_version = ">= 0.15.1"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.41.0"
    }
  }
}
