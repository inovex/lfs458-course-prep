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
