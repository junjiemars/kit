# rabbitmq.Makefile
# https://hub.docker.com/_/rabbitmq
# on Ubuntu: /etc/containers/registries.conf
# unqualified-search-registries = ["docker.io"]

START_FLAGS ?= -d
# START_FLAGS ?= -d --remove-orphans

compose_file := $(CURDIR)/rabbitmq.yml

up: $(compose_file)
	podman-compose -f $< up $(START_FLAGS)

start: $(compose_file)
	podman-compose -f $< start

stop: $(compose_file)
	podman-compose -f $< stop

exec:
	podman exec -e LINES=$(LINES) \
	            -e COLUMNS=$(COLUMNS) \
	            -e TERM=$(TERM) \
	            -it \
	            rabbitmq-dev /bin/bash

down: $(compose_file) stop
	podman-compose -f $< down
