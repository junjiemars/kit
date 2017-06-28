#!/bin/bash
#------------------------------------------------
# target: aliases on bash environment
# author: junjiemars@gmail.com
#------------------------------------------------

PLATFORM="`uname -s 2>/dev/null`"

alias ..1='cd ../'
alias ..2='cd ../../'
alias ..3='cd ../../../'
alias ..4='cd ../../../../'

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

function exist_p() {
    type -p ${1} &>/dev/null; echo $?
}

function diff_p() {
    diff ${1} ${2} &>/dev/null; echo $?
}

function diff_p() {
  diff ${1} ${2} >/dev/null 2>&1; echo $?
}

has_rlwrap=$(exist_p 'rlwrap')

case "${PLATFORM}" in
  Darwin)
    alias ls='ls -G'
    alias ll='ls -lh -G'
    alias l='ls -CF -G'
    alias tailf='tail -f'
    alias stat='stat -x'
    ;;
  *)
    alias ls='ls --color=auto'
    alias ll='ls -lh --color=auto'
    alias l='ls -CF --color=auto'
    ;;
esac

alias_racket() {
	if [ 0 -eq $has_rlwrap ]; then
		local p_racket=$(exist_p 'racket')
		if [ 0 -eq $p_racket ]; then
			local v
			IFS='.' read -a v <<< "`racket -v|sed 's/.*v\([0-9].[0-9]\).*/\1/g'`"
			if [ 67 -gt $(( ${v[0]}*10+${v[1]} )) ]; then
				alias racket='rlwrap racket'
			fi
		fi
	fi
}

alias_emacs() {
	local p_emacs=$(exist_p 'emacs')
	if [ 0 -eq $p_emacs ]; then
		alias emacs='emacs -nw'
	fi
}

alias_vi() {
	local p_vi=$(exist_p 'vi')
	local p_vim=$(exist_p 'vim')
	if [ 0 -eq $p_vi ] && [ 0 -eq $p_vim ]; then
	  if [ 0 -ne $(diff_p `type -p vi` `type -p vim`) ]; then
	    alias vi=vim
	  fi
	fi
}

alias_rlwrap_bin() {
	local bin="$1"
	local os="$2"
	local m=

	if [ -n "$os" ]; then
		case "$PLATFORM" in
			$os) m=0 ;;
			*) m=1 ;;
		esac
	else
		m=0
	fi

	if [ 0 -eq $m -a 0 -eq $has_rlwrap ]; then
		local p_bin=$(exist_p "$bin")
		if [ 0 -eq $p_bin ]; then
			alias $(echo "$bin")="rlwrap $bin"
		fi
	fi
}


alias_vi
alias_emacs
alias_racket
alias_rlwrap_bin lein
alias_rlwrap_bin sbcl
alias_rlwrap_bin ecl
alias_rlwrap_bin openssl
alias_rlwrap_bin jjs
alias_rlwrap_bin lldb Linux
