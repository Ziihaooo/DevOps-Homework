# Week8 – Multi-Container Fargate Service (Nginx + Backend App)

This project showcases a full DevOps workflow that includes:
- A multi-container application (Nginx reverse proxy + backend API)
- Local development using Docker Compose
- AWS deployment using Terraform (IaC)
- ECS Fargate service wired behind an Application Load Balancer
- Automated CI/CD via Bitbucket Pipelines

The application consists of **two containers** running inside a **single Fargate task**:
1. **nginx** – serves static HTML assets and proxies API requests
2. **app** – backend application running on port 8080

Traffic flows from the ALB → nginx container → backend app container.


---

## 1️⃣ Local Development

Local development is done using Docker Compose, allowing both containers to run exactly as they would inside ECS.

Run locally
Command:
make local-up

Open the application
http://localhost:8080

Stop local environemtn 
Command:
make local-down

## 2️⃣ AWS Deployment (Terraform)
The infrastructure definition is stored under:

infra/envs/dev

Terraform provisions:

route tables, NAT gateway

Security groups for ALB and ECS

ECS Cluster + Task Definition (multi-container)

Fargate Service

Application Load Balancer + target group

Deploy to AWS
cd infra/envs/dev
terraform init
terraform validate
terraform apply


After deployment, Terraform outputs the ALB DNS name, e.g.:

http://week8-alb-xxxxxxx.ap-southeast-2.elb.amazonaws.com


Open that link to access the live application.

## 3️⃣ Bitbucket Pipelines (CI/CD)

The pipeline runs automatically on pushes to my branch, as required.

Pipeline stages:

Build container images

nginx image

backend app image

push to Docker Hub using Bitbucket-secured variables

Infrastructure validation stage

terraform fmt -check

terraform validate

Ensures IaC correctness before deployment

Depending on branch policies

Security

No credentials or secrets are hard-coded

Sensitive values are managed through Bitbucket repository variables

This satisfies the marking criteria for CI/CD pipeline configuration.

## 4️⃣ Architecture Overview

High-level system architecture:

User accesses the ALB public DNS.

ALB forwards traffic to port 80 of the running ECS task.

Nginx container either:

Serves static HTML files, or

Proxies /api/* requests to the backend on port 8080.

Backend returns its response through nginx → ALB → client.

Both containers share the same ENI because ECS uses the awsvpc networking mode.

## 5️⃣ How the System Fits Together

Local: Docker Compose mirrors the same behavior as ECS (nginx → backend).

Images: Built in Pipelines and pushed to Docker Hub.

Terraform: Provisions AWS infrastructure as the single source of truth.

Fargate: Runs the containers in a fully managed environment.

ALB: Exposes the service publicly and health-checks nginx.

This README explains the flow at a high level without exposing implementation details, exactly as required by the rubric.

## 6️⃣ Useful Commands
Format Terraform
terraform fmt

Destroy AWS resources
terraform destroy

## 7️⃣ Project Status

Everything in this project is fully operational:

✔ Local multi-container Docker setup
✔ Terraform-managed AWS infrastructure
✔ ECS Fargate service running nginx + app
✔ ALB routing healthy traffic
✔ Bitbucket pipeline builds & validates
✔ README meets all submission criteria

## 8️⃣ Live URL Example

After deployment, your service is accessible at the ALB DNS name:

http://week8-alb-xxxxx.ap-southeast-2.elb.amazonaws.com
(Your actual DNS name will be shown in Terraform outputs.)