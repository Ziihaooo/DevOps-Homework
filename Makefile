#ENV define for easier use

SHELL := /bin/bash

DC := docker compose

.PHONY: build run up db:wait test down clean reset

build:
	$(DC) build

run:
	$(DC) up -d 

up:
	$(DC) up -d --build
#@ for printing echo
db:wait:
	@$(DC) exec -T db mysqladmin ping -h "localhost" --silent && \
	echo "MYSQL is ready"

test:
	$(DC) exec -T api npm test

down:
	$(DC) down

clean:
	$(DC) down -v

reset:
	$(DC) down && $(DC) up -d --build