#!/bin/bash
set -euo pipefail

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Starting Deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"

#!/bin/bash
set -euo pipefail

PROJECT_NAME=$1
DOCKER_USERZ=$2
DOCKER_REPO=$3
APP_TAG=$4
S3_BUCKET=$5
AWS_REGION=$6

export PROJECT_NAME
export DOCKER_USERZ
export DOCKER_REPO
export APP_TAG
export S3_BUCKET
export AWS_REGION


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
