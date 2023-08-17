# podman machine
# https://podman.io

PODMAN_MACHINE_NAME ?= podman-machine-default
PODMAN_CPUS ?= 2
PODMAN_MEMORY ?= 2048
PODMAN_DISK_SIZE ?= 64
PODMAN_LOG_LEVEL ?= info


init:
	podman machine init \
         --cpus=$(PODMAN_CPUS) \
         --memory=$(PODMAN_MEMORY) \
         --disk-size=$(PODMAN_DISK_SIZE) \
         --log-level=$(PODMAN_LOG_LEVEL)

start:
	podman machine start $(PODMAN_MACHINE_NAME) --log-level=$(PODMAN_LOG_LEVEL)

stop:
	podman machine stop $(PODMAN_MACHINE_NAME) --log-level=$(PODMAN_LOG_LEVEL)

remove:
	podman machine rm $(PODMAN_MACHINE_NAME) --log-level=$(PODMAN_LOG_LEVEL)


.PHONY: init start stop remove
