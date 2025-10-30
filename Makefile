#dont ignore extra words
%:
	@:
# Use short names for Docker and Docker Compose
D := docker
DC := docker compose
TRIVY_OPTS=--severity HIGH,CRITICAL --exit-code 1
.PHONY: up down logs rebuild delete

build:
	$(DC) build

# Start all services (detached mode)
start:
	$(DC) up -d 

# Stop and remove all running containers
down:
	$(DC) down -v

reset:
	$(DC) down && $(DC) up -d --build
# Rebuild containers without cache
rebuild:
	$(DC) build --no-cache

# View logs
logs:
	$(DC) logs -f

# Delete ALL containers and images (use with caution)
delete:
	@if [ -n "$$($(D) ps -aq)" ]; then $(D) stop $$($(D) ps -aq); fi
	@if [ -n "$$($(D) ps -aq)" ]; then $(D) rm $$($(D) ps -aq); fi
	@if [ -n "$$($(D) images -aq)" ]; then $(D) rmi $$($(D) images -aq); fi

#download trivy in CI
trivydownload:
	curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

logs:
	$(DC) logs --tail=50 --no-color

#do multiples can 
#create trivy report for each images
#show output in terminal as well in the json 
scan:
	@echo "Collecting running Docker images..."
	@IMAGES=$$(docker ps --format "{{.Image}}" | sort | uniq); \
	if [ -z "$$IMAGES" ]; then \
		echo "No running containers found. Please run 'make start' first."; \
	else \
		for img in $$IMAGES; do \
			echo "============================="; \
			echo "Scanning $$img ..."; \
			trivy image $(TRIVY_OPTS) --format table $$img; \
			trivy image $(TRIVY_OPTS) --format json -o trivy-report-$$(echo $$img | tr '/' '_' | tr ':' '_').json $$img; \
			echo "Report saved: trivy-report-$$(echo $$img | tr '/' '_' | tr ':' '_').json"; \
			echo ""; \
		done; \
	fi

#terminal output and json file as well for trivy config 
trivyconfig:
	trivy config . --format table
	trivy config . --format json -o trivy-config-report.json