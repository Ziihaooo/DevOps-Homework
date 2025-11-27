#!/bin/bash
set -xeuo pipefail
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Starting Deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "PROJECT_NAME: $PROJECT_NAME"
echo "DOCKER_USERZ: $DOCKER_USERZ"
echo "DOCKER_REPO:  $DOCKER_REPO"
echo "APP_TAG:      $APP_TAG"
echo "S3_BUCKET:    $S3_BUCKET"
echo "AWS_REGION:   $AWS_REGION"

echo "Updating system and installing dependencies"
sudo yum update -y || true
sudo yum install -y docker make awscli jq
sudo systemctl enable docker
sudo systemctl start docker
echo "System update and dependency installation done"

echo "create directory"
sudo mkdir -p /opt/$PROJECT_NAME
echo "create directory done"

echo "create env file"
cat <<EOF | sudo tee /opt/$PROJECT_NAME/.env
PROJECT_NAME=$PROJECT_NAME
DOCKER_USERZ=$DOCKER_USERZ
DOCKER_REPO=$DOCKER_REPO
APP_TAG=$APP_TAG
S3_BUCKET=$S3_BUCKET
AWS_REGION=$AWS_REGION
EOF
echo "create env file done"
# fetch artifacts
echo "fetch artifacts"
aws s3 cp s3://$S3_BUCKET/deploy/docker-compose /usr/local/bin/docker-compose --region $AWS_REGION
sudo chmod +x /usr/local/bin/docker-compose
echo "fetch artifacts done"

echo "Downloading deployment files from S3"
aws s3 cp s3://$S3_BUCKET/deploy/docker-compose.yml /opt/$PROJECT_NAME/docker-compose.yml --region $AWS_REGION
aws s3 cp s3://$S3_BUCKET/deploy/Makefile /opt/$PROJECT_NAME/Makefile --region $AWS_REGION
echo "Download complete"
# start app
echo "Starting application using Makefile"
cd /opt/$PROJECT_NAME
sudo make up
echo "Application started successfully!"