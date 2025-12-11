.PHONY: lint build login push aws-oidc tf-install tf-validate tf-plan tf-apply tf-destroy
export PROJECT_NAME := grafana-week9
export APP_TAG := $(or $(VERSION), $(shell git rev-parse --short HEAD))
export AWS_REGION := ap-southeast-2
export DOCKER_USERZ ?= zavierrr
export DOCKER_REPO ?= week9

lint:
	@echo "Linting Dockerfile"
	docker run --rm -v $$(pwd):/app hadolint/hadolint hadolint /app/grafana/Dockerfile

build:
	@echo "Building Docker images"
	docker build -t $(DOCKER_USERZ)/$(PROJECT_NAME):$(APP_TAG) -f grafana/Dockerfile ./grafana

login:
	docker login -u $(DOCKER_USERZ) -p $(DOCKER_PASS)

push: 
	docker push $(DOCKER_USERZ)/$(PROJECT_NAME):$(APP_TAG)

tf-install:
	@echo "Installing Terraform..."
	wget -q https://releases.hashicorp.com/terraform/1.8.5/terraform_1.8.5_linux_amd64.zip
	unzip terraform_1.8.5_linux_amd64.zip
	mv terraform /usr/local/bin/

dev:
	cd infra/env/dev
tf-validate:
	cd infra/env/dev && terraform init -backend=false && terraform validate

tf-plan:
	cd infra/env/dev && terraform init && terraform plan -no-color

tf-apply:
	cd infra/env/dev && terraform init && terraform apply -auto-approve

tf-destroy:
	cd infra/env/dev && terraform init && terraform destroy -auto-approve
