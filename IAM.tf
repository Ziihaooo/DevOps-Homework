#create the role with aws ec2 service
resource "aws_iam_role" "ssm_role" {
  name = "EC2-SSM-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}
#attach the SSMMANAGED policy to the role created above
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

#need this for later attaching with ec2
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "EC2-SSM-InstanceProfile"
  role = aws_iam_role.ssm_role.name
}
