output "lambda_arn" {
  value = aws_lambda_function.dns_lambda.arn
}

output "lambda_name" {
  value = aws_lambda_function.dns_lambda.function_name
}
