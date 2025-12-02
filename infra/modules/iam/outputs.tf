output "role_name" {
  value = aws_iam_role.this.name
}

#if got instance profile then output if not then null
output "instance_profile_name" {
  value = length(aws_iam_instance_profile.profile) > 0 ? aws_iam_instance_profile.profile[0].name : null
}

output "role_arn" {
  value = aws_iam_role.this.arn
}
