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

variable "user" {
  type    = string
  default = "registry"
}

variable "registry_data_size" {
  type        = number
  description = "Size of the data volume for the registry in GB"
  default     = 60
}
