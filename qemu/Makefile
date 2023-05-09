# env
images_dir := images

# fedora

fedora_image_name := Fedora-Cloud-Base-38-1.6.x86_64.qcow2
fedora_iso_name := Fedora-Workstation-Live-x86_64-38-1.6.iso

fedora_image_url := "https://download.fedoraproject.org/pub/fedora/linux/releases/38/Cloud/x86_64/images/$(fedora_image_name)"
fedora_iso_url := "https://download.fedoraproject.org/pub/fedora/linux/releases/38/Workstation/x86_64/iso/$(fedora_iso_name)"

fedora_image_file := $(images_dir)/$(fedora_image_name)
fedora_iso_file := $(images_dir)/$(fedora_iso_name)

fedora_x86_64: $(fedora_iso_file) $(fedora_create_image)
	qemu-system-x86_64                            \
   -m 2048                                      \
   -vga virtio                                  \
   -cdrom $(fedora_iso_file)                    \
   -drive file=$(fedora_image_file),if=virtio

fedora_create_image: $(fedora_image_file)
	qemu-img create -f qcow2 $< 10G

$(fedora_image_file):
	curl -L -S $(fedora_image_url) -o $@

$(fedora_iso_file):
	curl -L -S $(fedora_iso_url) -o $@
