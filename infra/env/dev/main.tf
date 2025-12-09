####################################
# 1. SQS Queue Module
####################################
module "client_domain_sqs" {
  source = "../../modules/sqs"

  name                       = var.sqs_name
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds
  dlq_max_receive_count      = var.dlq_max_receive_count
  lambda_role_arn            = module.lambda_dns_iam.role_arn

}

####################################
# 2. Route53 Hosted Zone
####################################
resource "aws_route53_zone" "client_dns_zone" {
  name = var.base_domain
}
####################################
# 3. IAM Role for Lambda (Module)
####################################
module "lambda_dns_iam" {
  source = "../../modules/iam"

  role_name          = var.lambda_role_name
  assume_role_policy = jsonencode(var.lambda_assume_role_policy)

  managed_policy_arns = var.lambda_managed_policies

  inline_policies = [
    for p in var.lambda_inline_policies : {
      name   = p.name
      policy = jsonencode(p.policy)
    }
  ]

  create_instance_profile = false
}

####################################
# 4. Lambda Function Module
####################################
module "lambda_dns" {
  source = "../../modules/lambda_dns"

  lambda_name     = var.lambda_name
  role_arn        = module.lambda_dns_iam.role_arn
  lambda_zip_path = var.lambda_zip_path
  hosted_zone_id  = aws_route53_zone.client_dns_zone.id
  base_domain     = var.base_domain
  lambda_timeout  = var.lambda_timeout
}


####################################
# 5. Event Source Mapping (SQS → Lambda)
####################################
resource "aws_lambda_event_source_mapping" "dns_trigger" {
  event_source_arn = module.client_domain_sqs.queue_arn
  function_name    = module.lambda_dns.lambda_arn
  batch_size       = 1
  enabled          = true
}
