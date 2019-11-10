# mysql Makefile
# https://hub.docker.com/_/mysql

START_FLAGS ?= -d --remove-orphans
REMOVE_FLAGS ?= --force

compose_file := mysql.yml

start: $(compose_file) stop
	docker-compose -f $<  up $(START_FLAGS)

stop: $(compose_file)
	docker-compose -f $<  stop

exec: start
	docker exec -e LINES=$(LINES) \
							-e COLUMNS=$(COLUMNS) \
							-e TERM=$(TERM) \
							-it -u u \
							mysql-dev /bin/bash

remove: $(compose_file) stop
	docker-compose -f $<  rm $(REMOVE_FLAGS)
