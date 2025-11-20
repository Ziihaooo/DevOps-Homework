#for the bucket that need to save the tfstate need to be manually create
#as well as the dynamodb table for locking
#the S3 bucket for uploading can be created by terraform
resource "aws_s3_bucket" "app_artifacts" {
  bucket        = "zihao-app-artifacts"
  force_destroy = true # allows terraform destroy without errors

  tags = {
    Name    = "zihao-app-artifacts"
    Project = "DevOps"
    Owner   = "ZiHao"
  }
}

resource "aws_s3_bucket_public_access_block" "app_artifacts" {
  bucket = aws_s3_bucket.app_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
