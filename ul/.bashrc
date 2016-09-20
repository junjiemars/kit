# minimal .bashrc, can be on Docker or EC2

test -n "$PS1" || PS1="\u@\h:\w\$ "

test -f $HOME/.bash_vars && . $HOME/.bash_vars

test -f $HOME/.bash_paths && . $HOME/.bash_paths
export PATH

test -f $HOME/.bash_aliases && . $HOME/.bash_aliases 

#export LANG=en_US.UTF-8
