data "openstack_networking_network_v2" "public" {
  name = "public"
}

data "openstack_images_image_v2" "ubuntu" {
  name = "ubuntu-20.04-x86_64"
  most_recent = true
  visibility  = "public"
}
