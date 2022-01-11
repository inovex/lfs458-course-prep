variable "network" {
  type = string
}

variable "machine_type" {
  type = string
}

variable "course_type" {
  type = string
}

variable "trainer" {
  type = string
}

variable "sec_groups" {
  type = list(string)
}

variable "dns_domain" {
  type = string
}

variable "instances" {
  type = map(object({
    ip      = string,
    student = string,
    ssh_key = string
  }))
}

variable "trainer_email" {
  type = string
}

variable "user" {
  type    = string
  default = "student"
}

variable "nginx_image" {
  type    = string
  default = "nginx:1.21.4"
}

variable "certbot_image" {
  type    = string
  default = "certbot/certbot" # FIXME: Pin?
}

variable "wetty_image" {
  type    = string
  default = "wettyoss/wetty" # FIXME: Pin?
}
