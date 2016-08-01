# git-bash shortcut
# target: "<path-to-git-bash.exe>" -cd-to-home
# start in: %HOMEDRIVER%%HOMEPATH%

test -f ~/.bash_aliases && . ~/.bash_aliases 
test -f ~/.bash_vars && . ~/.bash_vars
test -f ~/.bash_paths && . ~/.bash_paths


sort_path() {
  local car="`echo -n "$1"|tr ':' '\n'|sort|grep -v '^/c/'|tr '\n' ':'|sed -e 's#:*$##'`"
  local cdr="`echo -n "$1"|tr ':' '\n'|sort|grep    '^/c/'|tr '\n' ':'`|sed -e 's#:$##'"
  local new="${car}${cdr}"
  echo -n "${new}" | sed -e 's#:$##'
}

export PATH=$(sort_path "$PATH")

# change code page to unicode
chcp.com 65001 &>/dev/null

export LANG=en_US.UTF-8

