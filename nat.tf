# order not important, terraform will resolves the correct order

#nat gateway resource
resource "aws_nat_gateway" "NAT_gateway"{
    #allocation id should created by terraform
    allocation_id = aws_eip.nat.id
    subnet_id     = var.public_subnet_id
    
    tags = {
        Name = "Nat_gateway"
    }
}

#create a new Elastic IP for NAT which is safer because it is tracked in the tfstate
resource "aws_eip" "nat" {
#this elastic IP belongs to a VPC
#this EIP can be used for nat gateway or EC2 in a vpc
  vpc = true

  tags = {
    Name = "Nat_eip"
  }
}
