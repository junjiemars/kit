alias ..1='cd ../'
alias ..2='cd ../../'
alias ..3='cd ../../../'
alias ..4='cd ../../../../'

if [ 'Darwin' = `uname -s` ]; then
  alias ls='ls -G'
  alias ll='ls -lh -G'
  alias l='ls -CF -G'
  alias tailf='tail -f'
else
  alias ls='ls --color=auto'
  alias ll='ls -lh --color=auto'
  alias l='ls -CF --color=auto'
fi
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

p_rlwrap=$(exist_p 'rlwrap')
if [[ 0 -eq p_rlwrap ]]; then
  p_racket=$(exist_p 'racket')
  if [[ 0 -eq p_racket ]]; then
    alias racket='rlwrap racket'
  fi
fi

p_emacs=$(exist_p 'emacs')
if [[ 0 -eq p_emacs ]]; then
  alias emacs='emacs -nw'
fi

p_vi=$(exist_p 'vi')
p_vim=$(exist_p 'vim')
if [[ 0 -eq p_vi ]] && [[ 0 -eq p_vim ]]; then
  if [[ 0 -ne $(diff_p `type -p vi` `type -p vim`) ]]; then
    alias vi=vim
  fi
fi
