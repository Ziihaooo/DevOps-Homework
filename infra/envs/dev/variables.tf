variable "public_subnet_id" {
  description = "the id of the public subnet"
  type        = string
  default     = "subnet-0a05dfbfa9b02eb45"
}

#------ public_subnet --------
variable "public_subnet_ids" {
  description = "List of public subnets for ALB (must be across at least 2 AZs)"
  type        = list(string)
}
#------ private subnet -------
variable "private_subnet_id" {
  description = "the id of the private subnet"
  type        = string
  default     = "subnet-089bf9a6ed97aad05"
}
#------ private subnet -------

#------ VPC -----
variable "vpc_id" {
  description = "the id of the sample vpc"
  type        = string
  default     = "vpc-0a775837570253930"
}

variable "aws_region" {}

variable "sg_name" {}
variable "sg_description" {}
variable "sg_ingress" {}
variable "sg_egress" {}
variable "alb_sg_ingress" {}
variable "alb_sg_egress" {}
variable "env_name" {}
variable "s3_bucket_name" {}
variable "s3_tags" {}

variable "ec2_role_name" {}
variable "ec2_assume_role_policy" {}
variable "ec2_managed_policy_arns" {}
variable "ec2_inline_policies" {}

variable "pipeline_role_name" {}
variable "pipeline_assume_role_policy" {}
variable "pipeline_inline_policies" {}

#using variables for decoupling 
variable "ami_id" {
  description = "AMAZON MACHINE IMAGE for ec2"
  type        = string
  default     = "ami-038013fbee7451346"
}

#default will be the free tier
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "alb_name" {}
variable "alb_listener_port" {}
variable "alb_listener_protocol" {}

variable "app_port" {}
variable "target_protocol" {}
variable "health_check_path" {}

variable "attach_target" {
  type = bool
}

variable "alb_tags" {
  type = map(string)
}


variable "nat_name" {}
variable "nat_tags" {
  type = map(string)
}
