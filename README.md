# CodeToCloud – Automated CI/CD with Docker & AWS
## Overview
CodeToCloud showcases a complete DevOps CI/CD workflow that builds, pushes, and deploys Dockerized microservices to AWS EC2 using Bitbucket Pipelines, Docker Hub, and AWS SSM.
It includes a Node.js API behind an Nginx reverse proxy, orchestrated with Docker Compose.

## Project Structure
CODETOCLOUD/
├── app/                    # Node.js backend service
│   ├── server.js
│   ├── package.json
│   └── Dockerfile
│
├── deploy/
│   └── nginx/
│       ├── default.conf
│       └── Dockerfile.nginx
│
├── docker-compose.yml       # Multi-service orchestration
├── Makefile                 # Build / Push / Deploy automation
├── bitbucket-pipelines.yml  # CI/CD pipeline configuration
├── .env.template            # Template for environment variables
└── README.md

## Deployment Flow
1. Run linting to validate Dockerfiles using hadolint.
2. Build Docker images for both the Node.js app and Nginx proxy.
3. Run Nginx syntax check using nginx -t.
4. Login to Docker Hub and push images.
5. Perform OIDC check between Bitbucket and AWS to confirm secure access.
6. Upload essential files (Makefile, docker-compose.yml, docker-compose binary) to S3.
7. On EC2, pull images from Docker Hub and execute make up to start containers.
8. Pipelines execute make verify to confirm that all services are running and healthy.

## Environment Variables
You must configure the following in your local .env or Bitbucket repository variables:
Variable	Description
PROJECT_NAME	Name of your project (e.g. codetocloud)
DOCKER_USERZ	Your Docker Hub username
DOCKER_REPO	Target Docker Hub repository
APP_TAG	Image tag (e.g. latest or Git commit hash)
AWS_REGION	AWS region (e.g. ap-southeast-2)
S3_BUCKET	S3 bucket for storing deployment files
AWS_ROLE_ARN	IAM role for Bitbucket OIDC
EC2_INSTANCE_ID	Target EC2 instance ID
DOCKER_PASSZ	Docker Hub password (set in Bitbucket pipeline variables)

## Tech Stack 
Backend: Node.js (Express)
Proxy: Nginx
CI/CD: Bitbucket Pipelines + AWS SSM
Containerization: Docker + Docker Compose
Registry: Docker Hub
Hosting: AWS EC2

## Makefile Targets
Target	Description
lint	Runs hadolint on all Dockerfiles.
build	Builds both app and nginx Docker images.
test-nginx	Validates Nginx configuration syntax.
login / push	Logs into Docker Hub and pushes images.
OICDcheck	Verifies Bitbucket OIDC → AWS integration and S3 write access.
upload-s3	Uploads deployment files (Makefile, docker-compose, binary docker-compose) to S3.
deploy	Executes remote EC2 deployment via AWS SSM.
verify	Health-checks EC2 endpoint (/api/health).
up / down / clean	Local lifecycle management commands.

## Pipeline Design

Bitbucket pipeline runs in two main stages:
1. Lint & Build & Push
Lints Dockerfiles, builds both images, and pushes them to Docker Hub.
2. Deploy & Validate (via AWS OIDC + SSM)
Uses OIDC for AWS authentication (no static credentials).
Uploads required files to S3.
Executes remote deployment through SSM (make deploy → EC2 → make up).
Verifies service health via API /api/health.

## Health Endpoints
Service	Endpoint
App	http://<EC2-IP>:3000/api/health
Nginx	http://<EC2-IP>/health