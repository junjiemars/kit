# Kit for Ubuntu

## Setup Desktop Environment
* Naming: setup-<application>-desktop.sh
* How to setup:
```sh
bash <(curl https://raw.githubusercontent.com/junjiemars/kit/master/ubuntu/setup-<application>-desktop.sh)
```

## Tips 

* Mount Windows' sharing directories
```sh
sudo mount -t cifs -o user=<win-user-name>//<host-name/ip>/<shared-dir> <mnt-dir>
```

* JDK tools can't attach to the target process
```sh
# temporarily
echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope

# or change ptrace_scope from 1 to 0 and then reboot.
sudo sed -i 's#^kernel.yama.ptrace_scope = 0#kernel.yama.ptrace_scope = 1#' /etc/sysctl.d/10-ptrace.conf
```
 


