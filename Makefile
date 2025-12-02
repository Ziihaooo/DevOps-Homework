.PHONY: lint build login push up down restart ngrok
export PROJECT_NAME := orchestration-week8
export APP_TAG := $(or $(VERSION), $(shell git rev-parse --short HEAD))
export AWS_REGION := ap-southeast-2
export DOCKER_USERZ ?= zavierrr
export DOCKER_REPO ?= week8

lint:
	@echo "Linting Dockerfile"
	docker run --rm -v $$(pwd):/app hadolint/hadolint hadolint /app/app/Dockerfile
	docker run --rm -v $$(pwd):/app hadolint/hadolint hadolint /app/nginx/Dockerfile

build:
	@echo "Building Docker images"
	docker build -t $(DOCKER_USERZ)/$(PROJECT_NAME)-app:$(APP_TAG) -f app/Dockerfile ./app
	docker build -t $(DOCKER_USERZ)/$(PROJECT_NAME)-nginx:$(APP_TAG) -f nginx/Dockerfile ./nginx

login:
	docker login -u $(DOCKER_USERZ) -p $(DOCKER_PASS)

push: 
	docker push $(DOCKER_USERZ)/$(PROJECT_NAME)-app:$(APP_TAG)
	docker push $(DOCKER_USERZ)/$(PROJECT_NAME)-nginx:$(APP_TAG)
up:
	@echo "🚀 Starting containers..."
	docker-compose up -d --build

down:
	@echo "🧹 Stopping containers..."
	docker-compose down

restart:
	make down && make up



