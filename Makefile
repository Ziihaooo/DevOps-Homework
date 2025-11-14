.PHONY: lint build login push OICDcheck upload-s3 deploy verify up down restart logs status cleanRetry
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
EC2_INSTANCE_ID ?= i-0e9efb73e3f4a89a6
AWS_REGION ?= ap-southeast-2
AWS_ROLE_ARN ?= arn:aws:iam::314146318322:role/PIPELINEOIDCROLE_ZIHAO
S3_BUCKET ?= uat-artifacts-zihao
S3_COMPOSE := $(PROJECT_NAME)/docker-compose.yml
S3_MAKEFILE := $(PROJECT_NAME)/Makefile
#run shell command and give the output to the var 
#1$ run is make file var,2$ run is shell env var
#$Docker var will pass to shell
DOCKER_USERZ ?= $(shell echo $$DOCKER_USERZ)
DOCKER_PASSZ ?= $(shell echo $$DOCKER_PASSZ)

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

#should login first and push
push: login
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


#for local, just run docker compose but for remote need to find a way to integrate the image without building them
#push first and pull

upload-s3:
	@echo "📤 Uploading files to S3..."
	aws s3 cp docker-compose.yml s3://$(S3_BUCKET)/$(S3_COMPOSE) --region $(AWS_REGION)
	aws s3 cp Makefile s3://$(S3_BUCKET)/$(S3_MAKEFILE) --region $(AWS_REGION)
	@echo "✅ Uploaded:"
	@echo "  - s3://$(S3_BUCKET)/$(S3_COMPOSE)"
	@echo "  - s3://$(S3_BUCKET)/$(S3_MAKEFILE)"

deploy:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🚀 Deploying to EC2"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "Project: $(PROJECT_NAME)"
	@echo "Tag: $(APP_TAG)"
	@echo "Instance: $(EC2_INSTANCE_ID)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	aws ssm send-command \
		--region $(AWS_REGION) \
		--instance-ids "$(EC2_INSTANCE_ID)" \
		--document-name "AWS-RunShellScript" \
		--comment "Deploy $(PROJECT_NAME)-$(APP_TAG)" \
		--parameters 'commands=[
			"set -e",
			"echo \"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\"",
			"echo \"🚀 Starting Deployment\"",
			"echo \"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\"",
			"echo \"Tag: $(APP_TAG)\"",
			"echo",
			"echo \"📦 Step 1/6: Installing Docker & Docker Compose\"",
			"sudo yum install -y docker || true",
			"sudo systemctl enable docker",
			"sudo systemctl start docker",
			"sudo curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose",
			"sudo chmod +x /usr/local/bin/docker-compose",
			"docker --version",
			"docker-compose --version",
			"echo \"✅ Docker installed\"",
			"echo",
			"echo \"📁 Step 2/6: Preparing deployment directory\"",
			"sudo mkdir -p $(DEPLOY_PATH)",
			"cd $(DEPLOY_PATH)",
			"echo \"Working in: $(DEPLOY_PATH)\"",
			"echo",
			"echo \"📥 Step 3/6: Downloading from S3\"",
			"aws s3 cp s3://$(S3_BUCKET)/$(S3_COMPOSE) docker-compose.yml --region $(AWS_REGION)",
			"aws s3 cp s3://$(S3_BUCKET)/$(S3_MAKEFILE) Makefile --region $(AWS_REGION)",
			"echo \"✅ Downloaded from S3\"",
			"ls -lh",
			"echo",
			"echo \"📝 Step 4/6: Creating .env file\"",
			"sudo tee .env > /dev/null <<EOF",
			"PROJECT_NAME=$(PROJECT_NAME)",
			"DOCKER_USERZ=$(DOCKER_USERZ)",
			"DOCKER_REPO=$(DOCKER_REPO)",
			"APP_TAG=$(APP_TAG)",
			"EOF",
			"echo \"✅ .env file created:\"",
			"cat .env",
			"echo",
			"echo \"🚀 Step 5/6: Running make up\"",
			"sudo make up",
			"echo",
			"echo \"✅ Step 6/6: Deployment Complete!\"",
			"echo \"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\"",
			"echo \"Tag deployed: $(APP_TAG)\"",
			"echo \"Path: $(DEPLOY_PATH)\""
		]' \
		--region $(AWS_REGION) \
		--output text
	@echo ""
	@echo "✅ Deployment initiated!"
	@echo "💡 Run 'make verify' to check status"


	
verify:
	@echo "🔍 Verifying deployment..."
	aws ssm send-command \
		--instance-ids "$(EC2_INSTANCE_ID)" \
		--document-name "AWS-RunShellScript" \
		--parameters 'commands=[
			"cd $(DEPLOY_PATH)",
			"echo \"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\"",
			"echo \"📝 Environment Configuration\"",
			"echo \"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\"",
			"cat .env",
			"echo",
			"echo \"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\"",
			"echo \"📊 Container Status\"",
			"echo \"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\"",
			"sudo docker-compose ps",
			"echo",
			"echo \"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\"",
			"echo \"🏥 Health Checks\"",
			"echo \"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\"",
			"curl -f http://localhost:3000/api/health && echo \"✅ App healthy\" || echo \"❌ App failed\"",
			"curl -f http://localhost/health && echo \"✅ Nginx healthy\" || echo \"❌ Nginx failed\""
		]' \
		--region $(AWS_REGION) \
		--output text

up:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "🚀 Starting Containers"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "Stopping old containers..."
	docker-compose down || true
	@echo ""
	@echo "Pulling images from Docker Hub..."
	docker-compose pull
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

down:
	docker compose down -v

clean:
	docker system prune -f