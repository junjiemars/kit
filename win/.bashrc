#------------------------------------------------
# target: git-bash env on Windows 
# author: junjiemars@gmail.com
# Note:
# > mintty.exe instead 
# > start in %USERPROFILE%
#------------------------------------------------


test -f ~/.bash_vars && . ~/.bash_vars

test -f ~/.bash_paths && . ~/.bash_paths


# let MSYS_NT and user defined commands first
sort_path() {
	local awk='/bin/awk'
	local tr='/usr/bin/tr'
	local grep='/usr/bin/grep'
	local paths="$1"
	local opt_p="`/usr/bin/dirname $OPT_RUN`"
	local opt=
	local win_p="^/c/"

	opt="`echo -n "$paths" | $tr ':' '\n' | \
		$grep "$opt_p" | $tr '\n' ':' `"
  local car="`echo -n "$paths" | $tr ':' '\n' | \
		$grep -v "$opt_p" | $grep -v "$win_p" | $tr '\n' ':' `"
  local cdr="`echo -n "$paths" | $tr ':' '\n' | \
    $grep "$win_p" | $tr '\n' ':' `"
  local new="`echo -n "${car}${opt:+$opt }${cdr}" | \
		$awk '!xxx[$0]++' | sed -e 's#:$##' -e 's#:\  *\/#:\/#g' `"
  echo -n "${new}" 
}

export PATH=$(sort_path "$PATH")

test -f ~/.bash_aliases && . ~/.bash_aliases 

# change code page to unicode
chcp.com 65001 &>/dev/null

export LANG=en_US.UTF-8

