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
  description = "config for wetty server, disabled by default"
  type = object({
    enabled       = bool,
    trainer_email = optional(string)
  })
  default = {
    enabled       = false
    trainer_email = "only required when enabled"
  }
  validation {
    condition = (
      anytrue([
        alltrue([
          var.wetty_config["enabled"] == true,
          can(regex("^\\S{1,}@\\S{2,}\\.\\S{2,}$", var.wetty_config["trainer_email"]))]
        ),
        var.wetty_config["enabled"] == false
        ]
      )
    )
    error_message = "When wetty_config is enabled, a valid trainer_email is required."
  }
}

variable "network_range" {
  description = "network range for the internal vpc"
}

variable "dns_domain" {
  description = "domain for creating DNS records, currently only used for wetty-server"
  default     = "training-lf-kubernetes.fra.ics.inovex.io."
}
