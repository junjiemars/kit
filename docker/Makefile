
IMAGE_NAME ?= centos

BUILD_FLAGS ?=
START_FLAGS ?= -d
REMOVE_FLAGS ?= --force

docker_file := dev/$(IMAGE_NAME).dockerfile
compose_file := compose/$(IMAGE_NAME)-dev.yaml
image_tag := junjiemars/$(IMAGE_NAME)-dev:latest


build: $(docker_file)
	docker build $(BUILD_FLAGS) -t $(image_tag) -f $< .

start: $(compose_file) stop build
	docker-compose -f $<  up $(START_FLAGS)

stop: $(compose_file)
	docker-compose -f $<  stop

remove: $(compose_file) stop
	docker-compose -f $<  rm $(REMOVE_FLAGS)

clean: $(compose_file) remove
	docker rmi $(image_tag)

push: build
	docker push $(image_tag)

.PHONY: build start stop remove clean push
