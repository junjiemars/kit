# podman machine
# https://podman.io

PODMAN_MACHINE_NAME ?= podman-machine-default
PODMAN_CPUS ?= 2
PODMAN_MEMORY ?= 2048
PODMAN_DISK_SIZE ?= 64
PODMAN_LOG_LEVEL ?= info


init:
	podman machine inspect $(PODMAN_MACHINE_NAME) &>/dev/null \
    || podman machine init \
         --cpus=$(PODMAN_CPUS) \
         --memory=$(PODMAN_MEMORY) \
         --disk-size=$(PODMAN_DISK_SIZE) \
         --rootful=false \
         --log-level=$(PODMAN_LOG_LEVEL)
	# podman system connection default $(podman_machine_name)-root

start: init
	podman machine start $(PODMAN_MACHINE_NAME) --log-level=$(PODMAN_LOG_LEVEL)

stop:
	podman machine stop $(PODMAN_MACHINE_NAME) --log-level=$(PODMAN_LOG_LEVEL)

remove:
	podman machine rm $(PODMAN_MACHINE_NAME) --log-level=$(PODMAN_LOG_LEVEL)


.PHONY: init start stop remove
