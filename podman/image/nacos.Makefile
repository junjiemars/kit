# nacos Makefile
# https://nacos.io/zh-cn/docs/what-is-nacos.html
# https://hub.docker.com/r/nacos/nacos-server
# on Ubuntu: /etc/containers/registries.conf
# unqualified-search-registries = ["docker.io"]

# START_FLAGS ?= -d --remove-orphans

nacos_name := nacos-dev
nacos_image := nacos/nacos-server:2.0.2
nacos_port ?= 8848

start:
	podman run --name $(nacos_name)               \
    -e MODE=standalone                          \
    -p $(nacos_port):8848                       \
    -d $(nacos_image)

stop:
	podman container stop $(nacos_name)
	podman container rm -f $(nacos_name)

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
