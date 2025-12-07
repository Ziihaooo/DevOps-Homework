############################
# SQS Configuration
############################
sqs_name                    = "client-domain-requests"
#these value recommended by AI
visibility_timeout_seconds  = 30
message_retention_seconds   = 86400
receive_wait_time_seconds   = 5
dlq_max_receive_count       = 5

############################
# Route 53
############################
#use .internal for fake DNS 
base_domain = "zavier.devops.internal"  

############################
# IAM + Lambda
############################


lambda_role_name = "lambda-dns-role"

lambda_assume_role_policy = {
  Version = "2012-10-17"
  Statement = [
    {
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }
  ]
}

lambda_managed_policies = [
  "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
]

lambda_inline_policies = [
  {
    name = "route53-access"
    policy = {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "route53:ChangeResourceRecordSets",
            "route53:ListResourceRecordSets"
          ]
          #this will be restricted at lambda level which will become just for one specific hosted zone
          Resource = "*"
        }
      ]
    }
  }
]

lambda_name     = "client-domain-dns-function"
lambda_zip_path = "../../lambda/dns_handler.zip"
lambda_timeout  = 30

