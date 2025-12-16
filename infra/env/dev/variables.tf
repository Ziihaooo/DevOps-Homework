variable "env_name" {}
variable "project_name" {}
variable "vpc_id" {}
variable "public_subnet_ids" {}
variable "private_subnet_ids" {}

########################
# SQS
########################
variable "sqs_name" {
  type = string
}

variable "visibility_timeout_seconds" {
  type = number
}

variable "message_retention_seconds" {
  type = number
}

variable "receive_wait_time_seconds" {
  type = number
}

variable "dlq_max_receive_count" {
  type = number
}

########################
# Route53
########################
variable "base_domain" {
  type = string
}

########################
# IAM for Lambda
########################
variable "lambda_role_name" {
  type = string
}

variable "lambda_assume_role_policy" {
  type = any
}

variable "lambda_managed_policies" {
  type = list(string)
}

variable "lambda_inline_policies" {
  type = list(object({
    name   = string
    policy = any
  }))
}

########################
# Lambda Function
########################
variable "lambda_name" {
  type = string
}

variable "lambda_zip_path" {
  type = string
}

variable "lambda_timeout" {
  type = number
}
########################
# Security groups
########################

variable "alb_sg_ingress" {}
variable "alb_sg_egress" {}
variable "grafana_sg_ingress" {}
variable "grafana_sg_egress" {}

############################################
# NAT 
############################################
variable "nat_name" {
  type = string
}

#############################################
# ALB CONFIG
#############################################
variable "alb_name" {}
variable "alb_listener_port" {}
variable "alb_listener_protocol" {}
variable "alb_tags" {}
variable "target_port" {}
variable "target_protocol" {}
variable "health_check_path" {}

#############################################
# Cloudwatch
#############################################
variable "cloudwatchname" {}
variable "retention_in_days" {}
variable "grafanacw" {}
variable "grafana_retention_in_days" {}
##############################
# Grafana IAM variables
##############################

/*
variable "grafana_role_name" {
  type = string
}

variable "grafana_assume_role_policy" {
  type = any
}

variable "grafana_managed_policies" {
  type = list(string)
}

variable "grafana_inline_policies" {
  type = list(object({
    name   = string
    policy = any
  }))
}

##############################
# Grafana EC2
##############################
variable "grafana_ami_id" {
  type = string
}

variable "grafana_instance_type" {
  type = string
}

variable "user_data"{}
*/

##############################
# IAM for Grafana ECS
##############################
variable "execution_role_name" {}
variable "execution_assume_policy" {}
variable "execution_managed_policies" {}
variable "execution_inline_policies" {}

variable "task_role_name" {}
variable "task_assume_policy" {}
variable "task_managed_policies" {}
variable "task_inline_policies" {}

##############################
# Grafana ECS
##############################
variable "lb_container_name" {}
variable "lb_container_port" {}
variable "grafana_image" {}
variable "ecs_cpu" {}
variable "ecs_memory" {}
variable "ecs_desired_count" {}
