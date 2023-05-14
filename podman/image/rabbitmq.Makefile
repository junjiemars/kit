# rabbitmq Makefile
# https://www.rabbitmq.com/getstarted.html
# https://hub.docker.com/_/rabbitmq/
# on Ubuntu: /etc/containers/registries.conf
# unqualified-search-registries = ["docker.io"]

rabbitmq_name := rabbitmq-dev
rabbitmq_image := rabbitmq:3-management
rabbitmq_user ?= guest
rabbitmq_password ?= guest
rabbitmq_port ?= 5672

start:
	podman run --name $(rabbitmq_name)              \
    -e RABBITMQ_DEFAULT_USER=$(rabbitmq_user)     \
    -e RABBITMQ_DEFAULT_PASS=$(rabbitmq_password) \
    -p $(rabbitmq_port):5672                      \
    -p 15672:15672                                \
    -p 15692:15692                                \
    -d $(rabbitmq_image)

stop:
	podman container stop $(rabbitmq_name)
	podman container rm -f $(rabbitmq_name)

inspect:
	podman container inspect $(rabbitmq_name)

exec:
	podman exec -e LINES=$(LINES)                 \
							-e COLUMNS=$(COLUMNS)             \
							-e TERM=$(TERM)                   \
              -it                               \
							$(rabbitmq_name) /bin/bash


# EOF
