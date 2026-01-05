# Client Domains Automation System
This repository implements an automated DNS provisioning workflow using AWS SQS, Lambda, Route 53, CloudWatch, and a containerised Grafana dashboard running on ECS Fargate.

The system eliminates manual DNS changes by engineers and introduces observability using structured logs and CloudWatch metrics.

## Project Overview

This system automates DNS creation for client production domains.

Workflow:

A JSON message is published to Amazon SQS.

AWS Lambda validates the payload and creates a Route53 DNS record.

Logs are written as structured JSON to CloudWatch.

Metrics (success/failure, action counts) are pushed to CloudWatch Metrics.

A containerised Grafana dashboard visualises system behaviour.

No manual Route 53 updates are required.

## Architecture
SQS → Lambda → Route 53 → CloudWatch Logs + Metrics → Grafana (ECS Fargate)

## Deployment
### 1. Build & Push Grafana Image
make build
make push

### 2. Deploy Terraform Infrastructure
cd infra/env/dev
terraform init
terraform apply


Terraform provisions:

SQS Queue + DLQ

Lambda + IAM execution role

CloudWatch Log Group

CloudWatch Metrics namespace

ECS Fargate service running Grafana

Public ALB (dev)

## PIPELINES
Pipelines automate image build & push, run Terraform validation, and provide manual triggers for apply and destroy.

## Lambda Function

The Lambda function executes the core logic:

### Responsibilities

Parse and validate SQS messages

Enforce schema rules for:

action, client, record_type, target_value

source_env="staging"

target_env="production"

Construct FQDN:

<client>.production.<base_domain>


Create or update DNS records in Route 53

Write structured JSON logs

Emit CloudWatch custom metrics

### Code Location
lambda/dns_handler.py

## Sending Test Messages
### Example Valid SQS Message
{
  "action": "add",
  "client": "ikea",
  "source_env": "staging",
  "target_env": "production",
  "record_type": "A",
  "target_value": "1.2.3.4"
}

### Example Invalid Message (Triggers DLQ)
{
  "action": "add",
  "client": "ikea"
}


Use AWS Console → SQS → “Send Message”.

## CloudWatch Logging

Lambda produces structured JSON like:

{
  "request_id": "abc-123",
  "action": "add",
  "client": "ikea",
  "subdomain": "ikea.production.example.com",
  "target_domain": "1.2.3.4",
  "status": "success"
}


You can query via CloudWatch Logs Insights.

## Grafana Dashboard

Grafana is deployed to ECS Fargate and connects directly to CloudWatch as its data source.

### Dashboard Panels Include:

Success vs Failure Time Series

Success by Action

Failure by Action

Success by Client

Error Log Table

Recent Requests

### Dev Access (Public ALB)

Used ONLY for development → quick testing.

### Prod Access (Internal ALB)

Not exposed to the internet.
Access via:

AWS SSM Port Forwarding → EC2 (private subnet) → Internal ALB → Grafana

## DLQ Failure Handling

If Lambda cannot process a message:

SQS retries up to maxReceiveCount

If still failing → message is moved to Dead-Letter Queue

Engineers inspect message in DLQ

Message remains until retention expiry unless manually reprocessed

This prevents bad messages from blocking the system.

## IAM & Security

IAM roles follow least privilege

Lambda can modify only the specific hosted zone

ECS task role only accesses CloudWatch

Pipeline OIDC role restricted to Terraform

No wildcard * admin policies (except required AWS service exceptions)

No secrets are hardcoded or logged

## Production Recommendations

Your current environment is development mode:

Public ALB for easy testing

Simple access to Grafana

Easier debugging

### For Production, change:

Convert ALB → internal

Add EC2 SSM Proxy Node

Use SSM port forwarding for private access

Strengthen IAM boundaries

Enable CloudWatch alarms (e.g., DLQ > 0)

## Grafana Dashboard Notes

The entire Grafana monitoring stack—including the ECS Fargate task, Application Load Balancer, IAM roles, and the Dashboard itself—is fully provisioned through Terraform. There is no manual setup required for the dashboard or data sources.

The system is designed for "plug-and-play" delivery:

Automated Provisioning: Upon deployment, the Grafana dashboard is automatically created and pre-configured with CloudWatch as the default data source.

Intelligent Filtering: The dashboard features Linked Variables (Client & Action) that automatically filter metrics based on your selection.

Latency Optimization: The variables are configured with an "On time range change" refresh policy. This ensures that even with AWS indexing delays, you can force the dashboard to pull new dimension names (like a new client name) simply by toggling the time range.

Real-time Metrics: Success and failure counts, as well as action-based distributions, will populate the graphs automatically as soon as SQS messages are processed by the Lambda function. 

# Note: Please ensure all changes in the Grafana UI or Terraform configuration are saved/applied immediately to ensure the dashboard remains synchronized with the latest infrastructure state.

This README focuses on the system architecture and deployment workflow, while the accompanying Word file provides detailed instructions for using the Grafana dashboard.
