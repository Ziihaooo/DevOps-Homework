Project Workflow Summary 

This project demonstrates how to use Terraform to provision AWS infrastructure, deploy an application into a private EC2 instance, expose it securely through an Application Load Balancer (ALB), and support outbound access via a NAT Gateway.

The workflow is:

Run Terraform inside the environment directory (dev or prod).
All infrastructure is created per-environment, so Terraform commands must be executed under the correct path.

After terraform apply, run upload_output.sh.
This script extracts Terraform outputs (EC2 instance ID, ALB DNS, etc.), generates outputs.json, and uploads it to the S3 artifacts bucket.
The Bitbucket pipeline reads this file later to know where to deploy.

Trigger the Bitbucket Pipeline and wait for the deployment to complete.
The pipeline builds the Docker image, uploads deployment files to S3, deploys to the EC2 instance via AWS OIDC + SSM, and finally runs a health-check against the ALB.
When the pipeline displays “OK – Deployment healthy through ALB”, the deployment is successful.