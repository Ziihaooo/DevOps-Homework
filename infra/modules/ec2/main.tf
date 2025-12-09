resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id

  associate_public_ip_address = false

  vpc_security_group_ids = var.security_group_ids

  iam_instance_profile = var.instance_profile_name

  user_data = var.user_data

  tags = merge(
    {
      Name = var.name
    },
    var.tags
  )
}

