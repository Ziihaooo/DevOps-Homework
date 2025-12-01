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

up:
	@echo "🚀 Starting containers..."
	docker-compose up -d --build

down:
	@echo "🧹 Stopping containers..."
	docker-compose down

restart:
	make down && make up

ngrok:
	@echo "🚀 Starting app + ngrok preview..."
	docker-compose up -d
	@echo "📦 Installing ngrok"
	apk add --no-cache curl >/dev/null
	curl -s https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.tgz -o ngrok.tgz
	tar zxvf ngrok.tgz >/dev/null
	@echo "🔑 Authenticating ngrok"
	./ngrok authtoken $$NGROK_AUTHTOKEN
	@echo "🌍 Exposing port 80 via ngrok"
	./ngrok http 80 > ngrok.log &
	sleep 5
	@echo "🌐 Public URL:"
	@grep "Forwarding" ngrok.log | head -1
	@echo "🕐 Keeping container alive for 5 minutes..."
	sleep 300
	docker-compose down
