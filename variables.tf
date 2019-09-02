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

