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

variable "wetty_config" {
  description = "config for wetty server, set enabled to 1 to deploy"
  type = object({
    enabled       = number,
    trainer_email = string
  })
  default = {
    enabled       = 0
    trainer_email = "only required when enabled=1"
  }
}

variable "network_range" {
  description = "network range for the internal vpc"
}

variable "dns_domain" {
  description = "domain for creating DNS records, currently only used for wetty-server"
  default     = "training-lf-kubernetes.fra.ics.inovex.io."
}
