.PHONY: lint build login push OICDcheck upload-s3 deploy

lint:
	@echo "Linting Dockerfile"
	docker run --rm -v $$(pwd):/app hadolint/hadolint hadolint /app/app/Dockerfile
	
build:
	docker build -t $(DOCKER_USERZ)/$(DOCKER_REPO)-app:$(APP_TAG) -f app/Dockerfile ./app