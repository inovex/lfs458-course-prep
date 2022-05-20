variable "students" {
  type = list(string)
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

variable "sec_groups" {
  type = list(string)
}

variable "solutions_url" {
  type = string
  default = ""
}

variable "solutions_patch" {
  type = string
  default = ""
}