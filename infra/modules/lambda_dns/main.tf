resource "aws_iam_role" "lambda_role" {
  name = "${var.name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Basic Lambda Logging
resource "aws_iam_role_policy_attachment" "basic_logging" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Allow Lambda to use Route 53
resource "aws_iam_role_policy" "route53_access" {
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListHostedZonesByName"
        ]
        Resource = "*"
      }
    ]
  })
}

# The Lambda function itself
resource "aws_lambda_function" "dns_lambda" {
  function_name = var.name
  role          = aws_iam_role.lambda_role.arn
  handler       = "main.lambda_handler"
  runtime       = "python3.11"

  filename         = var.lambda_zip_path
  source_code_hash = filebase64sha256(var.lambda_zip_path)

  environment {
    variables = {
      HOSTED_ZONE_ID = var.hosted_zone_id
      ROOT_DOMAIN     = var.root_domain
    }
  }
}

# SQS → Lambda Trigger
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn  = var.sqs_queue_arn
  function_name     = aws_lambda_function.dns_lambda.arn
  batch_size        = 5
  enabled           = true
}

output "lambda_arn" {
  value = aws_lambda_function.dns_lambda.arn
}

output "lambda_name" {
  value = aws_lambda_function.dns_lambda.function_name
}
