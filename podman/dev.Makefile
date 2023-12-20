# podman compose for dev
# https://podman.io

IMAGE_NAME ?= centos
#IMAGE_NAME ?= ubuntu

build_flags ?= -rm
#start_flags ?= -d --remove-orphans
remove_flags ?= -force
stats_flags ?= --no-reset --no-stream

podman_file := dev/$(IMAGE_NAME).dockerfile
compose_file := compose/$(IMAGE_NAME)-dev.yaml
image_tag := junjiemars/$(IMAGE_NAME)-dev:latest
container_name := bone-$(IMAGE_NAME)-dev


build: $(podman_file)
	podman build $(build_flags) -t $(image_tag) -f $< .

up: $(compose_file)
	podman-compose -f $< up -d

down: $(compose-file)
	podman-compose -f $(compose_file) down

start: $(compose_file) 
	podman-compose -f $< start $(start_flags)

stop: $(compose_file)
	podman-compose -f $(compose_file) stop

exec:
	podman exec -e LINES=${LINES} \
	       		  -e COLUMNS=${COLUMNS} \
						  -e TERM=${TERM} \
						  -it -u u \
						  $(container_name) /bin/bash

remove: $(compose_file) stop
	podman-compose -f $< rm $(remove_flags)

clean: $(compose_file) remove
	podman rmi $(image_tag)

push: build
	podman push $(image_tag)

pull:
	podman pull $(image_tag)


.PHONY: build start stop exec remove clean push pull
