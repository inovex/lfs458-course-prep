variable "region" {
  type = string
}

variable "project" {
  type = string
}

variable "machine_type" {
  type = string
}

variable "students" {
  type    = list(string)
  default = []
}

variable "instances" {
  type = list(string)
  // "proxy", "second-master", "third-master"
  default = ["master", "node"]
}

variable "course_type" {
  type    = string
  default = "lfs458"
}
