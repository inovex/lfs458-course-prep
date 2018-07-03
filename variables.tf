variable trainer {
  type = "string"
}

variable resource_group {
  type = "string"
}

variable cidr {
  type    = "string"
  default = "10.0.0.0/16"
}

variable location {
  type = "string"
}

variable instance_type {
  type = "string"
}

variable students {
  type    = "list"
  default = []
}
