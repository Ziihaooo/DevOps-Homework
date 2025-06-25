DOCKER_IMAGE_NAME ?= myuser/myapp
TAG ?= latest

.PHONY: all lint build run push env

all: lint build run

env:
	echo "DOCKER_IMAGE_NAME=$(DOCKER_IMAGE_NAME)" > .env
	echo "TAG=$(TAG)" >> .env

lint:
	hadolint Dockerfile

build: env
	docker build -t $(DOCKER_IMAGE_NAME):$(TAG) .

run: env
	docker-compose --env-file .env up --abort-on-container-exit --build --remove-orphans

push:
	echo "$(WEI_PASSWORD)" | docker login -u "$(WEI_USERNAME)" --password-stdin
	docker push $(DOCKER_IMAGE_NAME):$(TAG)

