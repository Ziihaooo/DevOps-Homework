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
	docker build -t $(DOCKER_USERZ)/$(DOCKER_REPO)-app:$(APP_TAG) -f app/Dockerfile ./app
	docker build -t $(DOCKER_USERZ)/$(DOCKER_REPO)-nginx:$(APP_TAG) -f deploy/nginx/Dockerfile.nginx ./deploy/nginx


#<user>/<repo>:<tag>
# as the only one who can push the image will only assigned to one exact docker hub
# so the docker user must be fixed in the env
login:
	@echo "Logging in to Docker Hub..."
	@docker login -u $(DOCKER_USERZ) -p $(DOCKER_PASSZ)

push:
	docker push $(DOCKER_USERZ)/$(DOCKER_REPO)-app:$(APP_TAG)
	docker push $(DOCKER_USERZ)/$(DOCKER_REPO)-nginx:$(APP_TAG)
	@echo "push successful"

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
#same idea for ec2, only focus on one ec2 so ec2 fixed in the env

deploy:
	@echo "Starting deployment on EC2 via SSM..."

	# write script to a temporary file
	@echo "set -e" > /tmp/deploy_script.sh
	@echo "echo [INFO] Starting $(PROJECT_NAME) deployment at \`date\`" >> /tmp/deploy_script.sh
	@echo "if ! command -v docker &> /dev/null; then" >> /tmp/deploy_script.sh
	@echo "  echo [INSTALL] Installing Docker and tools...; sudo yum update -y && sudo yum install -y docker make git; sudo systemctl enable docker && sudo systemctl start docker;" >> /tmp/deploy_script.sh
	@echo "fi" >> /tmp/deploy_script.sh
	@echo "sudo mkdir -p /opt/$(PROJECT_NAME)" >> /tmp/deploy_script.sh
	@echo "cd /opt/$(PROJECT_NAME)" >> /tmp/deploy_script.sh
	@echo "if [ ! -d .git ]; then sudo rm -rf * && sudo git clone https://github.com/<yourrepo>/$(PROJECT_NAME).git .; else sudo git fetch --all && sudo git reset --hard origin/main; fi" >> /tmp/deploy_script.sh
	@echo "if [ -f docker-compose.yml ]; then sudo docker compose down -v || true; sudo docker system prune -af || true; sudo docker compose up -d --build; elif grep -q ^up: Makefile 2>/dev/null; then sudo make up; else echo [ERROR] No deploy target found; exit 1; fi" >> /tmp/deploy_script.sh
	@echo "echo [DONE] Deployment complete." >> /tmp/deploy_script.sh

	aws ssm send-command \
		--instance-ids "$(EC2_INSTANCE_ID)" \
		--document-name "AWS-RunShellScript" \
		--comment "Deploy $(PROJECT_NAME) $(APP_TAG)" \
		--parameters file://<(echo "{\"commands\": [\"$$(cat /tmp/deploy_script.sh | sed 's/\"/\\\\\"/g')\"]}") \
		--region $(AWS_REGION)

	@echo "Deployment command sent via SSM successfully."


verify:
	AWS_REGION="$(AWS_REGION)" \
	aws ssm send-command \
		--instance-ids "$(EC2_INSTANCE_ID)" \
		--document-name "AWS-RunShellScript" \
		--parameters 'commands=["curl -s -o /dev/null -w \"%{http_code}\" http://localhost/health","curl -s -o /dev/null -w \"%{http_code}\" http://localhost/api/health"]' \
		--region $(AWS_REGION)
	@echo "Internal health probe executed via SSM."

up:
	docker pull
	docker compose up -d --build
	@"EC2 running"

down:
	docker compose down -v

clean:
	docker system prune -f