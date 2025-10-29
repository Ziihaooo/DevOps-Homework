#ENV define for easier use
D := docker
DC := docker compose

ifeq ($(CI),true)
	ENV :=
else
	ENV := --env-file .env.tests
endif

.PHONY: build run up db-wait test down clean reset

build:
	$(DC) $(ENV) build

start:
	$(DC) $(ENV) up -d --build

#@ for printing echo
db-wait:
#this command check is the database container ready and responds
#-T stands for no TTY to prevent errors
#name must align with dockerfile
	@$(D) exec -t mysql_db mysqladmin ping -h "localhost" --silent && \
	echo "MYSQL is ready"

#name must align with dockerfile
test:
	$(D) exec -t node_api npm test

down:
	$(DC) $(ENV) down

clean:
	$(DC) $(ENV) down -v

reset:
	$(DC) $(ENV) down && $(DC) $(ENV) up -d --build