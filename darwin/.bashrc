## prompt
PS1="\u@\h:\w\$ "

## lang
export LANG=en_US.UTF-8

[ -r ~/.bash_vars ] && . ~/.bash_vars

## macports
PATH="${PATH:+$PATH:}/opt/local/bin:/opt/local/sbin"

[ -r ~/.bash_paths ] && . ~/.bash_paths
export PATH

[ -r ~/.bash_aliases ] && . ~/.bash_aliases
