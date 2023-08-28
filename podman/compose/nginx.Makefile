# nginx Makefile
# https://hub.docker.com/_/nginx
# on Ubuntu: /etc/containers/registries.conf
# unqualified-search-registries = ["docker.io"]
# podman search -f is-official=true

START_FLAGS ?= -d

compose_file := $(CURDIR)/nginx.yml

up: $(compose_file)
	podman-compose -f $< up $(START_FLAGS)

start: $(compose_file)
	podman-compose -f $< start

stop: $(compose_file)
	podman-compose -f $< stop

exec: start
	podman exec -e LINES=$(LINES) \
	            -e COLUMNS=$(COLUMNS) \
	            -e TERM=$(TERM) \
	            -it \
	            nginx-dev /bin/bash

down: $(compose_file) stop
	podman-compose -f $< down
