data "openstack_images_image_v2" "ubuntu" {
  most_recent = true
  visibility  = "public"

  properties = {
    os_distro  = "ubuntu"
    os_version = "18.04"
  }
}
