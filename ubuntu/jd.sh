#!/bin/bash
#------------------------------------------------
# jd.sh:	allow j* attach process
# author: 	junjiemars@gmail.com
#------------------------------------------------
echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
