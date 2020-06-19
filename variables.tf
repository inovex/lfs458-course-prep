variable "cloud" {
  description = "credentials to obtain from ~/.config/openstack/clouds.yaml"
  default     = "training-lf-kubernetes"
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

variable "trainer" {
  description = "Trainer name which holds the course"
  type        = string
}

variable "network_range" {
  description = "network range for the internal vpc"
}
