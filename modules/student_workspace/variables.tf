variable "student_name" {
  type = string
}

variable "network" {
  type = string
}

variable "machine_type" {
  type = string
}

variable "instances" {
  type = list(string)
}

variable "course_type" {
  type = string
}

variable "trainer" {
  type = string
}


variable "solutions_url" {
  type    = string
  default = ""
}

variable "solutions_patch" {
  type    = string
  default = ""
}

variable "dns_domain" {
  type    = string
  default = ""
}

variable "router" {
  type    = string
  default = ""
}

### not used atm
variable "public_ip_ranges" {
  type = set(string)
  default = [
    "0.0.0.0/5",
    "8.0.0.0/7",
    "11.0.0.0/8",
    "12.0.0.0/6",
    "16.0.0.0/4",
    "32.0.0.0/3",
    "64.0.0.0/2",
    "128.0.0.0/3",
    "160.0.0.0/5",
    "168.0.0.0/6",
    "172.0.0.0/1",
    "172.32.0.0/1",
    "172.64.0.0/1",
    "172.128.0.0/9",
    "173.0.0.0/8",
    "174.0.0.0/7",
    "176.0.0.0/4",
    "192.0.0.0/9",
    "192.128.0.0/1",
    "192.160.0.0/1",
    "192.169.0.0/1",
    "192.170.0.0/1",
    "192.172.0.0/1",
    "192.176.0.0/1",
    "192.192.0.0/1",
    "193.0.0.0/8",
    "194.0.0.0/7",
    "196.0.0.0/6",
    "200.0.0.0/5",
    "208.0.0.0/4"
  ]
}
