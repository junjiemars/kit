# redis Makefile
# https://hub.docker.com/_/redis
# on Ubuntu: /etc/containers/registries.conf
# unqualified-search-registries = ["docker.io"]

START_FLAGS ?= -d

compose_file := $(CURDIR)/redis.yml

start: $(compose_file) stop
	podman-compose -f $<  up $(START_FLAGS)

stop: $(compose_file)
	podman-compose -f $<  down

exec: start
	podman exec -e LINES=$(LINES) \
							-e COLUMNS=$(COLUMNS) \
							-e TERM=$(TERM) \
							-it -u u \
							redis-dev /bin/bash

remove: $(compose_file) stop
	podman-compose -f $< down
