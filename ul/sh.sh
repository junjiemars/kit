#!/bin/sh
#------------------------------------------------
# target: shell env setup script
# author: Junjie Mars
#------------------------------------------------

HOME="${HOME%/}"
PH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"
# check basis commands
set -e
awk=`PATH=$PH command -v awk`
basename=`PATH=$PH command -v basename`
cat=`PATH=$PH command -v cat`
cp=`PATH=$PH command -v cp`
cut=`PATH=$PH command -v cut`
date=`PATH=$PH command -v date`
grep=`PATH=$PH command -v grep`
ps=`PATH=$PH command -v ps`
rm=`PATH=$PH command -v rm`
sed=`PATH=$PH command -v sed`
tr=`PATH=$PH command -v tr`
uname=`PATH=$PH command -v uname`
set +e

PLATFORM="`$uname -s 2>/dev/null`"
SH_ENV="https://raw.githubusercontent.com/junjiemars/kit/master/ul/sh.sh"
SH="${SH}"
if [ -z "$SH" ]; then
  if `$ps -cp $$ -o command='' &>/dev/null`; then
    SH="`$ps -cp $$ -o command='' | $tr -d '-'`"
  else
    SH="`$basename $SHELL`"
  fi
fi


# check the echo's "-n" option and "\c" capability
if echo "test\c" | $grep -q c; then
  echo_c=
  if echo -n test | $tr '\n' _ | $grep -q _; then
    echo_n=
  else
    echo_n=-n
  fi
else
  echo_n=
  echo_c='\c'
fi

# check the sed's "-i" option
echo -e "a\nb\nc" > .sed_i.test
if [ -f .sed_i.test ]; then
  if $sed -i'.off' -e'1d' .sed_i.test; then
    sed_i=-i
    $rm .sed_i.test.off
  fi
  $rm .sed_i.test
fi


save_as () {
  local f="$1"
  local ori="${f}.ori"
  local pre="${f}.pre"

  if [ -n "$f" -a -f "$f" ]; then
    if [ -n "$ori" -a -f "$ori" ]; then
      $cp $f $pre
    else
      $cp $f $ori
    fi
  fi
}

on_windows_nt () {
 case "$PLATFORM" in
   MSYS_NT*|MINGW*) return 0 ;;
   *) return 1 ;;
 esac
}

on_darwin () {
  case "$PLATFORM" in
    Darwin) return 0 ;;
    *) return 1 ;;
  esac
}

on_linux () {
  case "$PLATFORM" in
    Linux) return 0 ;;
    *) return 1 ;;
  esac
}

posix_path () {
  local p="$@"
  local v=
  if echo "$p" | $grep -q "^[a-zA-Z]:[\/\\].*$"; then
    if [ "abc" = `echo "ABC" | $sed -e 's#\([A-Z]*\)#\L\1#g'` ]; then
      v=$(echo "\\$p" | $sed -e 's#^\\\([a-zA-Z]\):[\/\\]#\\\L\1\\#')
    else
      local car="`echo $p | $cut -d':' -f1`"
      local cdr="`echo $p | $cut -d':' -f2`"
      if [ "$p" = "${car}:${cdr}" ]; then
        v=$(echo $car | $tr [:upper:] [:lower:])
        v=$(echo "\\${v}${cdr}" | $sed -e 's#^\\\([a-zA-Z]\):[\/\\]#\\\1\\#')
      else
        v=$(echo "\\$p" | $sed -e 's#^\\\([a-zA-Z]\):[\/\\]#\\\1\\#')
      fi
    fi;
  fi
  echo "$v" | $sed -e 's#\\#\/#g'
}

sort_path () {
  # Windows: let MSYS_NT and user defined commands first
  local paths="$@"
  local opt_p="`/usr/bin/dirname $OPT_RUN`"
  local win_p="^/c/"
  local opt=
  local ori=
  local win=
  local sorted=

  opt="`echo "$paths\c" | $tr ':' '\n' | $grep "$opt_p" | $tr '\n' ':' `"

  ori="`echo "$paths\c" | $tr ':' '\n' | $grep -v "$opt_p" | $grep -v "$win_p" | $tr '\n' ':' `"

  win="`echo "$paths\c" | $tr ':' '\n' | $grep "$win_p" | $tr '\n' ':' `"

  sorted="`echo "${ori}${opt:+$opt }${win}\c" | $awk '!xxx[$0]++' | $sed -e 's#:$##' -e 's#:\  *\/#:\/#g' `"

  echo $echo_n "${sorted}${echo_c}"
}


delete_tail_lines () {
  local h="$1"
  local lines="$2"
  local f="$3"
  local sed_opt_i="${sed_i}.pre"

  [ -f "$f" ] || return 1

  local line_no=`$grep -m1 -n "^${h}" $f | $cut -d':' -f1`
  echo $line_no | $grep -q '^[0-9][0-9]*$' || return 1

  if [ 0 -lt $line_no ]; then
    if [ "yes" = "$lines" ]; then
      $sed $sed_opt_i -e "$line_no,\$d" "$f"
    else
      $sed $sed_opt_i -e "${line_no}d" "$f"
    fi
  fi
}


where () {
  case "$SHELL" in
    */zsh)
      # override the zsh builtin
      whence -p $@
      ;;
    */bash)
      type -P $@
      ;;
    *)
      command -v $@
      ;;
  esac
}

exist_p () {
  where ${1} 1>/dev/null 2>&1
  echo $?
}

diff_p () {
  diff ${1} ${2} 1>/dev/null 2>&1
  echo $?
}


gen_dot_shell_profile () {
  local profile="$HOME/.${SH}_profile"
  case "$SH" in
    bash) profile="$HOME/.bash_profile" ;;
    zsh)  profile="$HOME/.zprofile" ;;
    sh)   profile="$HOME/.profile" ;;
  esac

  save_as "$profile"
  echo $echo_n "+ generate $profile ... $echo_c"
  $cat << END > "$profile"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# file: $profile
# target: call .${SH}rc
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
`if [ -f "${profile}.ori" ]; then
  echo "# origin backup: ${profile}.ori"
fi`
#------------------------------------------------

`if [ "zsh" = "$SH" ]; then
   echo "# test -r \\$HOME/.${SH}rc && . \\$HOME/.${SH}r"c
elif [ "bash" = "$SH" ]; then
   echo "test -r \\$HOME/.\${SH}rc && . \\$HOME/.\${SH}r"c
elif [ "sh" = "$SH" ]; then
   echo "test -r \\$HOME/.\${SH}rc && . \\$HOME/.\${SH}r"c
fi`

# eof
END
  if [ 0 -eq $? ]; then
    echo "yes"
  else
    echo "no"
  fi
}

gen_dot_shell_logout () {
  local logout="$HOME/.${SH}_logout"
  if [ "zsh" = "$SH" ]; then
    logout="$HOME/.zlogout"
  fi
  save_as "$logout"
  echo $echo_n "+ generate $logout ... $echo_c"
  $cat << END > "$logout"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# file: $logout
# target: be called when logout
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
`if [ -f "${logout}.ori" ]; then
  echo "# origin backup: ${logout}.ori"
fi`
#------------------------------------------------

# `$basename ${logout}`: executed by ${SH}(1) when login shell exits.
# when leaving the console clear the screen to increase privacy

if [ "\$SHLVL" -eq 1 ]; then
`if on_darwin; then
   echo "  clear"
elif [ -x /usr/bin/clear_console ]; then
   echo "  /usr/bin/clear_console -q"
else
   echo "  clear"
fi`
fi

# eof
END
  if [ 0 -eq $? ]; then
    echo "yes"
  else
    echo "no"
  fi
}

gen_dot_shell_rc () {
  local rc="$HOME/.${SH}rc"
  save_as "$rc"
  if [ ! -f "$rc" ]; then
    echo $echo_n "+ generate $rc ... $echo_c"
    $cat << END > "$rc"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# file: $rc
# target: .${SH}rc default
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
`if [ -f "${rc}.ori" ]; then
  echo "# origin backup: ${rc}.ori"
fi`
#------------------------------------------------

END
  else
    echo $echo_n "+ append $rc ... $echo_c"
    delete_tail_lines "\(# call .${SH}_init\)\|\(#----Nore ${SH}----\)" "yes" "$HOME/.${SH}rc"
  fi # end of ! -f "$rc"

  echo "#----Nore ${SH}----" >> "$HOME/.${SH}rc"
  $cat << END >> "$HOME/.${SH}rc"

# o_check_prompt_env=no
# o_check_lang_env=no
`if on_darwin; then
  echo "# o_check_macports_env=no"
  echo "# o_check_llvm_env=no"
fi`
# o_check_completion_env=no
# o_check_racket_env=no
# o_check_java_env=no
# o_check_nvm_env=no
# o_check_kube_env=no
# o_check_bun_env=no
# o_check_rust_env=no
`if [ "zsh" = "$SH" ]; then
  echo "# o_check_ohmyzsh_env=no"
fi`
# o_export_path_env=no
# o_export_libpath_env=no

test -f \$HOME/.${SH}_init    && . \$HOME/.${SH}_init
test -f \$HOME/.${SH}_vars    && . \$HOME/.${SH}_vars
test -f \$HOME/.${SH}_paths   && . \$HOME/.${SH}_paths
test -f \$HOME/.${SH}_utils   && . \$HOME/.${SH}_utils
test -f \$HOME/.${SH}_aliases && . \$HOME/.${SH}_aliases

# eof
END

  if [ 0 -eq $? ]; then
    echo "yes"
  else
    echo "no"
  fi
}

gen_dot_shell_init () {
  local init="$HOME/.${SH}_init"
  save_as "$init"
  echo $echo_n "+ generate $init ... $echo_c"
  $cat << END > "$init"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# file: $init
# target: initialize .zsh_* scripts
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
`if [ -f "${init}.ori" ]; then
  echo "# origin backup: ${init}.ori"
fi`
#------------------------------------------------

SHELL=`if [ "$SH" = "zsh" ]; then
  whence -p zsh
elif [ "$SH" = "bash" ]; then
  type -P bash
else
  command -v $SH
fi`

`
declare -f where
`


inside_docker_p () {
  [ ".\$INSIDE_DOCKER" = ".1" ] && return 0
  [ -f /proc/1/cgroup ] || return 1
  if \`cat /proc/1/cgroup | grep '/docker/' >/dev/null\`; then
    export INSIDE_DOCKER=1
  else
    export INSIDE_DOCKER=0
  fi
}

inside_emacs_p () {
  test -n "\$INSIDE_EMACS"
}


`
declare -f delete_tail_lines
`

pretty_prompt_command () {
  local o="\${PROMPT_COMMAND}"
  local pc1=''

  if test -n "\${o}"; then
    if \`inside_docker_p\` || \`inside_emacs_p\`; then
      echo "\$pc1"
      return
    fi
  fi
  echo "\$o"
}

pretty_term () {
  local o="\$TERM"
  local t="xterm"

  if [ -z "\$o" ]; then
    echo "\$t"
    return
  fi

  if [ "dumb" = "\$o" ]; then
    if \`inside_emacs_p\`; then
      echo "\$o"
    else
      echo "\$t"
    fi
  else
    echo "\$o"
  fi
}

# check prompt env
if [ "\$o_check_prompt_env" = "yes" ]; then
  PROMPT_COMMAND="\$(pretty_prompt_command)"
  if [ -z "\$PROMPT_COMMAND" ]; then
    unset PROMPT_COMMAND
  else
    export PROMPT_COMMAND
  fi

`if [ "zsh" = "$SH" ]; then
  echo "  PS1=\"%n@%m %1~ %#\""
elif [ "bash" = "$SH" ]; then
  echo "  PS1=\\"\\u@\\h \\W \\$\\""
else
  echo "  PS1=\\"\\$LOGNAME@\\\`uname -n | cut -d '.' -f1\\\` \$\\""
fi`
  export PS1="\${PS1% } "

  TERM="\$(pretty_term)"
  export TERM
fi

# check lang env
if [ "\$o_check_lang_env" = "yes" ]; then
`if on_windows_nt; then
    echo "  # change code page to unicode"
    echo "  chcp.com 65001 &>/dev/null"
    echo "  export LANG=en_US.UTF-8"
  else
    echo "  if test -z \"\\$LANG\"; then"
    echo "    LANG=en_US.UTF-8"
    echo "  fi"
    echo "  export LANG=\\$LANG"
    if on_linux; then
      echo "  # fix set locale failed:"
      echo "  # sudo localedef -i en_US -f UTF-8 en_US.UTF-8"
    fi
fi`
fi


# eof
END
  if [ 0 -eq $? ]; then
    echo "yes"
  else
    echo "no"
  fi
}

gen_dot_shell_aliases () {
  local aliases="$HOME/.${SH}_aliases"
  save_as "$aliases"
  echo $echo_n "+ generate $aliases ... $echo_c"
  $cat << END > "$aliases"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# target: $aliases
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
`if [ -f "${aliases}.ori" ]; then
  echo "# origin backup: ${aliases}.ori"
fi`
#------------------------------------------------


alias ..1='cd ../'
alias ..2='cd ../../'
alias ..3='cd ../../../'
alias ..4='cd ../../../../'

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

`
if on_darwin; then
  echo "alias ls='ls -G'"
  echo "alias ll='ls -lh -G'"
  echo "alias l='ls -CF -G'"
  echo "alias tailf='tail -f'"
  echo "# alias stat='stat -x'"
else
  echo "alias ls='ls --color=auto'"
  echo "alias ll='ls -lh --color=auto'"
  echo "alias l='ls -CF --color=auto'"
fi
`

`
declare -f exist_p
`

`
declare -f diff_p
`

alias_racket () {
  local p_racket=\$(exist_p 'racket')
  if [ 0 -eq \$p_racket ]; then
    alias racket='rlwrap racket'
  fi
}

alias_emacs () {
  local p_emacs=\$(exist_p 'emacs')
  if [ 0 -eq \$p_emacs ]; then
    alias emacs='emacs -nw'
  fi
}

alias_vi () {
  local p_vi=\$(exist_p 'vi')
  local p_vim=\$(exist_p 'vim')
  if [ 0 -eq \$p_vi ] && [ 0 -eq \$p_vim ]; then
    if [ 0 -ne \$(diff_p \`where vi\` \`where vim\`) ]; then
      alias vi=vim
    fi
  fi
}

alias_python () {
  local p_p3=\$(exist_p 'python3')
  local p_pip3=\$(exist_p 'pip3')
  if [ 0 -eq \$p_p3 ]; then
    alias python=python3
  fi
  if [ 0 -eq \$p_pip3 ]; then
    alias pip=pip3
  fi
}

alias_rlwrap_bin () {
  local bin="\$1"
  if [ 0 -eq \$(exist_p "\$bin") ]; then
    alias \$(echo "\$bin")="rlwrap \$bin"
  fi
}

alias_vi
alias_emacs
# alias_racket
`if on_linux && [ "$SH" = "bash" ]; then
   echo "# bsd ps style"
   echo "alias ps='ps w'"
fi`
alias_python

if [ 0 -eq \$(exist_p rlwrap) ]; then
  alias_rlwrap_bin ecl
  alias_rlwrap_bin openssl
fi


# eof
END
  if [ 0 -eq $? ]; then
    echo "yes"
  else
    echo "no"
  fi
}

gen_dot_shell_utils () {
  local utils="$HOME/.${SH}_utils"
  save_as "$utils"
  echo $echo_n "+ generate $utils ... $echo_c"
  $cat << END > "$utils"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# target: $utils
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
`if [ -f "${utils}.ori" ]; then
  echo "# origin backup: ${utils}.ori"
fi`
#------------------------------------------------

date_from_epoch ()
{
`if on_linux; then
  echo "  if [ \\\$# -eq 0 ]; then"
  echo "    date -d@0 -u"
  echo "  else"
  echo "    date -d@\\\$@"
  echo "  fi"
elif on_darwin; then
  echo "  if [ \\\$# -eq 0 ]; then"
  echo "    date -r0 -u"
  echo "  else"
  echo "    date -r\\\$@"
  echo "  fi"
else
  echo "  # nop"
  echo "  :"
fi`
}

os_release ()
{
`if on_darwin; then
  echo "  sw_vers"
elif on_linux; then
  echo "  if [ -f \\"/etc/os-release\\" ]; then"
  echo "    cat /etc/os-release"
  echo "  fi"
elif on_windows_nt; then
  echo "  systeminfo | grep '^OS Version'"
else
  echo "  # nop"
  echo "  :"
fi`
}

random_base64 ()
{
`if where dd &>/dev/null && test -r /dev/random; then
   echo "  local n=\\"\\\${1:-8}\\""
   if on_darwin; then
      echo "  dd if=/dev/random bs=\\\$n | head -c\\\$n | base64 -b\\\$n | head -n1 | xargs"
    else
      echo "  dd if=/dev/random bs=\\\$n count=1 status=none | head -c\\\$n | base64 | head -c\\\$n | xargs"
   fi
else
   echo "  # nop"
   echo "  :"
fi`
}

outbound_ip ()
{
  local u="https://checkip.dns.he.net"
  local v="\$1"
  if \`where curl &>/dev/null\`; then
    case "\$v" in
      -6) v="-6" ;;
      *)  v="-4" ;;
    esac
    curl \$v -sL "\$u"|grep 'Your IP address'|sed -E 's/Your.*: ([.:0-9a-z]+).*/\1/'
  else
    echo "\$u"
  fi
}

`if on_linux && snap --version &>/dev/null; then
   echo "snap_remove_disabled ()"
   echo "{"
   echo "  LANG=C snap list --all | awk '/disabled/{print \\\$1, \\\$3}' |"
   echo "    while read snapname revision; do"
   echo "      sudo snap remove \\"\\\$snapname\\" --revision=\\"\\\$revision\\""
   echo "    done"
   echo "}"
   echo ""
   echo "snapd_disable ()"
   echo "{"
   echo "  sudo systemctl stop snapd"
   echo "  sudo systemctl disable snapd"
   echo "}"
   echo ""

   echo "snapd_enable ()"
   echo "{"
   echo "  sudo systemctl enable snapd"
   echo "  sudo systemctl restart snapd"
   echo "}"
fi`

`if on_linux && unzip -h &>/dev/null; then
   echo "unzip_zhcn ()"
   echo "{"
   echo "  unzip -Ogb2312 \\\$@"
   echo "}"
fi`

`if on_darwin; then
   echo "find_unwanted ()"
   echo "{"
   echo "   local what=\"\\$@\""
   echo "   local app_dir=\"/Applications\""
   echo "   local sup_dir=\"~/Library/Application Support\""
   echo "   local str_dir=\"~/Library/Saved Application State\""
   echo "   local cch_dir1=\"/Library/Caches\""
   echo "   local cch_dir2=\"~/Library/Caches\""
   echo "   local prf_dir=\"~/Library/Preferences\""
   echo "   local plg_dir=\"~/Library/Internet Plug-Ins\""
   echo "   local crs_dir=\"~/Library/Application Support/CrashReporter\""
   echo "   local lib_dir1=\"/Library\""
   echo "   local lib_dir2=\"~/Library\""
   echo "   echo \"check \\$app_dir ...\""
   echo "   echo \"check \\$sup_dir ...\""
   echo "   echo \"check \\$str_dir ...\""
   echo "   echo \"check \\$cch_dir2 ...\""
   echo "   echo \"check \\$cch_dir1 ...\""
   echo "   echo \"check \\$prf_dir ...\""
   echo "   echo \"check \\$plg_dir ...\""
   echo "   echo \"check \\$crs_dir ...\""
   echo "   echo \"check \\$lib_dir2 ...\""
   echo "   echo \"check \\$lib_dir1 ...\""
   echo "}"
fi`

# eof
END
  if [ 0 -eq $? ]; then
    echo "yes"
  else
    echo "no"
  fi
}


gen_dot_shell_vars () {
  local vars="$HOME/.${SH}_vars"
  save_as "$vars"
  echo $echo_n "+ generate $vars ... $echo_c"
  $cat << END > "$vars"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# target: $vars
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
`if [ -f "${vars}.ori" ]; then
  echo "# origin backup: ${vars}.ori"
fi`
#------------------------------------------------

`
if on_windows_nt; then
  echo "choose_prefix () {"
  echo "  if [ -d \"/d/\" ]; then"
  echo "    [ -d \"/d/opt\" ] || mkdir -p \"/d/opt\""
  echo "    echo \"/d/opt\""
  echo "  else"
  echo "    [ -d \"/c/opt\" ] || mkdir -p \"/c/opt\""
  echo "    echo \"/c/opt\""
  echo "  fi"
  echo "}"
else
  echo "choose_prefix () {"
  echo "  echo \"/opt\""
  echo "}"
fi
`

OPT_RUN="\${OPT_RUN:-\$(choose_prefix)/run}"
OPT_OPEN="\${OPT_OPEN:-\$(choose_prefix)/open}"

[ -d "\${OPT_RUN}" ]  && export OPT_RUN=\${OPT_RUN}
[ -d "\${OPT_OPEN}" ] && export OPT_OPEN=\${OPT_OPEN}


# https://github.com/oven-sh/bun
check_bun_env () {
  local d="\$HOME/.bun"
  if [ -x "\${d}/bin/bun" ]; then
    BUN_DIR="\${d}/bin"
    return 0
  fi
  return 1
}

# $SH completion
check_completion_env () {
`if [ "bash" = "$SH" ]; then
   echo "  local c=\"/etc/profile.d/bash_completion.sh\""
   echo "  if [ -f \"\\\$c\" ]; then"
   echo "    source \"\\\$c\""
   echo "  fi"
elif [ "zsh" = "$SH" ]; then
   echo "  autoload -Uz compinit && compinit"
else
   echo "  # nop"
   echo ":"
fi`
}

# https://openjdk.java.net
check_java_env () {
  local javac="\${JAVA_HOME%/}/bin/javac"
  local java_home=
  if test -x "\${javac}" && \${javac} -version &>/dev/null; then
    return 0
  else
    unset JAVA_HOME
  fi
`if on_darwin; then
  echo "  java_home='/usr/libexec/java_home'"
  echo "  if [ -L \\"\\\$java_home\\" ]; then"
  echo "    JAVA_HOME=\\"\\\$(\\\${java_home} 2>/dev/null)\\""
  echo "    javac=\\"\\\${JAVA_HOME%/}/bin/javac\\""
  echo "    if [ -x \\"\\\${javac}\\" ]; then"
  echo "      return 0"
  echo "    fi"
  echo "  fi"
elif on_linux; then
  echo "  javac=\\"\\\$(where javac 2>/dev/null)\\""
  echo "  if [ -n \\"\\\${javac}\\" -a -x \\"\\\$javac\\" ]; then"
  echo "    java_home=\\"\\\$(readlink -f \\"\\\${javac}\\" | sed 's:/bin/javac::')\\""
  echo "    JAVA_HOME=\\"\\\${java_home}\\""
  echo "    return 0"
  echo "  fi"
elif on_windows_nt; then
  echo "  # nop"
fi`
  return 1
}

# https://kubernetes.io/docs/reference/kubectl/overview/
check_kube_env () {
  local d="\${HOME}/.kube"
  local s="\${d}/kube-${SH}.sh"
  local c="\${d}/\${1}"
  local r="\${d}/.recent"
  if \`where kubectl &>/dev/null\`; then
    if [ ! -f "\$s" ]; then
      [ -d "\$d" ] || mkdir -p "\$d"
      SHELL=$SHELL kubectl completion ${SH} >"\$s"
    fi
    if [ -r "\$s" ]; then
      check_completion_env && . "\$s"
    fi
    if [ -f "\$c" ]; then
      export KUBECONFIG="\$c"
      cp "\$c" "\$r"
    elif [ -f "\$r" ]; then
      export KUBECONFIG="\$r"
    fi
    if \`inside_emacs_p\` && \`where emacsclient &>/dev/null\`; then
      export KUBE_EDITOR=emacsclient
    fi
    return 0
  else
    echo 'https://kubernetes.io/docs/tasks/tools/#kubectl'
  fi
  return 1
}

# https://github.com/nvm-sh/nvm
check_nvm_env () {
  local d="\$HOME/.nvm"
  if [ -s "\${d}/nvm.sh" ]; then
    NVM_DIR="\$d"
    . "\${d}/nvm.sh"
    [ -s "\${d}/bash_completion" ] && . "\${d}/bash_completion"
    return 0
  fi
  return 1
}

# https://www.python.org
check_python_env () {
  if where python; then
    echo "\`python --version\`"
  fi
  if where virtualenv; then
    echo "\`virtualenv --version\`"
  else
    echo "https://virtualenv.pypa.io"
  fi
  if where pip; then
    echo "\`pip --version\`"
    echo "\`pip config list\`"
    echo "mirrors:"
    echo "https://pypi.org/simple"
    echo "https://pypi.tuna.tsinghua.edu.cn/simple"
    echo "https://mirrors.aliyun.com/pypi/simple"
  else
    echo "https://pypi.org/project/pip/"
  fi
}

# https://podman.io
check_podman_env () {
  local d="\${HOME}/.config"
  local r="\${d}/registries.conf"
  local c="\$1"
  case "\$c" in
    mirror)
      echo "[registries.search]\nregistries = ['registry.access.redhat.com','registry.redhat.io','docker.io']" >> "\$r"
      ;;
    *)
      where podman; echo "\$d"
      ;;
  esac
}

# https://racket-lang.org
check_racket_env () {
`if on_darwin; then
   if [ "zsh" = "$SH" ]; then
      echo "  setopt +o nomatch &>/dev/null"
   fi
   echo "  if \\\`ls -ldr /Applications/Racket* &>/dev/null\\\`; then"
   echo "    RACKET_HOME=\"\\\`ls -ldr /Applications/Racket* | head -n1 | sed -e 's_.*\\\(/Applications/Racket\\ v[0-9][0-9]*\\.[0-9][0-9]*\\\).*_\\1_g'\\\`\""
   echo "  fi"
   if [ "zsh" = "$SH" ]; then
     echo "  setopt -o nomatch &>/dev/null"
   fi
else
   echo "  # nop"
   echo "  :"
fi`
}

# https://www.rust-lang.org/
check_rust_env () {
  local cargo_dir="\${HOME}/.cargo"
  local b="\${cargo_dir}/bin"
  if [ -d "\$b" ] && \`\${b}/rustc --version &>/dev/null\` && \`\${b}/cargo --version &>/dev/null\`; then
    export CARGO_HOME="\${cargo_dir}"
    return 0
  else
    unset CARGO_HOME
  fi
  return 1
}

check_rust_src_env () {
  local force="\$1"
  local rc="\`rustc --print sysroot 2>/dev/null\`"
  local hash="\`rustc -vV|grep -e '^commit-hash'|sed -e 's#commit-hash: \\(.*\\)#\\1#g' 2>/dev/null\`"
  local etc="\${rc}/lib/rustlib/src/rust/src/etc"
  local tag="\${etc}/ctags.rust"
  local tag_src="https://raw.githubusercontent.com/rust-lang/rust/master/src/etc/ctags.rust"
  local gdb="\${rc}/lib/rustlib/etc/gdb_load_rust_pretty_printers.py"
  local lldb="\${rc}/lib/rustlib/etc/lldb_commands"
  local from="/rustc/\${hash}"
  local src="\${rc}/lib/rustlib/src/rust"
  if [ -n "\$rc" ] && [ -d "\$rc" ]; then
    if ! [ -f "\$tag" ]; then
      mkdir -p "\${etc}"
      curl --proto '=https' --tlsv1.2 -sSf "\$tag_src" -o "\$tag"
    fi
    if [ -n "\$hash" ] && [ -d "\$src" ]; then
      if [ -f "\$gdb" ]; then
         if [ "\$force" = "renew" ]; then
           sed ${sed_i}.b1 "/set substitute-path/"d \$gdb
         fi
         if ! \`grep 'set substitute-path' \$gdb &>/dev/null\`; then
           cp \$gdb \${gdb}.b0
           echo ${echo_n} "gdb.execute('set substitute-path \$from \$src')" >> \$gdb
         fi
      fi
      if [ -f "\$lldb" ]; then
        if [ "\$force" = "renew" ]; then
          sed ${sed_i}.b1 "/settings set target\.source-map/"d \$lldb
        fi
        if ! \`grep 'settings set target.source-map' \$lldb &>/dev/null\`; then
          cp \$lldb \${lldb}.b0
          echo ${echo_n} "settings set target.source-map \$from \$src" >> \$lldb
        fi
      fi
    fi
  else
    echo "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
  fi
}


`if [ "zsh" = "$SH" ]; then
  echo "# https://ohmyz.sh"
  echo "check_ohmyzsh_env () {"
  echo "  local d=\"\\${HOME}/.oh-my-zsh\""
  echo "  local m=\"\\${HOME}/.zsh_ohmyzsh\""
  echo "  if [ -f \"\\${d}/oh-my-zsh.sh\" ]; then"
  echo "    if [ ! -f "\\$m" ]; then"
  echo "cat << END > \"\\$m\""
  echo "export ZSH=\"\\$d\""
  echo "DISABLE_AUTO_UPDATE=true"
  echo "ZSH_THEME=\"robbyrussell\""
  echo "#plugins=(git z nvm kubectl)"
  echo "source \"\\\\\\${ZSH}/oh-my-zsh.sh\""
  echo "END"
  echo "    fi"
  echo "    . \"\\$m\""
  echo "    return \\$?"
  echo "  fi"
  echo "  return 1"
  echo "}"
fi`

if [ "\$o_check_completion_env" = "yes" ]; then
  check_completion_env
fi

if [ "\$o_check_racket_env" = "yes" ]; then
  check_racket_env
fi

if [ "\$o_check_java_env" = "yes" ]; then
  check_java_env
fi

if [ "\$o_check_nvm_env" = "yes" ]; then
  check_nvm_env
fi

if [ "\$o_check_kube_env" = "yes" ]; then
  check_kube_env
fi

if [ "\$o_check_bun_env" = "yes" ]; then
  check_bun_env
fi

if [ "\$o_check_rust_env" = "yes" ]; then
  check_rust_env
fi


`if [ "zsh" = "$SH" ]; then
  echo "if [ \\"\\$o_check_ohmyzsh_env\" = \\"yes\\" ]; then"
  echo "  check_ohmyzsh_env"
  echo "fi"
fi`

# declare vars

# eof
END
  if [ 0 -eq $? ]; then
    echo "yes"
  else
    echo "no"
  fi
}

gen_dot_shell_paths () {
  local paths="$HOME/.${SH}_paths"
  save_as "$paths"
  echo $echo_n "+ generate $paths ... $echo_c"
  $cat << END > "$paths"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# target: $paths
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
`if [ -f "${paths}.ori" ]; then
  echo "# origin backup: ${paths}.ori"
fi`
#------------------------------------------------

append_path () {
  local new="\$1"
  local paths="\${@:2}"
  if [ -n "\$new" -a -d "\$new" ]; then
    case ":${PATH}:" in
      *:"$new":*)
        ;;
      *)
        echo "\${paths:+\$paths:}\$new"
        ;;
    esac
  else
    echo "\${paths}"
  fi
}

uniq_path () {
  local paths="\$@"
  paths=\`echo "\$paths" | $tr ':' '\n' | $awk '!a[\$0]++'\`
  paths=\`echo "\$paths" | $tr '\n' ':' | $sed -e 's_:\$__g'\`
  echo "\$paths"
}

`
declare -f posix_path
`

`
if on_windows_nt; then
  declare -f sort_path
fi
`

set_bin_paths () {
  local paths=(
    '/usr/local/bin'
    '/usr/local/sbin'
    '/usr/bin'
    '/usr/sbin'
    '/bin'
    '/sbin'
  )

  for d in "\${paths}"; do
    PATH="\`append_path \${d} \$PATH\`"
  done
}


# chain basis \${OPT_RUN}/{bin,sbin} paths
if [ -d "\${OPT_RUN}" ]; then
  PATH="\`append_path \${OPT_RUN}/bin \${PATH}\`"
  PATH="\`append_path \${OPT_RUN}/sbin \${PATH}\`"
`
  if on_linux; then
    echo "  LD_LIBRARY_PATH=\\"\\\$(append_path \\\${OPT_RUN}/lib \\\${LD_LIBRARY_PATH})\\""
  elif on_darwin; then
    echo "  DYLD_LIBRARY_PATH=\\"\\\$(append_path \\\${OPT_RUN}/lib \\\${DYLD_LIBRARY_PATH})\\""
  fi
`
fi

`if on_darwin; then
  echo "check_macports_env () {"
  echo "  if [ -x \"/opt/local/bin/port\" ]; then"
  echo "    if [ -d \"/opt/local/sbin\" ]; then"
  echo "      PATH=\"/opt/local/sbin\\${PATH:+:\\${PATH}}\""
  echo "    fi"
  echo "    PATH=\"/opt/local/bin\\${PATH:+:\\${PATH}}\""
  echo "    if [ -d \"/opt/local/lib\" ]; then"
  echo "      DYLD_LIBRARY_PATH=\"/opt/local/lib\\${DYLD_LIBRARY_PATH:+:\\${DYLD_LIBRARY_PATH}}\""
  echo "    fi"
  echo "  fi"
  echo "}"
  echo ""
  echo "check_llvm_env () {"
  echo "  local p=\"/opt/local/bin/port\""
  echo "  local l=\"/opt/local/libexec\""
  echo "  local d=\"\\${l}/llvm/bin\""
  echo "  if [ -x \"\\$p\" -a -d \"\\$l\" ]; then"
  echo "    if [ ! -d \"\\$d\" ]; then"
  echo "      ls -d \\${d}*"
  echo "    else"
  echo "      PATH=\"\\\`append_path \\${d} \\$PATH\\\`\""
  echo "    fi"
  echo "  fi"
  echo "}"
fi`

`if on_darwin; then
  echo "# macports"
  echo "if [ \"\\$o_check_macports_env\" = \"yes\" ]; then"
  echo "  check_macports_env"
  echo "fi"

  echo "# llvm"
  echo "if [ \"\\$o_check_llvm_env\" = \"yes\" ]; then"
  echo "  check_llvm_env"
  echo "fi"
fi`

# racket home
if [ "\$o_check_racket_env" = "yes" -a -n "\$RACKET_HOME" ]; then
`if on_windows_nt; then
  echo "  RACKET_HOME=\\$(posix_path \"\\$RACKET_HOME\")"
fi`
  PATH="\`append_path \"\$RACKET_HOME/bin\" \$PATH\`"
fi
unset RACKET_HOME

# java home
if [ "\$o_check_java_env" = "yes" -a -n "\$JAVA_HOME" ]; then
`if on_windows_nt; then
  echo "  JAVA_HOME=\\$(posix_path \"\\${JAVA_HOME}\")"
fi`
  PATH="\`append_path \"\${JAVA_HOME}\" \$PATH\`"
  PATH="\`append_path \"\${JAVA_HOME}/bin\" \$PATH\`"
fi

# nvm home
if [ "\$o_check_nvm_env" = "yes" -a -n "\$NVM_DIR" ]; then
  PATH="\`append_path \"\${NVM_DIR}\" \$PATH\`"
fi

# bun home
if [ "\$o_check_bun_env" = "yes" -a -n "\$BUN_DIR" ]; then
  PATH="\`append_path \"\${BUN_DIR}\" \$PATH\`"
fi

# rust home: cargo, rustc
if [ "\$o_check_rust_env" = "yes" -a -n "\$CARGO_HOME" ]; then
  PATH="\`append_path \"\${CARGO_HOME}/bin\" \$PATH\`"
fi


PATH="\$(uniq_path \${PATH})"
`if on_windows_nt; then
  echo "PATH=\\"\\\$(sort_path \\\${PATH})\\""
elif on_linux; then
  echo "LD_LIBRARY_PATH=\\"\\\$(uniq_path \\\${LD_LIBRARY_PATH})\\""
elif on_darwin; then
  echo "DYLD_LIBRARY_PATH=\\"\\\$(uniq_path \\\${DYLD_LIBRARY_PATH})\\""
fi`

# export path env
if [ "\$o_export_path_env" = "yes" ]; then
  set_bin_paths
  export PATH
fi

# export libpath env
if [ "\$o_export_libpath_env" = "yes" ]; then
`if on_linux; then
  echo "  export LD_LIBRARY_PATH"
elif on_darwin; then
  echo "  export DYLD_LIBRARY_PATH"
else
  echo "  : #void"
fi`
fi

# eof
END
  if [ 0 -eq $? ]; then
    echo "yes"
  else
    echo "no"
  fi
}

gen_dot_vimrc () {
  local rc="$HOME/.vimrc"
  echo $echo_n "+ generate $rc ... $echo_c"
  $cat << END > "$rc"
"------------------------------------------------
" target: $rc
" author: Junjie Mars
" generated by:
"   $SH <($SH_ENV)
`if [ -f "${rc}.ori" ]; then
  echo "\\" origin backup: ${rc}.ori"
fi`
"------------------------------------------------

" nocompatible
"set nocompatible

" indent uses 2 characters
set shiftwidth=2

" tabs are 2 characters
set tabstop=2

" expand tab
"if has("autocmd")
"   set expandtab
"   autocmd FileType make set noexpandtab
"   autocmd FileType python set noexpandtab
"endif

" history
set history=50

" 1000 undo levels
set undolevels=1000

" encoding
"set encoding=utf8
set fileencoding=utf8

" line number
set number

" syntax highlight
syntax enable

" highlight search
set hlsearch " :nohl

" background dark
set background=light

" keep filetype and syntax
set hidden " :nohidden

" status bar
set ruler
"set laststatus=2

" visual bell
set novisualbell

" search subdirs
set path+=**

" shell
`if [ "zsh" = "$SH" ]; then
  echo "\" set shell=zsh\ --rcs"
else
  echo "\" set shell=bash\ --rcfile\ ~/.bashrc"
fi`

END
  if [ 0 -eq $? ]; then
    echo "yes"
  else
    echo "no"
  fi
}

BEGIN=`$date +%s`
echo "setup ${PLATFORM}'s $SH env ..."

gen_dot_shell_profile
gen_dot_shell_logout
gen_dot_shell_rc

gen_dot_shell_init
gen_dot_shell_vars
gen_dot_shell_paths
gen_dot_shell_aliases
gen_dot_shell_utils

gen_dot_vimrc $HOME/.vimrc

export PATH
. $HOME/.${SH}rc

END=`$date +%s`
echo
echo "... elpased $(( ${END}-${BEGIN} )) seconds, successed."
