#!/bin/bash
set -euo pipefail

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Starting Deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "PROJECT_NAME: $PROJECT_NAME"
echo "DOCKER_USERZ: $DOCKER_USERZ"
echo "DOCKER_REPO:  $DOCKER_REPO"
echo "APP_TAG:      $APP_TAG"
echo "S3_BUCKET:    $S3_BUCKET"
echo "AWS_REGION:   $AWS_REGION"

sudo yum update -y || true
sudo yum install -y docker make awscli jq
sudo systemctl enable docker
sudo systemctl start docker

sudo mkdir -p /opt/$PROJECT_NAME

# fetch artifacts
aws s3 cp s3://$S3_BUCKET/deploy/docker-compose /usr/local/bin/docker-compose --region $AWS_REGION
sudo chmod +x /usr/local/bin/docker-compose

aws s3 cp s3://$S3_BUCKET/deploy/docker-compose.yml /opt/$PROJECT_NAME/docker-compose.yml --region $AWS_REGION
aws s3 cp s3://$S3_BUCKET/deploy/Makefile /opt/$PROJECT_NAME/Makefile --region $AWS_REGION

# start app
cd /opt/$PROJECT_NAME
sudo make up
