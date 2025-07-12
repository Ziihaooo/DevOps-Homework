IMAGE        := landing-page
CONTAINER    := landing-page

.PHONY: build run clean kill8080

build:
@docker build -t $(IMAGE) .

kill8080:
@lsof -ti tcp:8080 | xargs -r kill || true

run: kill8080
@docker compose up -d
@echo "Site is starting at http://localhost:8080"; sleep 2
@open http://localhost:8080 2>/dev/null || xdg-open http://localhost:8080 || true

clean:
@docker compose down --rmi all --volumes --remove-orphans || true
