resource "aws_sqs_queue" "queue" {
  name                       = "${var.name}-queue"
  #how long the message will retent
  #only for the message that havent been processed
  message_retention_seconds  = var.message_retention_seconds
  #the time that hides it when taken by lambda
  visibility_timeout_seconds = var.visibility_timeout_seconds
  #the time duration that lambda ask sqs for message 
  receive_wait_time_seconds  = var.receive_wait_time_seconds

  redrive_policy = jsonencode({
    #the dead letter queue for this queue
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    #the failing time that lambda try
    maxReceiveCount     = var.dlq_max_receive_count
  })
}


resource "aws_sqs_queue" "dlq" {
  name = "${var.name}-dlq"
}
resource "aws_sqs_queue_policy" "lambda_access" {
  queue_url = aws_sqs_queue.queue.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.lambda_role_arn
        }
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.queue.arn
      }
    ]
  })
}

