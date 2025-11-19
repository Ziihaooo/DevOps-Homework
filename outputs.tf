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
output "artifact_bucket_name" {
  value = aws_s3_bucket.app_artifacts.bucket
}

output "artifact_bucket_arn" {
  value = aws_s3_bucket.app_artifacts.arn
}

output "alb_arn" {
  value = aws_lb.app_alb.arn
}

output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}

output "alb_zone_id" {
  value = aws_lb.app_alb.zone_id
}

output "alb_target_group_arn" {
  value = aws_lb_target_group.app_tg.arn
}

output "alb_listener_arn" {
  value = aws_lb_listener.http.arn
}