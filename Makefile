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

ngrok:
	@echo "🚀 Starting app + ngrok preview..."
	docker-compose up -d
	@echo "📦 Installing ngrok (v3 latest)"
	apk add --no-cache curl >/dev/null
	curl -L -s https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz -o ngrok.tgz
	tar zxvf ngrok.tgz >/dev/null
	@echo "🔑 Authenticating ngrok"
	./ngrok authtoken $${NGROK_AUTHTOKEN_ZIHAO}
	@echo "🌍 Exposing nginx:80 via ngrok..."
	./ngrok http http://nginx:80 --log=stdout --log-format=logfmt > ngrok.log 2>&1 &
	sleep 8
	@echo "📜 ngrok.log (tail):"
	@tail -n 20 ngrok.log
	@echo "🌐 Public URL:"
	@grep -m 1 "started tunnel" ngrok.log | awk -F"url=" '{print $$2}'
	@echo "⏰ Keeping container alive for 5 minutes..."
	sleep 300
	docker-compose down

