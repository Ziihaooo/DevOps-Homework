#ENV define for easier use
DC := docker compose

.PHONY: build run up db-wait test down clean reset

build:
	$(DC) build

run:
	$(DC) up -d 

up:
	$(DC) up -d --build
#@ for printing echo
db-wait:
#this command check is the database container ready and responds
#-T stands for no TTY to prevent errors
#name must align with dockerfile
	@$(DC) exec -T mysql_db mysqladmin ping -h "localhost" --silent && \
	echo "MYSQL is ready"

#name must align with dockerfile
test:
	$(DC) exec -T node_api npm test

down:
	$(DC) down

clean:
	$(DC) down -v

reset:
	$(DC) down && $(DC) up -d --build