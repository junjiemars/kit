# git-bash shortcut
# target: "<path-to-git-bash.exe>" -cd-to-home
# start in: %HOMEDRIVER%%HOMEPATH%

test -f $HOME/.bash_aliases && . $HOME/.bash_aliases 
test -f $HOME/.bash_vars && . $HOME/.bash_vars
test -f $HOME/.bash_paths && . $HOME/.bash_paths

#export LANG=en_US.UTF-8
