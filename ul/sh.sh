#!/bin/sh
#------------------------------------------------
# target: shell env setup script
# author: Junjie Mars
#------------------------------------------------

HOME="${HOME%/}"
PH="/usr/bin:/bin:/usr/sbin:/sbin"
unset -f command 2>/dev/null

# check env
# check commands
set -e
awk=$(PATH=$PH command -v awk)
basename=$(PATH=$PH command -v basename)
cat=$(PATH=$PH command -v cat)
cp=$(PATH=$PH command -v cp)
cut=$(PATH=$PH command -v cut)
date=$(PATH=$PH command -v date)
dd=$(PATH=$PH command -v dd)
dirname=$(PATH=$PH command -v dirname)
env=$(PATH=$PH command -v env)
find=$(PATH=$PH command -v find)
grep=$(PATH=$PH command -v grep)
iconv=$(PATH=$PH command -v iconv)
ls=$(PATH=$PH command -v ls)
mkdir=$(PATH=$PH command -v mkdir)
printf=$(PATH=$PH command -v printf)
ps=$(PATH=$PH command -v ps)
rm=$(PATH=$PH command -v rm)
sed=$(PATH=$PH command -v sed)
sort=$(PATH=$PH command -v sort)
tr=$(PATH=$PH command -v tr)
uname=$(PATH=$PH command -v uname)
uniq=$(PATH=$PH command -v uniq)
xargs=$(PATH=$PH command -v xargs)
# check shell
PLATFORM=$($uname -s 2>/dev/null)
on_windows_nt () {
 case $PLATFORM in
   MSYS_NT*|MINGW*) return 0 ;;
   *) return 1 ;;
 esac
}
on_darwin () {
  case $PLATFORM in
    Darwin) return 0 ;;
    *) return 1 ;;
  esac
}
on_linux () {
  case $PLATFORM in
    Linux) return 0 ;;
    *) return 1 ;;
  esac
}
SH_ENV="https://raw.githubusercontent.com/junjiemars/kit/master/ul/sh.sh"
SHELL=$($ps -p$$ -ocommand 2>/dev/null|$sed 1d|$cut -d ' ' -f1|$tr -d '-')
if test -z "$SHELL" && on_windows_nt; then
  SHELL=$(PATH=$PH command -v bash)
fi
SH="$($basename $SHELL)"
set +e


echo_yes_or_no () {
  local c="$1"
  if [ 0 -eq $c ]; then
    $printf "yes\n"
  else
    $printf "no\n"
  fi
  return $c
}

save_as () {
  local f="$1"
  local ori="${f}.ori"
  local pre="${f}.pre"

  if [ -n "$f" ] && [ -f "$f" ]; then
    if [ -n "$ori" ] && [ -f "$ori" ]; then
      $cp "$f" "$pre"
    else
      $cp "$f" "$ori"
    fi
  fi
}

where () {
  case $SH in
    zsh) whence -p $@ ;;
    bash) type -P $@ ;;
    *) command -v $@ ;;
  esac
}

gen_shell_dot_profile () {
  local profile="$HOME/.${SH}_profile"
  local callrc="test -r \${HOME}/.${SH}rc && . \${HOME}/.${SH}rc"
  case $SH in
    bash) profile="$HOME/.bash_profile" ;;
    zsh) profile="$HOME/.zprofile"
         if on_darwin; then
           callrc="# test -r \${HOME}/.${SH}rc && . \${HOME}/.${SH}rc"
         fi
         ;;
    sh) profile="$HOME/.profile" ;;
  esac
  save_as "$profile"
  $printf "+ generate $profile ... "
  $cat << EOF > "$profile"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# file: $profile
# target: call .${SH}rc
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
$(if [ -f "${profile}.ori" ]; then
  echo "# origin backup: ${profile}.ori"
fi)
#------------------------------------------------

${callrc}

# eof
EOF
  echo_yes_or_no $?
}

gen_shell_dot_logout () {
  local logout="$HOME/.${SH}_logout"
  if [ "zsh" = "$SH" ]; then
    logout="$HOME/.zlogout"
  fi
  save_as "$logout"
  $printf "+ generate $logout ... "
  $cat << EOF > "$logout"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# file: $logout
# target: call when logout
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
$(if [ -f "${logout}.ori" ]; then
  echo "# origin backup: ${logout}.ori"
fi)
#------------------------------------------------

# $($basename ${logout}): executed by ${SH}(1) when login shell exits.
# when leaving the console clear the screen to increase privacy

if [ "\$SHLVL" -eq 1 ]; then
  clear
fi

# eof
EOF
  echo_yes_or_no $?
}

gen_shell_dot_rc () {
  local rc="$HOME/.${SH}rc"
  local ss="# nore
[ -f \$HOME/.nore/${SH}/init ] && . \$HOME/.nore/${SH}/init

# eof
"
  save_as "$rc"
  $printf "+ generate $rc ... "
  if [ ! -f "$rc" ]; then
    $cat << EOF > "$rc"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# file: $rc
# target: .${SH}rc default
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
$(if [ -f "${rc}.ori" ]; then
  echo "# origin backup: ${rc}.ori"
fi)
$(if [ -f "${rc}.pre" ]; then
  echo "# previous backup: ${rc}.pre"
fi)
#------------------------------------------------

${ss}
EOF
  else
    $sed -i.pre '/^# nore/,/^# eof/d' $rc
    $printf "%s" "$ss" >> $rc
  fi
  echo_yes_or_no $?
}

gen_shell_init () {
  local idir="$HOME/.nore/${SH}"
  local init="${idir}/init"
  save_as "$init"
  $printf "+ generate $init ... "
  $cat << EOF > "$init"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# file: $init
# target: initialize ${idir}/* scripts
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
$(if [ -f "${init}.ori" ]; then
  echo "# origin backup: ${init}.ori"
fi)
$(if [ -f "${init}.pre" ]; then
  echo "# previous backup: ${init}.pre"
fi)
#------------------------------------------------

SHELL=$SHELL

where () {
  # check the path of non-builtins
  $(if [ "zsh" = "$SH" ]; then
    echo "whence -p \$@"
  elif [ "bash" = "$SH" ]; then
    echo "type -P \$@"
  else
    echo "command -v \$@"
  fi)
}

exist_p () {
  # check the existence of non-builtins
  where \$1 >/dev/null 2>&1
}

inside_container_p () {
  [ ".\$INSIDE_CONTAINER" = ".1" ] && return 0
  if [ "\${container}" = "podman" ]; then
    export INSIDE_CONTAINER=1
    return 0
  fi
  if [ -f /proc/1/cgroup ]; then
    if $cat /proc/1/cgroup | $grep '/docker/' >/dev/null; then
      export INSIDE_CONTAINER=1
      return 0
    fi
  fi
  export INSIDE_CONTAINER=0
  return 1
}

inside_emacs_p () {
  [ -n "\$INSIDE_EMACS" ]
}

inside_vim_p () {
  [ -n "\$VIMRUNTIME" ]
}

[ -f \$HOME/.nore/${SH}/vars ] && . \$HOME/.nore/${SH}/vars
[ -f \$HOME/.nore/${SH}/paths ] && . \$HOME/.nore/${SH}/paths
[ -f \$HOME/.nore/${SH}/utils ] && . \$HOME/.nore/${SH}/utils
[ -f \$HOME/.nore/${SH}/check ] && . \$HOME/.nore/${SH}/check

# eof
EOF
  echo_yes_or_no $?
}

gen_shell_aliases () {
  local aliases="$HOME/.nore/${SH}/aliases"
  save_as "$aliases"
  $printf "+ generate $aliases ... "
  $cat << EOF > "$aliases"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# target: $aliases
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
$(if [ -f "${aliases}.ori" ]; then
  echo "# origin backup: ${aliases}.ori"
fi)
#------------------------------------------------

alias ..1='cd ../'
alias ..2='cd ../../'
alias ..3='cd ../../../'
alias ..4='cd ../../../../'

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'

$(if on_darwin; then
  echo "alias ls='ls -G'"
  echo "alias ll='ls -lh -G'"
  echo "alias l='ls -CF -G'"
  echo "alias tailf='tail -f'"
  echo "# alias stat='stat -x'"
else
  echo "alias ls='ls --color=auto'"
  echo "alias ll='ls -lh --color=auto'"
  echo "alias l='ls -CF --color=auto'"
fi)

alias_racket () {
  if exist_p racket; then
    alias racket='rlwrap racket'
  fi
}

alias_emacs () {
  if exist_p emacs; then
    alias emacs='emacs -nw'
  fi
}

alias_python () {
  if exist_p python3; then
    alias python=python3
  fi
  if exist_p pip3; then
    alias pip=pip3
  fi
}

alias_rlwrap_bin () {
  local bin=\$1
  if exist_p \$bin; then
    alias \$bin="rlwrap \$bin"
  fi
}

alias_emacs
# alias_racket
$(if on_linux && [ "$SH" = "bash" ]; then
   echo "# bsd ps style"
   echo "alias ps='ps w'"
fi)
alias_python

if exist_p rlwrap; then
  alias_rlwrap_bin ecl
  # alias_rlwrap_bin ed
  alias_rlwrap_bin openssl
fi


# eof
EOF
  echo_yes_or_no $?
}

gen_shell_utils () {
  local utils="$HOME/.nore/${SH}/utils"
  local rc=0
  save_as "$utils"
  $printf "+ generate $utils ... "
  $cat << EOF > "$utils"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# target: $utils
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
$(if [ -f "${utils}.ori" ]; then
  echo "# origin backup: ${utils}.ori"
fi)
#------------------------------------------------

# utc date
date_from_epoch ()
{
  local fmt="+%Y-%m-%d %H:%M:%S"
$(if on_linux; then
  echo "  if [ \$# -eq 0 ]; then"
  echo "    date -u -d@0 \"\$fmt\""
  echo "  else"
  echo "    date -u -d@\$@ \"\$fmt\""
  echo "  fi"
elif on_darwin; then
  echo "  if [ \$# -eq 0 ]; then"
  echo "    date -u -r0 \"\$fmt\""
  echo "  else"
  echo "    date -u -r\$@ \"\$fmt\""
  echo "  fi"
else
  echo "  return 1"
fi)
}

date_to_epoch ()
{
  local fmt="%Y-%m-%d %H:%M:%S"
  local out="+%s"
$(if on_linux; then
  echo "  if [ \$# -eq 0 ]; then"
  echo "    date -u \"\$out\""
  echo "  else"
  echo "    date -u -d\"\$@\" \"\$out\""
  echo "  fi"
elif on_darwin; then
  echo "  if [ \$# -eq 0 ]; then"
  echo "    date -u \"\$out\""
  echo "  else"
  echo "    date -u -j -f\"\$fmt\" \"\$@\" \"\$out\""
  echo "  fi"
else
  echo "  return 1"
fi)
}

$(if on_darwin; then
  echo "find_unwanted ()"
  echo "{"
  echo "   local what=\"\$@\""
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
  echo "   echo \"check \$app_dir ...\""
  echo "   echo \"check \$sup_dir ...\""
  echo "   echo \"check \$str_dir ...\""
  echo "   echo \"check \$cch_dir2 ...\""
  echo "   echo \"check \$cch_dir1 ...\""
  echo "   echo \"check \$prf_dir ...\""
  echo "   echo \"check \$plg_dir ...\""
  echo "   echo \"check \$crs_dir ...\""
  echo "   echo \"check \$lib_dir2 ...\""
  echo "   echo \"check \$lib_dir1 ...\""
  echo "}"
fi)

os_release ()
{
$(if on_darwin; then
  echo "  sw_vers"
elif on_linux; then
  echo "  if [ -f \"/etc/os-release\" ]; then"
  echo "    cat /etc/os-release"
  echo "  fi"
elif on_windows_nt; then
  echo "  systeminfo | grep '^OS Version'"
else
  echo "  return 1"
fi)
}

outbound_ip ()
{
  local u="https://checkip.dns.he.net"
  local v=\$1
  if exist_p curl; then
    case \$v in
      -6) v="-6" ;;
      *) v="-4" ;;
    esac
    curl \$v -sL "\$u" \\
      | $sed -n '/^Your IP.*/s;^Your IP.* \([.:a-z0-9]*\)</body>\$;\1;p'
  fi
}

random_range ()
{
   local n=\${1:-8}
   $dd if=/dev/urandom count=\$(( n*4 )) bs=1 2>/dev/null \\
     | $iconv -c -t ascii//TRANSLIT 2>/dev/null \\
     | $tr -cd '[:print:]' \\
     | $cut -c 1-\$n
}

$(if on_linux && where snap >/dev/null 2>&1; then
  echo "snap_remove_disabled ()"
  echo "{"
  echo "  LANG=C snap list --all | $awk '/disabled/{print \$1, \$3}' |"
  echo "    while read snapname revision; do"
  echo "      sudo snap remove \"\$snapname\" --revision=\"\$revision\""
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
fi)

# Doug McIlroy
word_frequency () {
  $tr -cs A-Za-z\' '\n' \\
    | $tr A-Z a-z \\
    | $sort \\
    | $uniq -c \\
    | $sort -k1,1nr -k2 \\
    | $sed \${1:-24}q
}

$(if on_linux && where unzip >/dev/null 2>&1; then
  echo "unzip_zhcn ()"
  echo "{"
  echo "  unzip -Ogb2312 \$@"
  echo "}"
fi)

# eof
EOF
  echo_yes_or_no $?
}

gen_shell_vars () {
  local vdir="$HOME/.nore/${SH}"
  local f="${vdir}/vars"
  save_as "$vars"
  $printf "+ generate $f ... "
  $cat << EOF > "$f"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# target: $f
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
$(if [ -f "${f}.ori" ]; then
  echo "# origin backup: ${f}.ori"
fi)
$(if [ -f "${f}.pre" ]; then
  echo "# previous backup: ${f}.pre"
fi)
#------------------------------------------------

o_check_prompt_env=yes
o_check_completion_env=yes
o_check_locale_env=yes

o_check_bun_env=no
o_check_java_env=no
o_check_kube_env=no
o_check_nvm_env=no
o_check_racket_env=no
o_check_rust_env=no
$(if on_darwin; then
  echo "o_check_llvm_env=yes"
  echo "o_check_macports_env=yes"
else
  echo "o_check_llvm_env=no"
  echo "o_check_macports_env=no"
fi)

o_export_libpath_env=no
o_export_path_env=yes

# eof
EOF
  echo_yes_or_no $?
}

gen_shell_check () {
  local vdir="$HOME/.nore/${SH}"
  local f="${vdir}/check"
  save_as "$f"
  $printf "+ generate $f ... "
  $cat << EOF > "$f"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# target: $f
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
$(if [ -f "${f}.ori" ]; then
  echo "# origin backup: ${f}.ori"
fi)
$(if [ -f "${f}.pre" ]; then
  echo "# previous backup: ${f}.pre"
fi)
#------------------------------------------------

if [ "\$o_check_prompt_env" = "yes" ]; then
  [ -f "${vdir}/prompt_env" ] \\
    && . "${vdir}/prompt_env"
fi

if [ "\$o_check_locale_env" = "yes" ]; then
  [ -f "${vdir}/locale_env" ] \\
    && . "${vdir}/locale_env"
fi

if [ "\$o_check_completion_env" = "yes" ]; then
  [ -f "${vdir}/completion_env" ] \\
    && . "${vdir}/completion_env"
fi

if [ "\$o_check_bun_env" = "yes" ]; then
  [ -f "${vdir}/bun_env" ] \\
    && . "${vdir}/bun_env"
fi

if [ "\$o_check_java_env" = "yes" ]; then
  [ -f "${vdir}/java_env" ] \\
    && . "${vdir}/java_env"
fi

if [ "\$o_check_kube_env" = "yes" ]; then
  [ -f "${vdir}/kube_env" ] \\
    && . "${vdir}/kube_env"
fi

if [ "\$o_check_llvm_env" = "yes" ]; then
  [ -f "${vdir}/llvm_env" ] \\
    && . "${vdir}/llvm_env"
fi

if [ "\$o_check_macports_env" = "yes" ]; then
  [ -f "${vdir}/macports_env" ] \\
    && . "${vdir}/macports_env"
fi

if [ "\$o_check_nvm_env" = "yes" ]; then
  [ -f "${vdir}/nvm_env" ] \\
    && . "${vdir}/nvm_env"
fi

if [ "\$o_check_racket_env" = "yes" ]; then
  [ -f "${vdir}/racket_env" ] \\
    && . "${vdir}/racket_env"
fi

if [ "\$o_check_rust_env" = "yes" ]; then
  [ -f "${vdir}/rust_env" ] \\
    && . "${vdir}/rust_env"
fi

# eof
EOF
  echo_yes_or_no $?
}

gen_shell_paths () {
  local f="$HOME/.nore/${SH}/paths"
  save_as "$f"
  $printf "+ generate $f ... "
  $cat << EOF > "$f"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# target: $f
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
$(if [ -f "${f}.ori" ]; then
  echo "# origin backup: ${f}.ori"
fi)
$(if [ -f "${f}.pre" ]; then
  echo "# pregin backup: ${f}.pre"
fi)
#------------------------------------------------

uniq_path() {
  $printf "\$*" \\
    | $awk -v RS=':' '\$0 && !a[\$0]++{printf "%s:",\$0}' \\
    | $sed 's/:*$//'
}

rm_path() {
  local pd="\$1"
  local ph="\${2:-\$PATH}"
  local pr=\$(echo \$ph \\
              | $tr ':' '\n' \\
              | $grep -v "\$pd" \\
              | $tr '\n' ':' \\
              | $sed 's/:*\$//')
  $printf "%s\n" \$pr
}

posix_path() {
  local car=\$(echo \$@ | $cut -d ':' -f1 | $sed 's#\\\\#\/#g')
  local cdr=\$(echo \$@ | $cut -d ':' -f2 | $sed 's#\\\\#\/#g')
  if [ \${#car} -lt \${#cdr} ]; then
    car=\$(echo \$car | $tr '[:upper:]' '[:lower:]')
    $(if on_windows_nt; then
      echo "cdr=/\${car}\${cdr}"
    else
      echo "cdr=\${car}:\${cdr}"
    fi)
  fi
  echo \${cdr}
}

check_opt_dir () {
  $(if on_windows_nt; then
    echo "  if [ -d \"\/d\" ]; then"
    echo "    [ -d \"/d/opt\" ] || $mkdir -p \"/d/opt\""
    echo "    echo \"/d/opt\""
    echo "  else"
    echo "    [ -d \"/c/opt\" ] || $mkdir -p \"/c/opt\""
    echo "    echo \"/c/opt\""
    echo "  fi"
  else
    echo "  [ -d \"/opt\" ] && echo \"/opt\""
  fi)
}

$(if on_windows_nt; then
  echo "sort_path () {"
  echo "  # let MSYS_NT and user defined commands first"
  echo "  local ps=\$@"
  echo "  local opt_p=\$(check_opt_dir)/run/bin"
  echo "  local win_p='^/c/'"
  echo "  local opt="
  echo "  local ori="
  echo "  local win="
  echo "  local sorted="
  echo "  opt=\$($printf \"\${ps}\"|$tr ':' '\n'|$grep \"\$opt_p\"|$tr '\n' ':')"
  echo "  ori=\$($printf \"\${ps}\"|$tr ':' '\n'|$grep -v \"\$opt_p\"|$grep -v \"\$win_p\" | $tr '\n' ':')"
  echo "  win=\$($printf \"\${ps}\"|$tr ':' '\n'|$grep \"\$win_p\" | $tr '\n' ':')"
  echo "  sorted=\$($printf \"\${ori}\${opt:+\$opt }\${win}\""
  echo "  $printf \"\${sorted}\""
  echo "}"
fi)

export_path_env () {
  local bin_path="\$PATH:\$PH"
  $(if on_darwin; then
    echo "local lib_path=\"\$DYLD_LIBRARY_PATH\""
  else
    echo "local lib_path=\"\$LD_LIBRARY_PATH\""
  fi)
  local opt_path="\$(check_opt_dir)"

  # /opt/run
  bin_path="\${opt_path}/run/bin:\$bin_path"
  lib_path="\${opt_path}/run/lib:\$lib_path"

  $(if on_windows_nt; then
    echo "bin_path=\"$(sort_path \$bin_path)\""
  fi)

  # export path env
  if [ "\$o_export_path_env" = "yes" ]; then
    export PATH="\$(uniq_path \$bin_path)"
  fi

  # export libpath env
  if [ "\$o_export_libpath_env" = "yes" ]; then
    $(if on_darwin; then
      echo "export DYLD_LIBRARY_PATH=\"\$(uniq_path \${lib_path})\""
    else
      echo "export LD_LIBRARY_PATH=\"\$(uniq_path \${lib_path})\""
    fi)
  fi
}

export_path_env

# eof
EOF
  echo_yes_or_no $?
}

gen_shell_lsp () {
  local lsp="$HOME/.nore/${SH}/lsp"
  save_as "$lsp"
  $printf "+ generate $lsp ... "
  $cat << EOF > "$lsp"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# target: $lsp
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
$(if [ -f "${lsp}.ori" ]; then
  echo "# origin backup: ${lsp}.ori"
fi)
#------------------------------------------------

python_lsp_install () {
  # python3 -m venv pylsp_venv
  # . pylsp_venv/bin/activate
  # pip install python-lsp-server
  # cat <<EOF > "pylsp.sh"
  ##!/usr/bin/sh
  #. pylsp_env/bin/activate
  #exec pylsp $@
  #EOF
}

rust_lsp_install () {
  #rustup component add rust-analyzer
}

# eof
EOF
  echo_yes_or_no $?
}

gen_shell_prompt_env () {
  local f="$HOME/.nore/${SH}/prompt_env"
  save_as "$f"
  $printf "+ generate $f ... "
  $cat << EOF > "$f"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# target: $f
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
$(if [ -f "${f}.ori" ]; then
  echo "# origin backup: ${f}.ori"
fi)
#------------------------------------------------

pretty_prompt_command () {
  local o="\${PROMPT_COMMAND}"
  local pc1=''

  if [ -n "\${o}" ]; then
    if inside_container_p || inside_emacs_p; then
      echo "\$pc1"
      return 0
    fi
  fi
  echo "\$o"
  return 1
}

pretty_term () {
  local o="\$TERM"
  local t="xterm"

  if [ -z "\$o" ]; then
    echo "\$t"
    return 0
  fi

  if [ "dumb" = "\$o" ]; then
    if inside_emacs_p; then
      echo "\$o"
    else
      echo "\$t"
    fi
  else
    echo "\$o"
  fi
}

check_prompt_env () {
  PROMPT_COMMAND="\$(pretty_prompt_command)"
  if [ -z "\$PROMPT_COMMAND" ]; then
    unset PROMPT_COMMAND
  else
    export PROMPT_COMMAND
  fi
$(if [ "zsh" = "$SH" ]; then
  echo "  PS1=\"%n@%m %1~ %#\""
elif [ "bash" = "$SH" ]; then
  echo "  PS1=\"\u@\h \W \$\""
else
  echo "  PS1=\"\$LOGNAME@\$($uname -n | $cut -d '.' -f1) \$\""
fi)
  export PS1="\${PS1% } "
  TERM="\$(pretty_term)"
  export TERM
}

# eof
EOF
  echo_yes_or_no $?
}

gen_shell_locale_env () {
  local f="$HOME/.nore/${SH}/locale_env"
  save_as "$f"
  $printf "+ generate $f ... "
  $cat << EOF > "$f"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# target: $f
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
$(if [ -f "${f}.ori" ]; then
  echo "# origin backup: ${f}.ori"
fi)
#------------------------------------------------

check_locale_env () {
  $(if on_windows_nt; then
    echo "# change code page to unicode"
    echo "  chcp.com 65001 &>/dev/null"
    echo "  export LANG=\"en_US.UTF-8\""
  elif on_darwin; then
    echo "local la=\"en_US.utf8\""
    echo "local lc=\"en_US.utf8\""
    echo "export LANG=\"\$la\""
    echo "  export LC_ALL=\"\$lc\""
  elif on_linux; then
    echo "local la=\"en_US.utf8\""
    echo "local lc=\"en_US.utf8\""
    echo "# sudo dpkg-reconfigure locales"
    echo "  if \$(locale -a|grep \"$la\" 2>/dev/null >&2); then"
    echo "    export LANG=\"\$la\""
    echo "  fi"
    echo "  export LC_ALL=\"\$lc\""
  else
    echo "export LC_ALL=C"
  fi)
}

# eof
EOF
  echo_yes_or_no $?
}

gen_shell_completion_env () {
  local f="$HOME/.nore/${SH}/completion_env"
  save_as "$f"
  $printf "+ generate $f ... "
  $cat << EOF > "$f"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# target: $f
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
$(if [ -f "${f}.ori" ]; then
  echo "# origin backup: ${f}.ori"
fi)
#------------------------------------------------

check_completion_env () {
$(if [ "bash" = "$SH" ]; then
   echo "  local c=\"/etc/profile.d/bash_completion.sh\""
   echo "  if [ -f \"\$c\" ]; then"
   echo "    . \"\$c\""
   echo "  fi"
elif [ "zsh" = "$SH" ]; then
   echo "  autoload -Uz compinit && compinit"
else
   echo "  # nop"
   echo ":"
fi)
}

# eof
EOF
  echo_yes_or_no $?
}

gen_bun_env () {
  local f="$HOME/.nore/${SH}/bun_env"
  save_as "$f"
  $printf "+ generate $f ... "
  $cat << EOF > "$f"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# target: $f
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
$(if [ -f "${f}.ori" ]; then
  echo "# origin backup: ${f}.ori"
fi)
$(if [ -f "${f}.pre" ]; then
  echo "# previous backup: ${f}.pre"
fi)
# https://github.com/oven-sh/bun
#------------------------------------------------

check_bun_env () {
  local d="\$HOME/.bun"
  if [ -x "\${d}/bin/bun" ]; then
    BUN_DIR="\${d}/bin"
    return 0
  fi
  return 1
}

# eof
EOF
  echo_yes_or_no $?
}

gen_java_env () {
  local f="$HOME/.nore/${SH}/java_env"
  save_as "$f"
  $printf "+ generate $f ... "
  $cat << EOF > "$f"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# target: $f
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
$(if [ -f "${f}.ori" ]; then
  echo "# origin backup: ${f}.ori"
fi)
$(if [ -f "${f}.pre" ]; then
  echo "# previous backup: ${f}.pre"
fi)
# https://openjdk.java.net
#------------------------------------------------

check_java_env () {
  local javac="\$(where javac 2>/dev/null)"
  local java_home=
  if [ -x "\$javac" -a -L "\$javac" ] ; then
    echo "\$(readlink \$javac)"
    return 0
  fi
$(if on_darwin; then
  echo "  java_home='/usr/libexec/java_home'"
  echo "  if [ -L \"\$java_home\" ]; then"
  echo "    javac=\"\$(readlink \${java_home}/javac)\""
  echo "    if [ -x \"\$javac\" ]; then"
  echo "      echo \"\$javac\""
  echo "      return 0"
  echo "    fi"
  echo "  fi"
elif on_linux; then
  echo "  javac=\"\$(where javac 2>/dev/null)\""
  echo "  if [ -x \"\$javac\" ]; then"
  echo "    echo \"\$(readlink -f \"\$javac\")\""
  echo "    return 0"
  echo "  fi"
elif on_windows_nt; then
  echo "  # nop"
fi)
  return 1
}

select_java_env () {
  local javac="\$1"
  local d=
  if [ -x "\$javac" ]; then
    d="\$(dirname \$javac)"
    export JAVA_HOME="\$(dirname \$d)"
    export PATH="\$d:\$(rm_path \$d)"
    return 0
  fi
}

export_java_env () {
  local javac="\$(check_java_env 2>/dev/null)"
  local d=
  if [ -x "\$javac" ]; then
    d="\$(dirname \$javac)"
    export JAVA_HOME="\$(dirname \$(dirname \$d))"
    export PATH=\$d:\$(rm_path \$d)
  else
    unset JAVA_HOME
  fi
}

# eof
EOF
  echo_yes_or_no $?

}

gen_kube_env () {
  local f="$HOME/.nore/${SH}/kube_env"
  save_as "$f"
  $printf "+ generate $f ... "
  $cat << EOF > "$f"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# target: $f
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
$(if [ -f "${f}.ori" ]; then
  echo "# origin backup: ${f}.ori"
fi)
# https://kubernetes.io/docs/reference/kubectl/overview/
# https://argoproj.github.io/argo-workflows/
#------------------------------------------------

check_kube_env () {
  local d="\${HOME}/.kube"
  local s="\${d}/kube-${SH}.sh"
  local a="\${d}/argo-${SH}.sh"
  local c="\${d}/\${1}"
  local r="\${d}/.recent"
  if exist_p kubectl; then
    if [ ! -f "\$s" ]; then
      [ -d "\$d" ] || mkdir -p "\$d"
      SHELL=$SHELL kubectl completion ${SH} >"\$s"
    fi
    if [ -r "\$s" ]; then
      check_completion_env && . "\$s"
    fi
    if [ -f "\$c" ]; then
      export KUBECONFIG="\$c"
      $cp "\$c" "\$r"
    elif [ -f "\$r" ]; then
      export KUBECONFIG="\$r"
    fi
    if inside_emacs_p && exist_p emacsclient; then
      export KUBE_EDITOR=emacsclient
    fi
  else
    return 1
  fi
  if exist_p argo; then
    if [ ! -f "\$a" ]; then
      SHELL=$SHELL argo completion ${SH} >"\$a"
    fi
    if [ -r "\$a" ]; then
      check_completion_env && . "\$a"
    fi
  fi
  return 0
}

# eof
EOF
  echo_yes_or_no $?
}

gen_llvm_env () {
  local f="$HOME/.nore/${SH}/llvm_env"
  save_as "$f"
  $printf "+ generate $f ... "
  $cat << EOF > "$f"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# target: $f
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
$(if [ -f "${f}.ori" ]; then
  echo "# origin backup: ${f}.ori"
fi)
# https://llvm.org
#------------------------------------------------

if [ \"\$o_check_llvm_env\" = \"yes\" -a -n \"\$LLVM_DIR\" ]; then
  bin_path=\"\${LLVM_DIR}/bin:\${LLVM_DIR}/sbin:\$bin_path\"
  lib_path=\"\${LLVM_DIR}/lib:\$lib_path\"
else
  unset LLVM_DIR
fi

# eof
EOF
  echo_yes_or_no $?
}

gen_macports_env () {
  local f="$HOME/.nore/${SH}/macports_env"
  save_as "$f"
  $printf "+ generate $f ... "
  $cat << EOF > "$f"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# target: $f
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
$(if [ -f "${f}.ori" ]; then
  echo "# origin backup: ${f}.ori"
fi)
$(if [ -f "${f}.pre" ]; then
  echo "# previous backup: ${f}.pre"
fi)
# https://www.macports.org
#------------------------------------------------

check_macports_env () {
  if [ -x "/opt/local/bin/port" ]; then
    MACPORTS_HOME=/opt/local
    return 0
  else
    unset MACPORTS_HOME
    return 1
  fi
}

export_macports_env () {
  local p=""
  if ! check_macports_env; then
    return 1
  fi
  if [ "\$o_export_path_env" = "yes" ]; then
    p=\${MACPORTS_HOME}/sbin:\$(rm_path "\${MACPORTS_HOME}/sbin" "\$PATH")
    p=\${MACPORTS_HOME}/bin:\$(rm_path "\${MACPORTS_HOME}/bin" "\$p")
    export PATH=\$p
  fi
  if [ "\$o_export_libpath_env" = "yes" ]; then
    p=\${MACPORTS_HOME}/lib:\$(rm_path "\${MACPORTS_HOME}/lib" "\$DYLD_LIBRARY_PATH")
    export DYLD_LIBRARY_PATH=\$p
  fi
  return 0
}

export_macports_env

# eof
EOF
  echo_yes_or_no $?
}

gen_nvm_env () {
  local f="$HOME/.nore/${SH}/nvm_env"
  save_as "$f"
  $printf "+ generate $f ... "
  $cat << EOF > "$f"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# target: $f
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
$(if [ -f "${f}.ori" ]; then
  echo "# origin backup: ${f}.ori"
fi)
$(if [ -f "${f}.pre" ]; then
  echo "# previous backup: ${f}.pre"
fi)
# https://github.com/nvm-sh/nvm
#------------------------------------------------

check_nvm_env () {
  local d="\$HOME/.nvm"
  if [ -s "\${d}/nvm.sh" ]; then
    NVM_DIR="\$d"
    . "\${d}/nvm.sh"
    $(if [ "bash" = "$SH" ]; then
      echo "[ -s \"\${d}/bash_completion\" ] && . \"\${d}/bash_completion\""
    fi)
    return 0
  fi
  return 1
}

export_nvm_env () {
  if check_nvm_env; then
    export PATH="\$NVM_DIR:\$(rm_path \$NM_DIR)"
  fi
}

if [ "\$o_check_nvm_env" = "yes" ]; then
  export_nvm_env
fi

# eof
EOF
  echo_yes_or_no $?
}

gen_podman_env () {
  local f="$HOME/.nore/${SH}/podman_env"
  save_as "$f"
  $printf "+ generate $f ... "
  $cat << EOF > "$f"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# target: $f
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
$(if [ -f "${f}.ori" ]; then
  echo "# origin backup: ${f}.ori"
fi)
$(if [ -f "${f}.pre" ]; then
  echo "# previous backup: ${f}.pre"
fi)
# https://podman.io
#------------------------------------------------

check_podman_env () {
  local d="\${HOME}/.config"
  local r="\${d}/registries.conf"
  local c="\$1"
  case \$c in
    mirror)
      echo "[registries.search]\nregistries = ['registry.access.redhat.com','registry.redhat.io','docker.io']" >> "\$r"
      ;;
    *)
      where podman; echo "\$d"
      ;;
  esac
}

# eof
EOF
  echo_yes_or_no $?
}

gen_python_env () {
  local f="$HOME/.nore/${SH}/python_env"
  save_as "$f"
  $printf "+ generate $f ... "
  $cat << EOF > "$f"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# target: $f
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
$(if [ -f "${f}.ori" ]; then
  echo "# origin backup: ${f}.ori"
fi)
# https://www.python.org
# https://virtualenv.pypa.io
# https://pypi.org/project/pip/
#------------------------------------------------

check_python_env () {
  local py=\$(where python3 || where python 2>/dev/null)
  local pi=\$(where pip3 || where pip 2>/dev/null)
  if [ -n "\$py" ]; then
    echo "python: \$(\$py --version)"
  fi
  if exist_p virtualenv; then
    echo "virtualenv: \$(virtualenv --version)"
  fi
  if [ -n "\$pi" ]; then
    echo "pip: \$(\$pi --version)"
    echo "pip config: \$(\$pi config list)"
    echo "pip mirrors:"
    echo "https://pypi.org/simple"
    echo "https://pypi.tuna.tsinghua.edu.cn/simple"
    echo "https://mirrors.aliyun.com/pypi/simple"
  fi
}

python_lsp_install () {
  # python3 -m venv pylsp_venv
  # . pylsp_venv/bin/activate
  # pip install python-lsp-server
  # cat <<EOF > "pylsp.sh"
  ##!/usr/bin/sh
  #. pylsp_env/bin/activate
  #exec pylsp $@
  #EOF
}

# eof
EOF
  echo_yes_or_no $?
}

gen_racket_env () {
  local f="$HOME/.nore/${SH}/racket_env"
  save_as "$f"
  $printf "+ generate $f ... "
  $cat << EOF > "$f"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# target: $f
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
$(if [ -f "${f}.ori" ]; then
  echo "# origin backup: ${f}.ori"
fi)
# https://racket-lang.org
#------------------------------------------------

check_racket_env () {
$(if on_darwin; then
   if [ "zsh" = "$SH" ]; then
      echo "  setopt +o nomatch &>/dev/null"
   fi
   echo "  if \$ls -ldr /Applications/Racket* &>/dev/null; then"
   echo "    RACKET_HOME=\"\$($ls -ldr /Applications/Racket* | $sed 1q | $sed 's;.*\(/Applications/Racket v[0-9][0-9]*\.[0-9][0-9]*\).*;\1;g')\""
   echo "  fi"
   if [ "zsh" = "$SH" ]; then
     echo "  setopt -o nomatch &>/dev/null"
   fi
   echo "  if [ -z \"\$RACKET_HOME\" ]; then"
   echo "    unset RACKET_HOME"
   echo "    return 1"
   echo "  fi"
else
   echo "  # nop"
   echo "  :"
fi)
}

# eof
EOF
  echo_yes_or_no $?
}

gen_rust_env () {
	local r="${HOME}/.nore/${SH}"
  local f="${r}/rust_env"
  save_as "$f"
  $printf "+ generate $f ... "
  $cat << EOF > "$f"
#### -*- mode:sh -*- vim:ft=sh
#------------------------------------------------
# target: $f
# author: Junjie Mars
# generated by:
#   $SH <($SH_ENV)
$(if [ -f "${f}.ori" ]; then
  echo "# origin backup: ${f}.ori"
fi)
$(if [ -f "${f}.pre" ]; then
  echo "# previous backup: ${f}.pre"
fi)
# https://www.rust-lang.org/
#------------------------------------------------

check_rust_env () {
  local cargo_dir="\${HOME}/.cargo"
  local b="\${cargo_dir}/bin"
  local r="\${b}/rustc"
  local sr="\$(\$r --print sysroot 2>/dev/null)"
  if [ -n "\$sr" -a -d "\$sr" -a -x "\$sr/bin/rustc" ]; then
    echo "\$sr"
    return 0
  else
    return 1
  fi
}

install_rustup () {
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
}

check_rust_completion () {
  local rc="${r}/rust_cargo_completion"
  local ru="${r}/rust_rustup_completion"
  rustup completions $SH cargo > \$rc
	rustup completions $SH rustup > \$ru
  . \$rc
  . \$ru
}

check_rust_src_env () {
  local force="\$1"
  local rc="\$(rustc --print sysroot 2>/dev/null)"
  local hash="\$(rustc -vV|$sed -n '/^commit-hash/s;commit-hash: \(.*\);\1;' 2>/dev/null)"
  local etc="\${rc}/lib/rustlib/src/rust/src/etc"
  local tag="\${etc}/ctags.rust"
  local tag_src="https://raw.githubusercontent.com/rust-lang/rust/master/src/etc/ctags.rust"
  local gdb="\${rc}/lib/rustlib/etc/gdb_load_rust_pretty_printers.py"
  local lldb="\${rc}/lib/rustlib/etc/lldb_commands"
  local from="/rustc/\${hash}"
  local src="\${rc}/lib/rustlib/src/rust"
  if [ -n "\$rc" ] && [ -d "\$rc" ]; then
    if ! [ -f "\$tag" ]; then
      $mkdir -p "\${etc}"
      curl --proto '=https' --tlsv1.2 -sSf "\$tag_src" -o "\$tag"
    fi
    if [ -n "\$hash" ] && [ -d "\$src" ]; then
      if [ -f "\$gdb" ]; then
         if [ "\$force" = "renew" ]; then
           sed -i.b1 '/set substitute-path/d' \$gdb
         fi
         if ! $grep 'set substitute-path' \$gdb &>/dev/null; then
           $cp \$gdb \${gdb}.b0
           $printf "gdb.execute('set substitute-path \$from \$src')" >> \$gdb
         fi
      fi
      if [ -f "\$lldb" ]; then
        if [ "\$force" = "renew" ]; then
          $sed -i.b1 '/settings set target\.source-map/d' \$lldb
        fi
        if ! $grep 'settings set target.source-map' \$lldb &>/dev/null; then
          $cp \$lldb \${lldb}.b0
          $printf "settings set target.source-map \$from \$src" >> \$lldb
        fi
      fi
    fi
  fi
}

export_rust_env () {
  local h="\$(check_rust_env)";
  unset CARGO_HOME
  if [ -d "\$h" ]; then
    CARGO_HOME="\$h"
    export PATH="\${h}/bin:\$(rm_path \${h}/bin)"
  fi
}

if [ "\$o_export_path_env" = "yes" ]; then
  export_rust_env
fi

if [ "\$o_check_completion_env" = "yes" ]; then
  # check_rust_completion
fi

# eof
EOF
  echo_yes_or_no $?
}

gen_dot_exrc () {
  local rc="$HOME/.exrc"
  $printf "+ generate $rc ... "
  $cat << END > "$rc"
"------------------------------------------------
" target: $rc
" author: Junjie Mars
" generated by:
"   $SH <($SH_ENV)
$(if [ -f "${rc}.ori" ]; then
  echo "\" origin backup: ${rc}.ori"
fi)
"------------------------------------------------

set exrc

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
set nonumber

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

" shell
$(if [ "zsh" = "$SH" ]; then
  echo "\"set shell=zsh\ --rcs"
else
  echo "\"set shell=bash\ --rcfile\ ${HOME}/.bashrc"
fi)

" search subdirs
set path+=**

END
  echo_yes_or_no $?
}


BEGIN=$($date +%s)
echo "setup ${PLATFORM}'s $SH env ..."

gen_shell_dot_profile
gen_shell_dot_logout
gen_shell_dot_rc

gen_shell_init
gen_shell_vars
gen_shell_check
gen_shell_paths
gen_shell_aliases
gen_shell_utils
gen_shell_lsp

gen_shell_prompt_env
gen_shell_locale_env
gen_shell_completion_env

gen_bun_env
gen_java_env
gen_kube_env
gen_nvm_env
gen_podman_env
gen_python_env
gen_racket_env
gen_rust_env
if on_darwin; then
  gen_llvm_env
  gen_macports_env
fi

gen_dot_exrc $HOME/.exrc

export PATH
. $HOME/.${SH}rc

unset PH
unset PLATFORM
unset SH
unset SH_ENV


END=$($date +%s)
$printf "\n... elpased %d seconds, successed.\n" $(( ${END}-${BEGIN} ))

# eof
