#!/bin/bash
set -e

sudo yum update -y || true
sudo yum install -y docker make awscli
sudo systemctl enable docker
sudo systemctl start docker

aws s3 cp s3://$S3_BUCKET/deploy/docker-compose /usr/local/bin/docker-compose --region $AWS_REGION
sudo chmod +x /usr/local/bin/docker-compose

sudo mkdir -p /opt/$PROJECT_NAME
aws s3 cp s3://$S3_BUCKET/deploy/docker-compose.yml /opt/$PROJECT_NAME/docker-compose.yml --region $AWS_REGION
aws s3 cp s3://$S3_BUCKET/deploy/Makefile /opt/$PROJECT_NAME/Makefile --region $AWS_REGION

echo PROJECT_NAME=$PROJECT_NAME | sudo tee /opt/$PROJECT_NAME/.env
echo DOCKER_USERZ=$DOCKER_USERZ | sudo tee -a /opt/$PROJECT_NAME/.env
echo DOCKER_REPO=$DOCKER_REPO | sudo tee -a /opt/$PROJECT_NAME/.env
echo APP_TAG=$APP_TAG | sudo tee -a /opt/$PROJECT_NAME/.env

cd /opt/$PROJECT_NAME && sudo make up
