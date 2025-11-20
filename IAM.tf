# ========= EC2 SSM ROLE =========
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

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "EC2-SSM-InstanceProfile"
  role = aws_iam_role.ssm_role.name
}

# ========= BITBUCKET OIDC PROVIDER =========
data "aws_iam_openid_connect_provider" "bitbucket" {
  url = "https://api.bitbucket.org/2.0/workspaces/distinctioncoding/pipelines-config/identity/oidc"
}

# ========= PIPELINE ROLE =========
resource "aws_iam_role" "pipeline_oidc_role" {
  name = "PipelineOIDCRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.bitbucket.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          "ForAnyValue:StringEquals" = {
            "api.bitbucket.org/2.0/workspaces/distinctioncoding/pipelines-config/identity/oidc:aud" = [
              "ari:cloud:bitbucket::workspace/4819ba2a-d033-41a1-87c5-3988f84c0b16"
            ]
          }
        }
      }
    ]
  })
}

# ========= PIPELINE POLICY (WRITE TO oidc-test + READ deploy/outputs.json) =========
# ========= PIPELINE POLICY (FULL ACCESS TO deploy/* AND oidc-test/*) =========
resource "aws_iam_policy" "pipeline_s3_access" {
  name = "PipelineOIDCS3Access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      # --- 1. OIDC test folder (READ + WRITE) ---
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
      },

      # --- 2. deploy folder (READ + WRITE) ---
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.app_artifacts.arn}/deploy/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.app_artifacts.arn
        Condition = {
          StringLike = {
            "s3:prefix" = "deploy/*"
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
