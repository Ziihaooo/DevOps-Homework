#!/bin/bash
set -e

# Move into the Terraform environment directory
cd ../infra/envs/dev

# Generate JSON file of outputs from Terraform
terraform output -json > outputs.json

# Upload outputs.json to S3
aws s3 cp outputs.json \
  s3://zihao-dev-artifacts/deploy/outputs.json \
  --region ap-southeast-2

echo "✓ outputs.json uploaded to S3!"
