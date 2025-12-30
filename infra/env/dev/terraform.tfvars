env_name           = "dev"
project_name       = "Automated_CDS"
vpc_id             = "vpc-0a775837570253930"
public_subnet_ids  = ["subnet-0a05dfbfa9b02eb45", "subnet-044bb7e2c10d0b1ee"]
private_subnet_ids = ["subnet-089bf9a6ed97aad05", "subnet-0cdfed7a146ee743c"]

############################
# SQS Configuration
############################
sqs_name = "client-domain-requests"
#these value recommended by AI
visibility_timeout_seconds = 30
message_retention_seconds  = 86400
receive_wait_time_seconds  = 5
dlq_max_receive_count      = 5

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
          Resource = "*"
        }
      ]
    }
  },
  {
    name = "lambda-cw-putmetric"
    policy = {
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["cloudwatch:PutMetricData"]
          Resource = "*"
        }
      ]
    }
  }
]


lambda_name     = "client-domain-dns-function"
lambda_zip_path = "../../../lambda/dns_handler.zip"
lambda_timeout  = 30

############################
# SG
############################
# ALB Security Group (allow HTTP from internet)
alb_sg_ingress = [
  {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
]

alb_sg_egress = [
  {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
]

# GRAFANA SG (only allow traffic from ALB)
grafana_sg_ingress = [
  # (extra rules if needed)
]

grafana_sg_egress = [
  {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
]
############################
# NAT
############################
nat_name = "zihao_nat_gateway"

#############################################
# ALB CONFIG
#############################################

alb_name              = "week9-alb"
alb_listener_port     = 80
alb_listener_protocol = "HTTP"
alb_tags = {
  Project = "week8"
}
target_port       = "3000"
target_protocol   = "HTTP"
health_check_path = "/api/health"

#############################################
# CLOUDWATCH
#############################################
cloudwatchname    = "/aws/route53/query-logs"
retention_in_days = 30

grafanacw                 = "/aws/ecs/grafana"
grafana_retention_in_days = 30
/*
#############################################
# GRAFANA IAM
#############################################
grafana_role_name = "grafana-ec2-role"

grafana_assume_role_policy = {
  Version = "2012-10-17"
  Statement = [
    {
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }
  ]
}

grafana_managed_policies = []

grafana_inline_policies = [
  {
    name = "grafana-cloudwatch-access"
    policy = {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "cloudwatch:Describe*",
            "cloudwatch:Get*",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
            "logs:GetLogEvents",
            "logs:FilterLogEvents"
          ]
          Resource = "*"
        }
      ]
    }
  }
]
/*
#############################################
# GRAFANA EC2
#############################################
grafana_ami_id       = "ami-0b3c832b6b7289e44"
grafana_instance_type = "t2.micro"
user_data = userdata = <<EOF
#!/bin/bash
set -e

# Install wget
dnf install -y wget

# Add Grafana repo
tee /etc/yum.repos.d/grafana.repo <<REPO
[grafana]
name=Grafana OSS
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
REPO

# Install Grafana
dnf install -y grafana

# Start Grafana
systemctl enable grafana-server
systemctl start grafana-server
EOF
*/

#need to put in
#############################################
# IAM — Execution Role (pull image + logs)
#############################################

execution_role_name = "ecs-execution-role"

execution_assume_policy = {
  Version = "2012-10-17"
  Statement = [
    {
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }
  ]
}

#this include the policy that Fargate needed by AWS 
#pull image + logs
execution_managed_policies = [
  "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
]

execution_inline_policies = []


#############################################
# IAM — Task Role (app permissions)
#############################################
#this is for task if task need to do something that needed permission you added in here
task_role_name = "ecs-task-role"

task_assume_policy = ({
  Version = "2012-10-17"
  Statement = [
    {
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }
  ]
})

task_managed_policies = []
task_inline_policies = [
  {
    name = "grafana-cloudwatch-read"
    policy = {
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "cloudwatch:ListMetrics",
            "cloudwatch:GetMetricData",
            "cloudwatch:DescribeAlarms",
            "cloudwatch:DescribeAlarmHistory",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
            "logs:GetLogEvents",
            "logs:FilterLogEvents",
            "logs:StartQuery",
            "logs:GetQueryResults"
          ]
          Resource = "*"
        }
      ]
    }
  }
]


#############################################
# Grafana ECS
#############################################
lb_container_name = "grafana"
lb_container_port = 3000
grafana_image     = "zavierrr/grafana-week9:4275cef"
ecs_cpu           = 256
ecs_memory        = 512
ecs_desired_count = 1
