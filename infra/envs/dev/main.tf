terraform {
  backend "s3" {
    bucket         = "terraforms3-zihao"
    key            = "dev/week7/terraform/zihao/terraform.tfstate"
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

module "sg_private" {
  source      = "../../modules/sg"
  name        = "${var.env_name}-ec2-sg"
  vpc_id      = var.vpc_id
  description = "EC2 Security Group"

  ingress = var.sg_ingress
  egress  = var.sg_egress

  allow_sg_ingress = [
    {
      from_port = 3000
      to_port   = 3000
      protocol  = "tcp"
      source_sg = module.sg_alb.sg_id
    }
  ]
}


#########################################
# NAT & ROUTES
#########################################

module "nat" {
  source           = "../../modules/nat"
  name             = var.nat_name
  public_subnet_id = var.public_subnet_id
}

module "private_routes" {
  source            = "../../modules/routetables"
  name              = var.env_name
  vpc_id            = var.vpc_id
  private_subnet_id = var.private_subnet_id
  nat_gateway_id    = module.nat.nat_gateway_id
}

#########################################
# S3
#########################################

module "app_s3" {
  source      = "../../modules/S3"
  bucket_name = var.s3_bucket_name
  tags        = var.s3_tags
}

#########################################
# IAM ROLES
#########################################

module "iam_ec2" {
  source                  = "../../modules/iam"
  role_name               = var.ec2_role_name
  assume_role_policy      = var.ec2_assume_role_policy
  managed_policy_arns     = var.ec2_managed_policy_arns
  inline_policies         = var.ec2_inline_policies
  create_instance_profile = true
}
#########################################
# EC2 INSTANCE
#########################################

module "ec2" {
  source = "../../modules/ec2"

  ami_id                = var.ami_id
  instance_type         = var.instance_type
  subnet_id             = var.private_subnet_id
  security_group_ids    = [module.sg_private.sg_id]
  instance_profile_name = module.iam_ec2.instance_profile_name

  user_data = <<-EOF
    #!/bin/bash
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
    systemctl restart amazon-ssm-agent
  EOF

  name = "${var.env_name}-ec2-instance"

  tags = {
    Environment = var.env_name
    Project     = "DevOps"
  }

  enable_alb_sg_rule = true
  app_port           = 3000
  ec2_sg_id          = module.sg_private.sg_id
  alb_sg_id          = module.sg_alb.sg_id
}

#########################################
# ALB
#########################################

module "alb" {
  source = "../../modules/alb"

  name              = var.alb_name
  vpc_id            = var.vpc_id
  public_subnet_ids = var.public_subnet_ids

  alb_sg_id = module.sg_alb.sg_id

  listener_port     = var.alb_listener_port
  listener_protocol = var.alb_listener_protocol

  target_port       = 3000
  target_protocol   = "HTTP"
  health_check_path = "/health"

  attach_target = true
  target_id     = module.ec2.instance_id

  tags = var.alb_tags
}
