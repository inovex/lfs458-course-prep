data "openstack_networking_network_v2" "public" {
  name = "public"
}

data "openstack_images_image_v2" "ubuntu" {
  name        = var.ubuntu_image
  most_recent = true
  visibility  = "public"
}
