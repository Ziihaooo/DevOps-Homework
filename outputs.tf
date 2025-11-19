output "ec2_id" {
  value = aws_instance.terraform_ec2.id
}
output "ec2_private_ip" {
  value = aws_instance.terraform_ec2.private_ip
}
output "instance_profile" {
  value = aws_iam_instance_profile.ssm_profile.name
}
output "nat_gateway_id" {
  value = aws_nat_gateway.NAT_gateway.id
}
output "private_route_table_id" {
  value = aws_route_table.private_rt.id
}
