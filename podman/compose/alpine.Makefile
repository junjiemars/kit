# alpine Makefile
# https://alpinelinux.org/
# https://hub.docker.com/_/alpine
# on Ubuntu: /etc/containers/registries.conf
# unqualified-search-registries = ["docker.io"]

START_FLAGS ?= -d
# START_FLAGS ?= -d --remove-orphans

compose_file := $(CURDIR)/alpine.yml

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
	            alpine-dev /bin/sh

down: $(compose_file) stop
	podman-compose -f $< down
