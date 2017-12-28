
IMAGE_NAME ?= centos
CONTAINER_NAME ?= bone-$(IMAGE_NAME)-dev

docker_file := dev/$(IMAGE_NAME).dockerfile
compose_file := compose/$(IMAGE_NAME)-dev.yaml
image_tag := junjiemars/$(IMAGE_NAME)-dev:latest


build: $(docker_file)
	docker build -t $(image_tag) -f $< .

start: $(compose_file) build
	docker-compose -f $<  up -d

stop: $(compose_file)
	docker-compose -f $<  stop

remove: $(compose_file) stop
	docker-compose -f $<  rm --force

clean: $(compose_file) remove
	docker rmi $(image_tag)


.PHONY: build start stop remove clean
