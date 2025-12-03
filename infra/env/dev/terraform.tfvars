#############################################
# ENV + PROJECT
#############################################

env_name     = "dev"
nat_name     = "nat-zihao"
project_name = "week8-app"

#############################################
# VPC + SUBNETS
#############################################

vpc_id = "vpc-0a775837570253930"

public_subnet_ids  = ["subnet-0a05dfbfa9b02eb45", "subnet-044bb7e2c10d0b1ee"]
private_subnet_ids = ["subnet-089bf9a6ed97aad05", "subnet-0cdfed7a146ee743c"]

#############################################
# SECURITY GROUP RULES
#############################################

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

# ECS Service SG (only allow traffic from ALB)
ecs_sg_ingress = [
  # (extra rules if needed)
]

ecs_sg_egress = [
  {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
]

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
task_inline_policies  = []

#############################################
# ALB CONFIG
#############################################

alb_name              = "week8-alb"
alb_listener_port     = 80
alb_listener_protocol = "HTTP"
alb_tags = {
  Project = "week8"
}

#############################################
# ECS CONFIG
#############################################

ecs_cpu           = 512
ecs_memory        = 1024
ecs_desired_count = 1

#############################################
# Multi-Container Setup (STATIC + APP)
#############################################

containers = [
  # Container 1 — Nginx static page (HTML/Images)
  {
    name = "nginx"
    #pls update the image if needed
    image = "zavierrr/orchestration-week8-nginx:b100c8f"
    portMappings = [
      {
        containerPort = 80
        hostPort      = 80
      }
    ]

    essential   = true
    environment = []
  },

  # Container 2 — Feature App (.NET app or Node app)
  {
    name  = "app"
    image = "zavierrr/orchestration-week8-app:b100c8f"
    portMappings = [
      {
        containerPort = 8080
        hostPort      = 8080
      }
    ]
    essential = true

    environment = [
      { name = "ASPNETCORE_ENVIRONMENT", value = "Production" }
    ]
  }
]

#############################################
# ALB → send traffic only to nginx container
#############################################

lb_container_name = "nginx"
lb_container_port = 80
