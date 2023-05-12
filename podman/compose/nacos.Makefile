# mysql Makefile
# https://hub.docker.com/r/nacos/nacos-server
# on Ubuntu: /etc/containers/registries.conf
# unqualified-search-registries = ["docker.io"]

# START_FLAGS ?= -d --remove-orphans

nacos_container := nacos/nacos-server
nacos_version := 2.0.2

start:
	podman run --name nacos-quick -e MODE=standalone  \
    -p 8848:8848                                    \
    -d $(nacos_container):$(nacos_version)

stop:
	podman container stop $(nacos_container):$(nacos_version)

# exec: start
# 	podman exec -e LINES=$(LINES) \
# 							-e COLUMNS=$(COLUMNS) \
# 							-e TERM=$(TERM) \
# 							-it -u u \
# 							mysql-dev /bin/bash

# remove: $(compose_file) stop
# 	podman-compose -f $< down
