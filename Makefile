.PHONY: lint build login push
PROJECT_NAME=orchestration-week8
APP_TAG ?= $(or $(VERSION), $(shell git rev-parse --short HEAD))
AWS_REGION ?= ap-southeast-2

lint:
	@echo "Linting Dockerfile"
	docker run --rm -v $(pwd):/app hadolint/hadolint hadolint /app/app/Dockerfile
	docker run --rm -v $(pwd):/app hadolint/hadolint hadolint /app/nginx/Dockerfile

build:
	@echo "Building Docker images"
	docker build -t $(DOCKER_USERZ)/$(DOCKER_REPO)-app:$(APP_TAG) -f app/Dockerfile ./app
	docker build -t $(DOCKER_USERZ)/$(DOCKER_REPO)-app:$(APP_TAG) -f nginx/Dockerfile ./nginx

login:
	docker login -u $(DOCKER_USERZ) -p $(DOCKER_PASS)

push: login 
	docker push $(DOCKER_USERZ)/$(DOCKER_REPO)-app:$(APP_TAG)