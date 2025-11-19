#------ public_subnet --------
#for nat gateway
variable "public_subnet_id" {
  description = "the id of the public subnet"
  type        = string
  default     = "subnet-0a05dfbfa9b02eb45"
}

#------ public_subnet --------

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
#------ Route Tables -----
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

#IAMROLE SSM
variable "SSM_role" {
  description = "role for ssm connect"
  type        = string
  default     = "UAT-SSM-ReadOnlyS3"

}