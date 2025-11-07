.phony: lint build push deploy up

#lint
lint:
	@echo: "Linting Dockerfile"
		docker run --rm -v $$(pwd):/app hadolint/hadolint hadolint /app/app/Dockerfile
