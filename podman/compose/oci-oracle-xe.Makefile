# oraclexe Makefile
# https://hub.docker.com/junjiemars/oraclexe

START_FLAGS ?= -d --remove-orphans
REMOVE_FLAGS ?= --force

compose_file := oci-oracle-xe.yml

up: $(compose_file)
	podman-compose -f $< up -d

down: $(compose-file)
	podman-compose -f $(compose_file) down

start: $(compose_file)
	podman-compose -f $(compose_file) start $(start_flags)

stop: $(compose_file)
	podman-compose -f $(compose_file)  stop

exec: start
	podman exec -e LINES=$(LINES) \
				-e COLUMNS=$(COLUMNS) \
				-e TERM=$(TERM) \
				-it -u u \
				oraclexe-db /bin/bash

remove: $(compose_file) stop
	podman-compose -f $<  rm $(REMOVE_FLAGS)

.PHONY: build start stop exec remove clean push pull
