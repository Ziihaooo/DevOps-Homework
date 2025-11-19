terraform {
  backend "s3" {
    bucket = "terraforms3-zihao"
    key    = "dev/terraform/zihao/terraform.tfstate"
    region = "ap-southeast-2"
    #encrypt the data in tfstate file
    encrypt = "true"
    #make lock to prevent concurrent apply with using LockID
    dynamodb_table = "terraform-lock-table"
  }
}

# using aws service 
provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_instance" "terraform_ec2" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.private_subnet_id
  #no public access no key pair
  associate_public_ip_address = false
  vpc_security_group_ids = [
    aws_security_group.private_sg.id
  ]
  #can only have instance profile cannot use role directly
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name
  user_data            = <<-EOF
    #!/bin/bash
    # Enable and start SSM agent (Amazon Linux 2/2023)
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
    systemctl restart amazon-ssm-agent
  EOF 
  tags = {
    Name = "Terraform Trial EC2"
    Env  = "uat"
  }
}

resource "aws_security_group" "private_sg" {
  name        = "private-ec2-sg"
  description = "Security group for private EC2 (SSM only)"
  #chatgpt said SG is a vpc based resource so need to assign it to a vpc
  vpc_id = var.vpc_id

  # No Inbound Rules (SSM does not need inbound)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = []
  }

  # Outbound: Allow EC2 to connect to AWS SSM endpoints
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-ec2-sg"
  }
}