# kali Makefile
# https://hub.docker.com/u/kalilinux
# on Ubuntu: /etc/containers/registries.conf
# unqualified-search-registries = ["docker.io"]
# https://www.kali.org/docs/containers/official-kalilinux-docker-images/
# https://www.kali.org/docs/containers/using-kali-podman-images/

kali_image_name := kalilinux/kali-rolling

run:
	podman run -it ${kali_image_name}
