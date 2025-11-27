#!/bin/bash
set -e

# Generate JSON file of outputs from Terraform
terraform output -json > outputs.json

# Upload the JSON safely to your artifacts bucket
aws s3 cp outputs.json s3://zihao-dev-artifacts/outputs.json \
    --region ap-southeast-2

echo "✔ outputs.json uploaded to S3!"