# mysql Makefile
# https://hub.docker.com/_/mysql

START_FLAGS ?= -d --remove-orphans

compose_file := mysql.yml

start: $(compose_file) stop
	podman-compose -f $<  up $(START_FLAGS)

stop: $(compose_file)
	podman-compose -f $<  down

exec: start
	podman exec -e LINES=$(LINES) \
							-e COLUMNS=$(COLUMNS) \
							-e TERM=$(TERM) \
							-it -u u \
							mysql-dev /bin/bash

remove: $(compose_file) stop
	podman-compose -f $< down
