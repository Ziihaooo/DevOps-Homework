#the vpc that this private route table will be 
resource "aws_route_table" "private_rt" {
  vpc_id = var.vpc_id

  tags = {
    Name = "private-route-table"
  }
}
#modify the route of the private route table 
#adding 0.0.0.0/0 NAT_gateway for ec2 in private subnet to connect to internet
#add a route to this route table
resource "aws_route" "private_nat_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.NAT_gateway.id
}

#this route need to be associated in the private subnet
#attach this route to this subnet
resource "aws_route_table_association" "private_assoc" {
  subnet_id      = var.private_subnet_id
  route_table_id = aws_route_table.private_rt.id
}
