#------ NAT --------
#for nat gateway
variable "public_subnet_id"{
    description = "the id of the public subnet"
    type = string
    default = "subnet-0a05dfbfa9b02eb45"
}

#------ NAT --------

#------ Route Tables -----
variable "private_route_table_id"{
    description = "the id of the private route table"
    type = string
    default = "rtb-0f423cee4892a02e1"
}
#------ Route Tables -----


#using variables for decoupling 
variable "ami_id"{
    description = "AMAZON MACHINE IMAGE for ec2"
    type = string
    default = "ami-038013fbee7451346"
}

#default will be the free tier
variable "instance_type"{
    description = "EC2 instance type"
    type = string
    default = "t2.micro"
}

