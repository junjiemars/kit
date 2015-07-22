sudo vi /etc/sysctl.d/10-ptrace.conf

kernel.yama.ptrace_scope = 1

from 1 to 0 and then reboot.


Or temporarily 
echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
