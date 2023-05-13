# mysql Makefile
# https://hub.docker.com/r/nacos/nacos-server
# on Ubuntu: /etc/containers/registries.conf
# unqualified-search-registries = ["docker.io"]

# START_FLAGS ?= -d --remove-orphans

nacos_name := nacos-quick
nacos_image := nacos/nacos-server:2.0.2

start:
	podman run --name nacos-quick -e MODE=standalone  \
    -p 8848:8848                                    \
    -d $(nacos_image)

stop:
	podman container stop $(nacos_name)

inspect:
	podman container inspect $(nacos_name)

# exec: start
# 	podman exec -e LINES=$(LINES) \
# 							-e COLUMNS=$(COLUMNS) \
# 							-e TERM=$(TERM) \
# 							-it -u u \
# 							mysql-dev /bin/bash

# remove: $(compose_file) stop
# 	podman-compose -f $< down
