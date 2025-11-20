#Docker user
#docker pass word
#docker repo 
S3_BUCKET = zihao-app-artifacts
S3_COMPOSE = docker-compose.yml
S3_MAKEFILE = Makefile
S3_DOCKER_COMPOSE = docker-compose
PROJECT_NAME ?= zihaoappalb
DOCKER_REPO ?= $(PROJECT_NAME)
DOCKER_USERZ ?= $(DOCKER_USER) 
AWS_REGION ?=ap-southeast-2
APP_TAG ?= $(or $(VERSION), $(shell git rev-parse --short HEAD))
.PHONY: lint build login push OICDcheck upload-s3 deploy

lint:
	@echo "Linting Dockerfile"
	docker run --rm -v $$(pwd):/app hadolint/hadolint hadolint /app/app/Dockerfile

build:
	docker build -t $(DOCKER_USERZ)/$(DOCKER_REPO)-app:$(APP_TAG) -f app/Dockerfile ./app

login:
	docker login -u $(DOCKER_USERZ) -p $(DOCKER_PASS)

push: login 
	docker push $(DOCKER_USERZ)/$(DOCKER_REPO)-app:$(APP_TAG)

OICDcheck:
	@echo "Testing Bitbucket OIDC connection to AWS..."
# 1. Save Bitbucket's OIDC token to a temp file
	echo "$$BITBUCKET_STEP_OIDC_TOKEN" > /tmp/bb.token

# 2. Check AWS identity using OIDC credentials
	AWS_ROLE_ARN="$(AWS_ROLE_ARN)" \
	AWS_WEB_IDENTITY_TOKEN_FILE="/tmp/bb.token" \
	AWS_REGION="$(AWS_REGION)" \
	aws sts get-caller-identity

# 3. Upload test file to S3 to confirm write access
	echo "Hello from Bitbucket OIDC pipeline!" > testoidc.txt
	AWS_ROLE_ARN="$(AWS_ROLE_ARN)" \
	AWS_WEB_IDENTITY_TOKEN_FILE="/tmp/bb.token" \
	AWS_REGION="$(AWS_REGION)" \
	aws s3 cp testoidc.txt s3://$(S3_BUCKET)/oidc-test/testoidc.txt

# 4. List uploaded file
	AWS_ROLE_ARN="$(AWS_ROLE_ARN)" \
	AWS_WEB_IDENTITY_TOKEN_FILE="/tmp/bb.token" \
	AWS_REGION="$(AWS_REGION)" \
	aws s3 ls s3://$(S3_BUCKET)/oidc-test/

	@echo "OIDC test successful — AWS access verified!"

upload-s3:
	@echo "📤 Uploading files to S3..."

	# Upload docker-compose.yml
	aws s3 cp docker-compose.yml \
		s3://$(S3_BUCKET)/deploy/$(S3_COMPOSE) \
		--region $(AWS_REGION)

	# Upload Makefile
	aws s3 cp Makefile \
		s3://$(S3_BUCKET)/deploy/$(S3_MAKEFILE) \
		--region $(AWS_REGION)

	# Upload docker-compose binary
	aws s3 cp docker-compose \
		s3://$(S3_BUCKET)/deploy/$(S3_DOCKER_COMPOSE) \
		--region $(AWS_REGION)

	# Upload deploy.sh (your EC2 deployment script)
	aws s3 cp deploy.sh \
		s3://$(S3_BUCKET)/deploy/deploy.sh \
		--region $(AWS_REGION)

	@echo "✅ Uploaded:"
	@echo "  - s3://$(S3_BUCKET)/deploy/$(S3_COMPOSE)"
	@echo "  - s3://$(S3_BUCKET)/deploy/$(S3_MAKEFILE)"
	@echo "  - s3://$(S3_BUCKET)/deploy/$(S3_DOCKER_COMPOSE)"
	@echo "  - s3://$(S3_BUCKET)/deploy/deploy.sh"

deploy:
	aws ssm send-command \
	  --region ap-southeast-2 \
	  --instance-ids "$(EC2_INSTANCE_ID)" \
	  --document-name "AWS-RunShellScript" \
	  --comment "Deploy $(PROJECT_NAME)-$(APP_TAG)" \
	  --parameters "{\"commands\":[\"bash /tmp/deploy.sh \\\"$(PROJECT_NAME)\\\" \\\"$(DOCKER_USERZ)\\\" \\\"$(DOCKER_REPO)\\\" \\\"$(APP_TAG)\\\" \\\"$(S3_BUCKET)\\\" \\\"ap-southeast-2\\\" \\\"123456\\\"\"]}" \
	  --output text

#stop old container and pull the image from docker hub and up them
up:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🚀 Starting Containers"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "Stopping old containers..."
	docker-compose down || true
	@echo ""
	@echo "Pulling images from Docker Hub..."
	docker-compose pull app
	@echo ""
	@echo "Starting containers..."
	docker-compose up -d
	@echo ""
	@echo "Waiting for services..."
	sleep 20
	@echo ""
	@echo "📊 Container Status:"
	docker-compose ps
	@echo ""
	@echo "✅ Containers Started!"

verify:
	@echo "🔍 Verifying deployment via ALB: $(ALB_DNS)"
	@if [ -z "$(ALB_DNS)" ]; then \
		echo "❌ ALB_DNS not set!"; exit 1; \
	fi; \
	for i in $$(seq 1 30); do \
		echo "Attempt $$i: checking http://$(ALB_DNS)/health ..."; \
		if curl -fsS "http://$(ALB_DNS)/health"; then \
			echo "✅ Deployment healthy through ALB!"; exit 0; \
		fi; \
		sleep 3; \
	done; \
	echo "❌ Deployment did NOT become healthy in time via ALB."; exit 1


down:
	docker compose down -v