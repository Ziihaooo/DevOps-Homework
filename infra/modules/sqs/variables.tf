variable "name" {
  description = "Base name for the SQS queue and DLQ"
  type        = string
}

variable "visibility_timeout_seconds" {
  description = "How long a message is hidden after being received"
  type        = number
  default     = 30
}

variable "message_retention_seconds" {
  description = "How long SQS keeps messages"
  type        = number
  default     = 86400
}

variable "receive_wait_time_seconds" {
  description = "Polling wait time"
  type        = number
  default     = 5
}

variable "dlq_max_receive_count" {
  description = "Number of receives before message goes to DLQ"
  type        = number
  default     = 5
}
variable "lambda_role_arn" {
  type        = string
  description = "IAM role ARN of Lambda function allowed to read from SQS"
}
