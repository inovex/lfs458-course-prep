terraform {
  experiments = [module_variable_optional_attrs]

  required_version = ">= 1.0.10"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 1.45.0"
    }
  }
}
