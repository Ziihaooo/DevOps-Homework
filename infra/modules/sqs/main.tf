resource "aws_sqs_queue" "queue" {
  name                      = "${var.name}-queue"
  message_retention_seconds = 86400
  visibility_timeout_seconds = 30
  receive_wait_time_seconds = 5

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue" "dlq" {
  name = "${var.name}-dlq"
}

output "queue_url" {
  value = aws_sqs_queue.queue.url
}

output "queue_arn" {
  value = aws_sqs_queue.queue.arn
}

output "dlq_arn" {
  value = aws_sqs_queue.dlq.arn
}
