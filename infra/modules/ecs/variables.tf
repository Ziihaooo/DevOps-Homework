variable "project_name" { type = string }
variable "cpu"          { type = number }
variable "memory"       { type = number }

variable "execution_role_arn" { type = string }
variable "task_role_arn"      { type = string }

variable "desired_count" {
  type    = number
  default = 1
}

variable "private_subnets" {
  type = list(string)
}

variable "service_sg" {
  type = string
}

# Multiple containers: app + nginx
variable "containers" {
  type = list(any)
}

# ALB mappings
variable "load_balancers" {
  type = list(object({
    target_group_arn = string
    container_name   = string
    container_port   = number
  }))
  default = []
}


