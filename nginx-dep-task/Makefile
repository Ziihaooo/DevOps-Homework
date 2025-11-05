#build command that easy to run instead of running docker .... all the time

IMAGE_NAME = week2homework2
CONTAINER_NAME = w2h2_container
PORT = 8080

#still run them if the same file name found
#fake target!

#best practice would be seperate all the command and also build a command that combine all the command 
.PHONY = all build run exec stop clean

# Combine command with the correct order where run is the last one
all: run

# since pull already done in dockerfile I dont think we need that here

# build container based on dockerfile
build:
	docker build -t $(IMAGE_NAME) .

# run container after build
run: build
	docker run -d --name $(CONTAINER_NAME) -p $(PORT):80 $(IMAGE_NAME)
# go inside the docker
exec:
	docker exec -it $(CONTAINER_NAME) /bin/sh
# stop container and remove it
stop:
	-docker stop $(CONTAINER_NAME)
	-docker rm $(CONTAINER_NAME)

# clean the container and image for storage
clean: stop
	-docker rmi $(IMAGE_NAME)
