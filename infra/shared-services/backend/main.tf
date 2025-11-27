terraform {
  backend "s3" {
    bucket         = "terraforms3-zihao"
    key            = "backend/terraform.tfstate"
    region         = "ap-southeast-2"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
}

provider "aws" {
  region = "ap-southeast-2"
}
