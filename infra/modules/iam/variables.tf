variable "role_name" {
  type = string
}

variable "assume_role_policy" {
  type = string
}

variable "managed_policy_arns" {
  type    = list(string)
  default = []
}

variable "inline_policies" {
  type = list(object({
    name   = string
    policy = string
  }))
  default = []
}

variable "create_instance_profile" {
  type    = bool
  default = false
}
