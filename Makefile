.PHONY = all build run exec
# Combine command with the correct order where run is the last one
all: run

# since pull already done in dockerfile I dont think we need that here

# all command should run docker compose yml file
build:
	docker compose build
run: build
	docker compose up -d
stop:
	docker compose down
