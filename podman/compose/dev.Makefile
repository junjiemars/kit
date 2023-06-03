# podman compose for dev
# https://podman.io

IMAGE_NAME ?= centos
#IMAGE_NAME ?= ubuntu

COLUMNS ?= 80
LINES ?= 24


build_flags ?= -rm
start_flags ?= -d --remove-orphans
remove_flags ?= -force

podman_file := $(CURDIR)/dev/$(IMAGE_NAME).dockerfile
compose_file := $(CURDIR)/compose/$(IMAGE_NAME)-dev.yaml
image_tag := junjiemars/$(IMAGE_NAME)-dev:latest
bone_dev_container := bone-$(IMAGE_NAME)-dev


build: $(podman_file)
	podman build $(build_flags) -t $(image_tag) -f $< .

start: $(compose_file)
	podman-compose -f $< up $(start_flags)

stop: $(compose_file)
	podman container ls && podman compose -f $< stop

exec: start
	podman exec -e LINES=$(LINES) \
							-e COLUMNS=$(COLUMNS) \
							-e TERM=$(TERM) \
							-it -u u \
							$(bone_dev_container) ${SHELL}

remove: $(compose_file) stop
	podman-compose -f $< rm $(remove_flags)

clean: $(compose_file) remove
	podman rmi $(image_tag)

push: build
	podman push $(image_tag)

pull:
	podman pull $(image_tag)


.PHONY: build start stop exec remove clean push pull
