terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  region = "ap-southeast-2"
}

module "sg_test" {
 #the path to the module
  source = "./modules/sg"
  name        = "sg-test"
  description = "testing module"
  #vpc is created by teacher so we just hard code it here with using variable
  vpc_id      = var.vpc_id

  ingress = [{
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }]

  egress = [{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }]
}

module "nat" {
  source = "./modules/nat"

  name             = "dev"
  vpc_id           = var.vpc_id
  public_subnet_id = var.public_subnet_id
}

module "private_routes" {
  source =  "./modules/routetables"

  name              = "dev"
  vpc_id            = var.vpc_id
  private_subnet_id = var.private_subnet_id
  nat_gateway_id    = module.nat.nat_gateway_id
}

module "iam_ec2" {
  source = "../../modules/iam"

  role_name           = "EC2-SSM-Role"
  create_instance_profile = true

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]

  inline_policies = [
    {
      name = "EC2-S3-Read"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect   = "Allow"
            Action   = ["s3:ListBucket"]
            Resource = module.s3.bucket_arn
          },
          {
            Effect   = "Allow"
            Action   = ["s3:GetObject"]
            Resource = "${module.s3.bucket_arn}/*"
          }
        ]
      })
    }
  ]
}

module "iam_pipeline" {
  source = "../../modules/iam"

  role_name               = "PipelineOIDCRole"
  create_instance_profile = false

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.bitbucket.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        "ForAnyValue:StringEquals" = {
          "api.bitbucket.org/2.0/workspaces/distinctioncoding/pipelines-config/identity/oidc:aud" = [
            "ari:cloud:bitbucket::workspace/4819ba2a-d033-41a1-87c5-3988f84c0b16"
          ]
        }
      }
    }]
  })

  inline_policies = [{
    name = "pipeline-access",
    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        # ========== S3 ==========
        {
          Effect = "Allow"
          Action = ["s3:PutObject", "s3:GetObject"]
          Resource = "${module.s3.bucket_arn}/deploy/*"
        },
        {
          Effect = "Allow"
          Action = ["s3:ListBucket"]
          Resource = module.s3.bucket_arn
          Condition = { StringLike = { "s3:prefix" = "deploy/*" } }
        },

        # ========== SSM ==========
        {
          Effect = "Allow"
          Action = ["ssm:SendCommand"]
          Resource = [
            "arn:aws:ssm:ap-southeast-2::document/AWS-RunShellScript",
            "arn:aws:ec2:ap-southeast-2:${data.aws_caller_identity.current.account_id}:instance/*"
          ]
        }
      ]
    })
  }]
}
