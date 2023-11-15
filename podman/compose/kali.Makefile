# kali Makefile
# https://hub.docker.com/u/kalilinux
# on Ubuntu: /etc/containers/registries.conf
# unqualified-search-registries = ["docker.io"]
# https://www.kali.org/docs/containers/official-kalilinux-docker-images/
# https://www.kali.org/docs/containers/using-kali-podman-images/

kali_image_name := kalilinux/kali-rolling
kali_container_name := kalilinux

run: exists
	podman container exec -it ${kali_container_name} /bin/bash

exists:
	podman container exists ${kali_container_name} \
		|| podman run --name ${kali_container_name} ${kali_image_name}

.PHONY: exists run
