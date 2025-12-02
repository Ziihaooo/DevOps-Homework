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
  assume_role_policy      = var.execution_assume_policy
  managed_policy_arns     = var.execution_managed_policies
  inline_policies         = var.execution_inline_policies
  create_instance_profile = false
}

module "iam_ecs_task" {
  source                  = "../../modules/iam"
  role_name               = var.task_role_name
  assume_role_policy      = var.task_assume_policy
  managed_policy_arns     = var.task_managed_policies
  inline_policies         = var.task_inline_policies
  create_instance_profile = false
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
  health_check_path = "/"

  attach_target = false

  tags = var.alb_tags
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

  private_subnets = var.private_subnet_ids
  service_sg      = module.sg_ecs.sg_id
  desired_count   = var.ecs_desired_count

  # your containers (nginx + app)
  containers = var.containers

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

