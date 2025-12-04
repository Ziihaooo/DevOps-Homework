variable "env_name" {}
variable "project_name" {}

variable "vpc_id" {}
variable "public_subnet_ids" {}
variable "private_subnet_ids" {}

variable "alb_sg_ingress" {}
variable "alb_sg_egress" {}
variable "ecs_sg_ingress" {}
variable "ecs_sg_egress" {}

variable "nat_name" {}
variable "alb_name" {}
variable "alb_listener_port" {}
variable "alb_listener_protocol" {}
variable "alb_tags" {}

variable "execution_role_name" {}
variable "execution_assume_policy" {}
variable "execution_managed_policies" {}
variable "execution_inline_policies" {}

variable "task_role_name" {}
variable "task_assume_policy" {}
variable "task_managed_policies" {}
variable "task_inline_policies" {}

variable "ecs_cpu" {}
variable "ecs_memory" {}
variable "ecs_desired_count" {}

variable "lb_container_name" {}
variable "lb_container_port" {}
