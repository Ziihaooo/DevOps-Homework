variable "name" {
  type        = string
  description = "Lambda function name"
}

variable "lambda_zip_path" {
  type        = string
  description = "Path to Lambda ZIP package"
}

variable "role_arn" {
  type        = string
  description = "IAM Role ARN for Lambda execution"
}

variable "hosted_zone_id" {
  type        = string
  description = "Route 53 Hosted Zone ID"
}

variable "root_domain" {
  type        = string
  description = "Root domain for DNS provisioning"
}
