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
