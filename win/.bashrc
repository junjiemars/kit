# git-bash shortcut
# target: "<path-to-git-bash.exe>" -cd-to-home
# start in: %HOMEDRIVER%%HOMEPATH%

test -f ~/.bash_aliases && . ~/.bash_aliases 
test -f ~/.bash_vars && . ~/.bash_vars
test -f ~/.bash_paths && . ~/.bash_paths

export PATH

# change code page to unicode
chcp.com 65001 &>/dev/null

export LANG=en_US.UTF-8

