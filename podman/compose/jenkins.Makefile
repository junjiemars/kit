# sonarqube Makefile
# https://hub.docker.com/_/jenkins
# on Ubuntu: /etc/containers/registries.conf
# unqualified-search-registries = ["docker.io"]

START_FLAGS ?= -d
# START_FLAGS ?= -d --remove-orphans

compose_file := $(CURDIR)/jenkins.yml

start: $(compose_file) stop
	podman-compose -f $< up $(START_FLAGS)

stop: $(compose_file)
	podman-compose -f $< stop

exec:
	podman exec -e LINES=$(LINES) \
							-e COLUMNS=$(COLUMNS) \
							-e TERM=$(TERM) \
							-it -u u \
							jenkins-dev /bin/bash

down: $(compose_file) stop
	podman-compose -f $< down
