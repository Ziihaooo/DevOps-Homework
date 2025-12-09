terraform {
  backend "s3" {
    bucket         = "terraforms3-zihao"
    key            = "dev/week8/terraform/zihao/terraform.tfstate"
    region         = "ap-southeast-2"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

#for route53 cloddwatch log
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

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

############################################
# 6. Security Group 
############################################

# ALB SG
module "sg_alb" {
  source      = "../../modules/sg"
  description = "ALB Security Group"
  name        = "${var.env_name}-alb-sg"
  vpc_id      = var.vpc_id
  ingress     = var.alb_sg_ingress
  egress      = var.alb_sg_egress
}

# GRAFANA Service SG
module "sg_grafana" {
  source      = "../../modules/sg"
  description = "ECS Service Security Group"
  name        = "${var.env_name}-ecs-sg"
  vpc_id      = var.vpc_id

  ingress = var.grafana_sg_ingress
  egress  = var.grafana_sg_egress

  allow_sg_ingress = [
    {
      from_port = 3000
      to_port   = 3000
      protocol  = "tcp"
      source_sg = module.sg_alb.sg_id
    }
  ]
}

############################################
# 7. NAT and PRIVATE ROUTE
############################################
module "nat" {
  source           = "../../modules/nat"
  name             = var.nat_name
  public_subnet_id = var.public_subnet_ids[0]
}

module "private_routes" {
  source            = "../../modules/routetables"
  name              = var.env_name
  vpc_id            = var.vpc_id
  private_subnet_id = var.private_subnet_ids[0]
  nat_gateway_id    = module.nat.nat_gateway_id
}
#########################################
# 8. ALB
#########################################

module "alb" {
  source = "../../modules/alb"

  name              = var.alb_name
  vpc_id            = var.vpc_id
  public_subnet_ids = var.public_subnet_ids
  alb_sg_id         = module.sg_alb.sg_id

  listener_port     = var.alb_listener_port
  listener_protocol = var.alb_listener_protocol

  target_port       = var.target_port
  target_protocol   = var.target_protocol
  health_check_path = var.health_check_path

  attach_target = false

  tags = var.alb_tags
}
###############################################
# 9. CloudWatch Log Group for Route53 Query Logs
###############################################
module "route53_cloudwatch" {
  source = "../../modules/cloudwatch_log"

  providers = {
    aws = aws.us_east_1
  }

  name              = var.cloudwatchname
  retention_in_days = var.retention_in_days
}



module "grafana_log_group" {
  source = "../../modules/cloudwatch_log"

  name              = var.grafanacw
  retention_in_days = var.grafana_retention_in_days
}
###############################################
# 9.1 CloudWatch Resource Policy for Route53
###############################################

data "aws_caller_identity" "current" {}

locals {
  log_group_arn_prefix = "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group"
}

resource "aws_cloudwatch_log_resource_policy" "route53" {
  provider = aws.us_east_1
  policy_name = "route53-query-logs-policy"

  policy_document = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Route53QueryLogs",
      "Effect": "Allow",
      "Principal": {
        "Service": "route53.amazonaws.com"
      },
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "${local.log_group_arn_prefix}:${module.route53_cloudwatch.log_group_name}:*"
    }
  ]
}
EOF
}

/*
###############################################
# 10. IAM role Grafana 
###############################################
module "grafana_iam" {
  source = "../../modules/iam"

  role_name            = var.grafana_role_name
  assume_role_policy   = jsonencode(var.grafana_assume_role_policy)
  managed_policy_arns  = var.grafana_managed_policies
  inline_policies      = [
    for p in var.grafana_inline_policies : {
      name   = p.name
      policy = jsonencode(p.policy)
    }
  ]

  create_instance_profile = true
}

###############################################
# 10. GRAFANA EC2
###############################################

module "grafana_ec2" {
  source = "../../modules/ec2"

  ami_id            = var.grafana_ami_id
  instance_type     = var.grafana_instance_type
  subnet_id         = var.private_subnet_ids[0]
  security_group_ids = [module.sg_grafana.sg_id]

  instance_profile_name = module.grafana_iam.instance_profile_name

  user_data = var.user_data
}
*/

#########################################
# IAM (Execution + Task Roles)
#########################################

module "iam_ecs_execution" {
  source              = "../../modules/iam"
  role_name           = var.execution_role_name
  assume_role_policy  = jsonencode(var.execution_assume_policy)
  managed_policy_arns = var.execution_managed_policies
  inline_policies = [
    for p in var.execution_inline_policies : {
      name   = p.name
      policy = jsonencode(p.policy)
    }
  ]
  create_instance_profile = false
}

module "iam_ecs_task" {
  source              = "../../modules/iam"
  role_name           = var.task_role_name
  assume_role_policy  = jsonencode(var.task_assume_policy)
  managed_policy_arns = var.task_managed_policies
  inline_policies = [
    for p in var.task_inline_policies : {
      name   = p.name
      policy = jsonencode(p.policy)
    }
  ]
  create_instance_profile = false
}
############################################
# ECS for Grafana
############################################

module "ecs_grafana" {
  source = "../../modules/ecs"

  project_name = "${var.project_name}-grafana"

  cpu    = var.ecs_cpu
  memory = var.ecs_memory

  execution_role_arn = module.iam_ecs_execution.role_arn
  task_role_arn      = module.iam_ecs_task.role_arn

  private_subnets = [var.private_subnet_ids[0]]

  # Security Group for ECS task
  service_sg = module.sg_grafana.sg_id

  desired_count = var.ecs_desired_count

  # Only one container
  containers = local.grafana_container

  load_balancers = [{
    target_group_arn = module.alb.target_group_arn
    container_name   = var.lb_container_name
    container_port   = var.lb_container_port
  }]

  depends_on = [
    module.sg_grafana,
    module.route53_cloudwatch
  ]
}


locals {
  grafana_container = [
    {
      name      = "grafana"
      image     = var.grafana_image
      essential = true

      portMappings = [{
        containerPort = 3000
        hostPort      = 3000
        protocol      = "tcp"
      }]

      environment = [
        { name = "GF_SECURITY_ADMIN_USER", value = "admin" },
        { name = "GF_SECURITY_ADMIN_PASSWORD", value = "admin" },
        { name = "AWS_REGION", value = "ap-southeast-2" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = module.grafana_log_group.log_group_name
          awslogs-region        = "ap-southeast-2"
          awslogs-stream-prefix = "grafana"
        }
      }
    }
  ]
}

resource "aws_route53_query_log" "route53_logs" {
  zone_id                  = aws_route53_zone.client_dns_zone.zone_id
  cloudwatch_log_group_arn = module.route53_cloudwatch.arn

  depends_on = [
    aws_cloudwatch_log_resource_policy.route53
  ]
}
