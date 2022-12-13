# podman machine
# https://podman.io

IMAGE_NAME ?= centos

BUILD_FLAGS ?= --rm
START_FLAGS ?= -d --remove-orphans
REMOVE_FLAGS ?= --force

podman_file := dev/$(IMAGE_NAME).dockerfile
compose_file := compose/$(IMAGE_NAME)-dev.yaml
image_tag := junjiemars/$(IMAGE_NAME)-dev:latest
bone_dev_container := bone-$(IMAGE_NAME)-dev


build: $(podman_file)
	podman build $(BUILD_FLAGS) -t $(image_tag) -f $< .

exit:
	podman machine stop

init: init-container

init-machine:
	podman machine ls || podman machine init

init-container: init-container
	podman container ls || podman machine start

start: $(compose_file) stop init
	podman-compose -f $<  up $(START_FLAGS)

stop: $(compose_file)
	podman container ls && podman-compose -f $< stop

exec: start
	podman exec -e LINES=$(LINES) \
							-e COLUMNS=$(COLUMNS) \
							-e TERM=$(TERM) \
							-it -u u \
							$(bone_dev_container) /bin/bash

# remove: $(compose_file) stop
# 	podman-compose -f $<  rm $(REMOVE_FLAGS)

clean: $(compose_file) remove
	podman rmi $(image_tag)

push: build
	podman push $(image_tag)

pull:
	podman pull $(image_tag)

.PHONY: build start stop exec remove clean push pull
