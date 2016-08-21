#------------------------------------------------
# target: git-bash env on Windows 
# author: junjiemars@gmail.com
# Note:
# > mintty.exe instead 
# > start in %USERPROFILE%
#------------------------------------------------


test -f ~/.bash_aliases && . ~/.bash_aliases 
test -f ~/.bash_vars && . ~/.bash_vars
test -f ~/.bash_paths && . ~/.bash_paths

# let MSYS_NT and user defined commands first
sort_path() {
  local sort='/usr/bin/sort'
  local car="`echo -n "$1" | \
    tr ':' '\n' | $sort | grep -v '^/c/' | tr '\n' ':' `"
  local cdr="`echo -n "$1" | \
    tr ':' '\n' | $sort | grep    '^/c/' | tr '\n' ':' `"
  local new="${car}${cdr}"
  echo -n "${new}" | sed -e 's#:$##'
}

export PATH=$(sort_path "$PATH")

# change code page to unicode
chcp.com 65001 &>/dev/null

export LANG=en_US.UTF-8

