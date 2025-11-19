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

#OIDC
#the url need to change
resource "aws_iam_openid_connect_provider" "bitbucket" {
  url = "https://api.bitbucket.org/2.0/workspaces/distinctioncoding/pipelines-config/identity/oidc"

  client_id_list = [
    "ari:cloud:bitbucket::workspace/4819ba2a-d033-41a1-87c5-3988f84c0b16"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

resource "aws_iam_role" "pipeline_oidc_role" {
  name = "PipelineOIDCRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.bitbucket.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          ForAnyValue:StringEquals = {
            "api.bitbucket.org/2.0/workspaces/distinctioncoding/pipelines-config/identity/oidc:aud" = [
              "ari:cloud:bitbucket::workspace/4819ba2a-d033-41a1-87c5-3988f84c0b16"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "pipeline_s3_access" {
  name = "PipelineOIDCS3Access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.app_artifacts.arn}/oidc-test/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.app_artifacts.arn
        Condition = {
          StringLike = {
            "s3:prefix" = "oidc-test/*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "pipeline_attach_s3" { 
  role       = aws_iam_role.pipeline_oidc_role.name 
  policy_arn = aws_iam_policy.pipeline_s3_access.arn 
}
