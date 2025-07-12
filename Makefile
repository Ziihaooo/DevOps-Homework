TAG ?= $(shell git rev-parse --short HEAD)

env:
@echo "DOCKER_IMAGE_NAME=$(DOCKER_IMAGE_NAME)" > .env
@echo "TAG=$(TAG)" >> .env
@echo "✅  Generated .env with DOCKER_IMAGE_NAME=$(DOCKER_IMAGE_NAME) TAG=$(TAG)"

lint: env
hadolint Dockerfile

build: env
docker build -t $(DOCKER_IMAGE_NAME):$(TAG) .

run: env
docker compose --env-file .env up --abort-on-container-exit

push:
echo "$$DOCKER_PASSWORD" | docker login -u "$$DOCKER_USERNAME" --password-stdin
docker push $(DOCKER_IMAGE_NAME):$(TAG)

clean:
docker compose --env-file .env down --remove-orphans
