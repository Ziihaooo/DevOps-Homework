.PHONY: lint build push OICDcheck upload deploy verify up down clean

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
EC2_INSTANCE_ID ?= i-01a647dab0456420a
AWS_REGION ?= ap-southeast-2
AWS_ROLE_ARN ?= arn:aws:iam::314146318322:role/PIPELINEOIDCROLE_ZIHAO
S3_BUCKET ?= uat-artifacts-zihao
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

#this is use for downloading compose in ec2 I cant find a way
#used it for one time local use
upload-compose:
	@echo "📦 Uploading docker-compose binary to S3..."
	aws s3 cp docker-compose s3://uat-artifacts-zihao/tools/docker-compose
	@echo "✅ docker-compose uploaded"
#same idea for ec2, only focus on one ec2 so ec2 fixed in the env

upload:
	@echo "📦 Packaging and uploading $(PROJECT_NAME) to S3..."
	tar -czf $(PROJECT_NAME).tar.gz app deploy docker-compose.yml Makefile .env.template
	aws s3 cp $(PROJECT_NAME).tar.gz s3://uat-artifacts-zihao/deploy/$(PROJECT_NAME).tar.gz
	rm $(PROJECT_NAME).tar.gz
	@echo "✅ Upload complete"

deploy:
	@echo "🚀 Deploying $(PROJECT_NAME) to EC2 via SSM..."
	aws ssm send-command \
		--region $(AWS_REGION) \
		--instance-ids "$(EC2_INSTANCE_ID)" \
		--document-name "AWS-RunShellScript" \
		--comment "Deploy $(PROJECT_NAME)" \
		--parameters "{\"commands\":[\"set -e && echo ====== [0/5] Installing dependencies ====== && sudo yum install -y make docker && sudo systemctl enable docker && sudo systemctl start docker\",\"echo ====== [0.5/5] Installing docker-compose ====== && sudo aws s3 cp s3://uat-artifacts-zihao/tools/docker-compose /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose\",\"echo ====== [1/5] Fetching latest source code ====== && sudo mkdir -p /opt/$(PROJECT_NAME) && sudo rm -rf /opt/$(PROJECT_NAME)/* && aws s3 cp s3://uat-artifacts-zihao/deploy/$(PROJECT_NAME).tar.gz /tmp/$(PROJECT_NAME).tar.gz && sudo tar -xzf /tmp/$(PROJECT_NAME).tar.gz -C /opt/$(PROJECT_NAME)\",\"cd /opt/$(PROJECT_NAME) && echo ====== [2/5] Generating environment file ====== && sed -e 's|DOCKER_USERZ=|DOCKER_USERZ=$(DOCKER_USERZ)|' -e 's|DOCKER_REPO=|DOCKER_REPO=$(DOCKER_REPO)|' -e 's|APP_TAG=|APP_TAG=$(APP_TAG)|' .env.template > .env && cat .env\",\"cd /opt/$(PROJECT_NAME) && echo ====== [3/5] Building and starting containers ====== && sudo make up\",\"echo ====== [4/5] Deployment complete! ======\"]}"
	@echo "✅ SSM deployment command sent successfully."

	

	
verify:
	aws ssm send-command \
		--instance-ids "$(EC2_INSTANCE_ID)" \
		--document-name "AWS-RunShellScript" \
		--parameters 'commands=["curl -I http://localhost/health", "curl -I http://localhost/api/health"]' \
		--region $(AWS_REGION)

up:
	@echo "🚀 Building and starting containers..."
	sudo docker-compose build --no-cache
	sudo docker-compose up -d --remove-orphans
	@echo "✅ Stack is running!"


down:
	docker compose down -v

clean:
	docker system prune -f