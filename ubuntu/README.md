# Kit for Ubuntu

* [Desktop](#desktop)
  * [Setup desktop shortcuts](#setup-desktop-shortcuts)
* [DNS](#dns)
* [Files](#files)
  * [Mount Windows directories](#mount-windows-directories)
* [Java](#java)
  * [Can not attach to the process](#can-not-attach-to-the-process)

## Desktop

### Setup desktop shortcuts
* Naming: setup-<application>-desktop.sh
* How to setup:
```sh
bash <(curl https://raw.githubusercontent.com/junjiemars/kit/master/ubuntu/setup-<application>-desktop.sh)
```

## DNS
Ubuntu 14.04+ adapt a useless dns component: [avahi-daemon](http://manpages.ubuntu.com/manpages/xenial/man8/avahi-daemon.8.html), 
[dnsmasq](http://www.thekelleys.org.uk/dnsmasq/doc.html) works fine and enough.

```sh
# copy dnsmasq.conf
sudo curl -sLo -C - https://raw.githubusercontent/junjiemars/kit/master/ubuntu/dnsmasq.conf

# uninstall avahi-daemon
sudo apt-get autoremove avahi-daemon

# restart dnsmsaq
sudo systemctl restart NetworkManager
```
## Files 

### Mount Windows directories
```sh
sudo mount -t cifs -o user=<win-user-name>//<host-name/ip>/<shared-dir> <mnt-dir>
```

## Java

### Can not attach to the process
```sh
# temporarily
echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope

# or change ptrace_scope from 1 to 0 and then reboot.
sudo sed -i 's#^kernel.yama.ptrace_scope = 0#kernel.yama.ptrace_scope = 1#' /etc/sysctl.d/10-ptrace.conf
```

