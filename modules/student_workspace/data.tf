data "openstack_networking_network_v2" "public" {
  name = "public"
}

data "openstack_images_image_v2" "ubuntu" {
  most_recent = true
  visibility  = "public"

  properties = {
    os_distro  = "ubuntu"
    os_version = "18.04"
  }
}
