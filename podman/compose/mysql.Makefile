# mysql Makefile
# https://hub.docker.com/_/mysql
# on Ubuntu: /etc/containers/registries.conf
# unqualified-search-registries = ["docker.io"]

START_FLAGS ?= -d
# START_FLAGS ?= -d --remove-orphans

compose_file := $(CURDIR)/mysql.yml

up: $(compose_file)
	podman-compose -f $< up $(START_FLAGS)

down: $(compose_file)
	podman-compose -f $< down

exec:
	podman exec -e LINES=$(LINES) \
							-e COLUMNS=$(COLUMNS) \
							-e TERM=$(TERM) \
							-it \
							mysql-dev /bin/bash

start: $(compose_file)
	podman-compose -f $< start

stop: $(compose_file)
	podman-compose -f $< stop
