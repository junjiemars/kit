# xxl-job-admin Makefile
# https://hub.docker.com/_/xxl-job-admin
# on Ubuntu: /etc/containers/registries.conf
# unqualified-search-registries = ["docker.io"]

START_FLAGS ?= -d
# START_FLAGS ?= -d --remove-orphans

compose_file := $(CURDIR)/xxl-job-admin.yml
initdb_sql := $(CURDIR)/xxl-job-admin.sql

up: $(compose_file)
	podman-compose -f $< up $(START_FLAGS)

down: $(compose_file)
	podman-compose -f $< down

exec:
	podman exec -e LINES=$(LINES) \
							-e COLUMNS=$(COLUMNS) \
							-e TERM=$(TERM) \
							-it \
							xxl-job-admin-dev /bin/bash

start: $(compose_file)
	podman-compose -f $< start

down: $(compose_file)
	podman-compose -f $< down

initdb: $(initdb_sql)
	podman cp $< mysql-dev:/docker-entrypoint-initdb.d/init.sql

# https://raw.githubusercontent.com/xxl-job/xxl-job-admin/master/doc/db/tables_xxl_job.sql
