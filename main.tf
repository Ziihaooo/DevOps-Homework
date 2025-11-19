terraform {
  backend "s3" {
    bucket = "terraforms3-zihao"
    key    = "dev/terraform/zihao/terraform.tfstate"
    region = "ap-southeast-2"
    #encrypt the data in tfstate file
    encrypt= "true"
    #make lock to prevent concurrent apply with using LockID
    dynamodb_table ="terraform-lock-table"
  }
}

# using aws service 
provider "aws"{
    region = "ap-southeast-2"
}

resource "aws_instance" "terraform_ec2" {
  ami           = "var.ami_id"
  instance_type = "var.instance_type"

  tags = {
    Name = "Terraform Trial EC2"
    Env = "uat"
  }
}

resource "aws_vpc" "sample-vpc"{

}