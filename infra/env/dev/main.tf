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

#########################################
# SECURITY GROUPS
#########################################

# ALB SG
module "sg_alb" {
  source      = "../../modules/sg"
  description = "ALB Security Group"
  name        = "${var.env_name}-alb-sg"
  vpc_id      = var.vpc_id
  ingress     = var.alb_sg_ingress
  egress      = var.alb_sg_egress
}

# Fargate Service SG
module "sg_ecs" {
  source      = "../../modules/sg"
  description = "ECS Service Security Group"
  name        = "${var.env_name}-ecs-sg"
  vpc_id      = var.vpc_id

  ingress = var.ecs_sg_ingress
  egress  = var.ecs_sg_egress

  allow_sg_ingress = [
    {
      from_port = 80
      to_port   = 80
      protocol  = "tcp"
      source_sg = module.sg_alb.sg_id
    }
  ]
}

#########################################
# IAM (Execution + Task Roles)
#########################################

module "iam_ecs_execution" {
  source                  = "../../modules/iam"
  role_name               = var.execution_role_name
  assume_role_policy      = jsonencode(var.execution_assume_policy)
  managed_policy_arns     = var.execution_managed_policies
  inline_policies         = var.execution_inline_policies
  create_instance_profile = false
}

module "iam_ecs_task" {
  source                  = "../../modules/iam"
  role_name               = var.task_role_name
  assume_role_policy      = jsonencode(var.task_assume_policy)
  managed_policy_arns     = var.task_managed_policies
  inline_policies         = var.task_inline_policies
  create_instance_profile = false
}
#########################################
# NAT and PRIVATE ROUTE
#########################################
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
# ALB
#########################################

module "alb" {
  source = "../../modules/alb"

  name              = var.alb_name
  vpc_id            = var.vpc_id
  public_subnet_ids = var.public_subnet_ids
  alb_sg_id         = module.sg_alb.sg_id

  listener_port     = var.alb_listener_port
  listener_protocol = var.alb_listener_protocol

  target_port       = 80
  target_protocol   = "HTTP"
  health_check_path = "/health"

  attach_target = false

  tags = var.alb_tags
}
#########################################
# Cloud Watch
#########################################
module "nginx_log" {
  source = "../../modules/cloudwatch_log"

  name = "/ecs/${var.project_name}-nginx"
  retention_in_days = 7
}
module "app_log" {
  source = "../../modules/cloudwatch_log"

  name = "/ecs/${var.project_name}-app"
  retention_in_days = 7
}
#########################################
# ECS (Cluster + TaskDefinition + Service)
#########################################

module "ecs" {
  #some hardcode must like awsvpc FARGATE is in the module
  source = "../../modules/ecs"

  project_name = var.project_name

  cpu    = var.ecs_cpu
  memory = var.ecs_memory

  execution_role_arn = module.iam_ecs_execution.role_arn
  task_role_arn      = module.iam_ecs_task.role_arn

  private_subnets = [var.private_subnet_ids[0]]
  service_sg      = module.sg_ecs.sg_id
  desired_count   = var.ecs_desired_count

  # your containers (nginx + app)
  #because it needs to use the module from cloudwatch
  containers = local.containers

  # ALB pointing only to nginx container
  load_balancers = [
    {
      target_group_arn = module.alb.target_group_arn
      container_name   = var.lb_container_name
      container_port   = var.lb_container_port
    }
  ]

  depends_on = [module.alb.alb_listener_arn]
}

  # your containers (nginx + app)
locals {
  containers = [
    {
      name  = "nginx"
      image = "zavierrr/orchestration-week8-nginx:b100c8f"
      essential = true

      portMappings = [{
        containerPort = 80
        hostPort      = 80
      }]
      environment = []
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = module.nginx_log.log_group_name
          awslogs-region        = "ap-southeast-2"
          awslogs-stream-prefix = "nginx"
        }
      }
    },

    {
      name  = "app"
      image = "zavierrr/orchestration-week8-app:b100c8f"
      essential = true

      portMappings = [{
        containerPort = 8080
        hostPort      = 8080
      }]

      environment = [
        { name = "ASPNETCORE_ENVIRONMENT", value = "Production" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = module.app_log.log_group_name
          awslogs-region        = "ap-southeast-2"
          awslogs-stream-prefix = "app"
        }
      }
    }
  ]
}

