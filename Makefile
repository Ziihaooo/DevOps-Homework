.phony: lint build push OICDcheck deploy verify up down clean

#project name = container after you build 
#docker repo = the name of the docker hub you want
PROJECT_NAME := codetocloud
DOCKER_REPO ?= codetocloud
#“Run the shell command git rev-parse --short HEAD,
#take its output (the short Git commit hash),
#and assign it to the Makefile variable APP_TAG.”

#real world scenario 
#Developer pushes commit → Pipeline builds image: zavierrr/app:7f3a2d1
#QA tests → If approved → Tag that commit as v1.0.0 → Pipeline re-tags zavierrr/app:v1.0.0
APP_TAG ?= $(or $(VERSION), $(shell git rev-parse --short HEAD))
#dont reveal credential
#with $() will first check is there any var provide after make command
#if not then will use the default in the env (bitbucket env)
EC2_INSTANCE_ID ?= i-0b0d36eecbf0e411a
AWS_REGION ?= ap-southeast-2
AWS_ROLE_ARN ?= arn:aws:iam::314146318322:role/PIPELINEOIDCROLE_ZIHAO
S3_BUCKET ?= uat-artifacts-zihao

#lint
lint:
	@echo "Linting Dockerfile"
	docker run --rm -v $$(pwd):/app hadolint/hadolint hadolint /app/app/Dockerfile
	docker run --rm -v $$(pwd):/app hadolint/hadolint hadolint /app/deploy/nginx/Dockerfile.nginx

build:
	docker build -t $(APP_IMAGE) -f app/Dockerfile ./app
	docker build -t $(NGINX_IMAGE) -f deploy/nginx/Dockerfile.nginx ./deploy/nginx


#<user>/<repo>:<tag>
# as the only one who can push the image will only assigned to one exact docker hub
# so the docker user must be fixed in the env
login:
	@echo "Logging in to Docker Hub..."
	@docker login -u $(DOCKER_USERZ) -p $(DOCKER_PASSZ)
push:
	@echo "pushing images"
	docker tag $(PROJECT_NAME)-app $(DOCKER_USER)/$(DOCKER_REPO)-app:$(APP_TAG)
	docker tag $(PROJECT_NAME)-nginx $(DOCKER_USER)/$(DOCKER_REPO)-nginx:$(APP_TAG)
	docker push $(DOCKER_USER)/$(DOCKER_REPO)-app:$(APP_TAG)
	docker push $(DOCKER_USER)/$(DOCKER_REPO)-nginx:$(APP_TAG)
	@echo "push successful"

OICDcheck:
	@echo "Testing Bitbucket OIDC connection to AWS..."
	echo "$$BITBUCKET_STEP_OIDC_TOKEN" > /tmp/bb.token

	export AWS_ROLE_ARN="$(AWS_ROLE_ARN)"; \
	export AWS_WEB_IDENTITY_TOKEN_FILE="/tmp/bb.token"; \
	export AWS_REGION="$(AWS_REGION)"; \

	echo "Checking AWS identity..."; \
	aws sts get-caller-identity; \

	echo "Hello from Bitbucket OIDC pipeline!" > testoidc.txt; \
	aws s3 cp testoidc.txt s3://$(S3_BUCKET)/oidc-test/testoidc.txt; \

	echo "Listing uploaded file..."; \
	aws s3 ls s3://$(S3_BUCKET)/oidc-test/; \

	echo "OIDC test successful — AWS access verified!"
#same idea for ec2, only focus on one ec2 so ec2 fixed in the env
deploy:
	aws ssm send-command \
		--instance-ids "$(EC2_INSTANCE_ID)" \
		--document-name "AWS-RunShellScript" \
		--comment "Trigger Docker Compose Up" \
		--parameters 'commands=["cd /home/ec2-user/codetocloud && make up"]' \
		--region $(AWS_REGION)
	@echo "deploy successful"

verify:
	verify:
	aws ssm send-command \
		--instance-ids "$(EC2_INSTANCE_ID)" \
		--document-name "AWS-RunShellScript" \
		--parameters 'commands=["sudo nginx -t && sudo systemctl reload nginx"]' \
		--region $(AWS_REGION)
	curl -i http://$(EC2_PUBLIC_IP)/health
	curl -i http://$(EC2_PUBLIC_IP)/api/health

up:
	docker pull
	docker compose up -d --build
	@"EC2 running"

down:
	docker compose down -v

clean:
	docker system prune -f