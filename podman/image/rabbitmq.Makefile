# mysql Makefile
# https://hub.docker.com/_/rabbitmq/
# on Ubuntu: /etc/containers/registries.conf
# unqualified-search-registries = ["docker.io"]

# START_FLAGS ?= -d --remove-orphans

rabbitmq_node_name := rabbitmq-node-dev
rabbitmq_node_image := rabbitmq:3
rabbitmq_node_user ?= user
rabbitmq_node_password ?= password
rabbitmq_node_port ?= 8484

rabbitmq_mgr_name := rabbitmq-mgr-dev
rabbitmq_mgr_image := rabbitmq:3-management
rabbitmq_mgr_user ?= user
rabbitmq_mgr_password ?= password
rabbitmq_mgr_port ?= 8383

node_start:
	podman run --name $(rabbitmq_node_name)               \
    -e RABBITMQ_DEFAULT_USER=$(rabbitmq_node_user)      \
    -e RABBITMQ_DEFAULT_PASS=$(rabbitmq_node_password)  \
    -d $(rabbitmq_node_image)

node_stop:
	podman container stop $(rabbitmq_node_name)
	podman container rm -f $(rabbitmq_node_name)

node_inspect:
	podman container inspect $(rabbitmq_node_name)


mgr_start:
	podman run --name $(rabbitmq_mgr_name)              \
    -e RABBITMQ_DEFAULT_USER=$(rabbitmq_mgr_user)     \
    -e RABBITMQ_DEFAULT_PASS=$(rabbitmq_mgr_password) \
    -p $(rabbitmq_mgr_port):8080                      \
    -d $(rabbitmq_mgr_image)

mgr_stop:
	podman container stop $(rabbitmq_mgr_name)
	podman container rm -f $(rabbitmq_mgr_name)

mgr_inspect:
	podman container inspect $(rabbitmq_mgr_name)

# exec: start
# 	podman exec -e LINES=$(LINES) \
# 							-e COLUMNS=$(COLUMNS) \
# 							-e TERM=$(TERM) \
# 							-it -u u \
# 							mysql-dev /bin/bash

# remove: $(compose_file) stop
# 	podman-compose -f $< down
