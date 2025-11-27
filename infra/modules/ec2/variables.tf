variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
  default = "t3.micro"
}

variable "subnet_id" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
  description = "List of SGs attached to EC2"
}

variable "instance_profile_name" {
  type = string
  description = "IAM Instance Profile name"
}

variable "user_data" {
  type = string
  default = ""
}

variable "name" {
  type = string
}

variable "tags" {
  type = map(string)
  default = {}
}

variable "enable_alb_sg_rule" {
  type    = bool
  default = false
}

variable "app_port" {
  type    = number
  default = 3000
}

variable "ec2_sg_id" {
  type = string
}

variable "alb_sg_id" {
  type = string
}
