# memcached Makefile
# https://hub.docker.com/_/memcached
# on Ubuntu: /etc/containers/registries.conf
# unqualified-search-registries = ["docker.io"]
# podman search memcached -f is-official=true

START_FLAGS ?= -d

compose_file := $(CURDIR)/memcached.yml

up: $(compose_file)
	podman-compose -f $< up $(START_FLAGS)

start: $(compose_file)
	podman-compose -f $< stop

stop: $(compose_file)
	podman-compose -f $< stop

exec:
	podman exec -e LINES=$(LINES) \
	            -e COLUMNS=$(COLUMNS) \
	            -e TERM=$(TERM) \
	            -it \
							memcached-dev /bin/bash

down: $(compose_file) stop
	podman-compose -f $< down
