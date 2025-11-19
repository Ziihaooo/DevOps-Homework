#Docker user
#docker pass word
#docker repo 
S3_BUCKET = zihao-app-artifacts
S3_COMPOSE = docker-compose.yml
S3_MAKEFILE = Makefile
S3_DOCKER_COMPOSE = docker-compose
DOCKER_USERZ ?= $(DOCKER_USER)
DOCKER_REPO ?= $(PROJECT_NAME)
AWS_REGION ?=ap-southeast-2
APP_TAG ?= $(or $(VERSION), $(shell git rev-parse --short HEAD))
.PHONY: lint build login push OICDcheck upload-s3

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
	aws s3 cp docker-compose.yml s3://$(S3_BUCKET)/$(S3_COMPOSE) --region $(AWS_REGION)
	aws s3 cp Makefile s3://$(S3_BUCKET)/$(S3_MAKEFILE) --region $(AWS_REGION)
	aws s3 cp docker-compose s3://$(S3_BUCKET)/$(S3_DOCKER_COMPOSE) --region $(AWS_REGION)
	@echo "✅ Uploaded:"
	@echo "  - s3://$(S3_BUCKET)/$(S3_COMPOSE)"
	@echo "  - s3://$(S3_BUCKET)/$(S3_MAKEFILE)"
	@echo "  - s3://$(S3_BUCKET)/$(S3_DOCKER_COMPOSE)"
