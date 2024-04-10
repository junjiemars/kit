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
chmod=$(PATH=$PH command -v chmod)
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
[ -f \$HOME/.nore/${SH}/utils ] && . \$HOME/.nore/${SH}/aliases
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
$(if [ -f "${aliases}.pre" ]; then
  echo "# previous backup: ${aliases}.pre"
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
  echo "alias tailf='tail -f'"
  echo "alias stat='stat -x'"
else
  echo "alias ls='ls --color=auto'"
  echo "alias ll='ls -lh --color=auto'"
  echo "alias l='ls -CF --color=auto'"
fi)

alias_emacs () {
  if exist_p emacs; then
    alias emacs='emacs -nw'
  fi
}

alias_rlwrap_bin () {
  local bin=\$1
  if exist_p \$bin; then
    alias \$bin="rlwrap \$bin"
  fi
}

alias_emacs

$(if on_linux && [ "$SH" = "bash" ]; then
   echo "# bsd ps style"
   echo "alias ps='ps w'"
fi)

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
o_check_llvm_env=no
o_check_nvm_env=no
o_check_podman_env=no
o_check_python_env=no
o_check_racket_env=no
o_check_rust_env=no
$(if on_darwin; then
  echo "o_check_macports_env=yes"
else
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

if [ "\$o_check_podman_env" = "yes" ]; then
  [ -f "${vdir}/podman_env" ] \\
    && . "${vdir}/podman_env"
fi

if [ "\$o_check_python_env" = "yes" ]; then
  [ -f "${vdir}/python_env" ] \\
    && . "${vdir}/python_env"
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

norm_path() {
  echo \$1 \\
    | $tr ':' '\n' \\
    | $sed '/^$/d' \\
    | $tr '\n' ':' \\
    | $sed 's_:*\$__'
}

uniq_path() {
  $printf "\$*" \\
    | $awk -v RS=':' '\$0 && !a[\$0]++{printf "%s:",\$0}' \\
    | $sed 's_:*\$__'
}

rm_path() {
  local pd="\$(norm_path \$1)"
  local ph="\$(norm_path \$2)"
  if [ -z "\$pd" -o -z "\$ph" ]; then
    return 1
  fi
  local pr=\$(echo \$ph \\
              | $tr ':' '\n' \\
              | $grep -v "^\${pd}\$" \\
              | $tr '\n' ':' \\
              | $sed 's_:*\$__')
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
  local la="en_US.utf8"
  local lc="en_US.utf8"
$(if on_windows_nt; then
  $printf "  # change code page to unicode\n"
  $printf "  chcp.com 65001 &>/dev/null\n"
  $printf "  export LANG=\"\$la\"\n"
elif on_darwin; then
  $printf "  export LANG=\"\$la\"\n"
  $printf "  export LC_ALL=\"\$lc\"\n"
elif on_linux; then
  $printf "  # sudo dpkg-reconfigure locales\n"
  $printf "  if \$(locale -a|grep \"$la\" 2>/dev/null >&2); then\n"
  $printf "    export LANG=\"\$la\"\n"
  $printf "  fi\n"
  $printf "  export LC_ALL=\"\$lc\"\n"
else
  $printf "export LC_ALL=C"
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
$(if [ -f "${f}.pre" ]; then
  echo "# previous backup: ${f}.pre"
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

check_completion_env

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
  if ! \$javac -version &>/dev/null; then
    return 1
  fi
  $printf "%s\n" "\$javac"
}

export_java_env () {
  local javac="\${1:-\$(check_java_env)}"
  local d="\$(dirname \$javac)"
  local java="\${d}/java"
  unset JAVA_HOME
  if ! "\$java" -version &>/dev/null; then
    return 1
  fi
$(if on_darwin; then
  echo "  d=\"\$(/usr/libexec/java_home 2>/dev/null)\""
  echo "  if [ ! -d \"\$d\" ]; then"
  echo "    return 1"
  echo "  fi"
  echo "  export JAVA_HOME=\"\$d\""
elif on_linux; then
  echo "  if [ -L \"\$javac\" ]; then"
  echo "    d=\"\$(dirname \$(readlink -f \"\$javac\"))\""
  echo "    if [ ! -d \"\$d\" ]; then"
  echo "      return 1"
  echo "    fi"
  echo "  fi"
  echo "  export JAVA_HOME=\"\$(dirname \$d)\""
else
  echo "  export JAVA_HOME=\"\$(dirname \$d)\""
fi)
  local p="\$PATH"
  p="\$(norm_path \$d:\$(rm_path \$d \$p))"
  [ -z "\$p" ] || export PATH="\$p"
}

select_java_env () {
  local javac="\$1"
  if [ ! -x "\$javac" ]; then
    return 1
  fi
  export_java_env "\$javac"
}

make_java_lsp () {
  # download https://www.eclipse.org/downloads/download.php?file=/jdtls/milestones/1.9.0/jdt-language-server-1.9.0-202203031534.tar.gz
  # config
  # generate startup script
  : #nop
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
$(if [ -f "${f}.pre" ]; then
  echo "# previous backup: ${f}.pre"
fi)
# https://llvm.org
#------------------------------------------------

# https://clangd.llvm.org/installation
check_llvm_clangd () {
  if clangd --version &>/dev/null; then
    return 0
  fi
$(if on_darwin; then
  echo "  echo \"sudo port install clang-12\""
elif on_linux; then
  echo "  echo \"sudo apt install clang-12\""
else
  echo "  :"
fi)
  return 1
}

# https://github.com/rizsotto/Bear?tab=readme-ov-file
check_bear () {
  if bear --version &>/dev/null; then
    return 0
  fi
$(if on_darwin; then
  echo "  echo \"sudo port install bear\""
elif on_linux; then
  echo "  echo \"sudo apt install bear\""
else
  echo "  :"
fi)
  return 1
}

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
  if [ ! -x "/opt/local/bin/port" ]; then
    return 1
  fi
  printf "%s\n" "/opt/local"
  return 0
}

check_macports_llvm_env () {
  local p="/opt/local/libexec/llvm"
  if [ ! -L "\$p" ]; then
    # sudo port install llvm-12
    return 1
  fi
  $printf "%s\n" "\$p"
  return 0
}

export_macports_path () {
  local h="\$(check_macports_env)"
  if [ -z "\$h" ]; then
    return 1
  fi
  local p=
  local o=
  o="\$(check_macports_llvm_env)"
  p="\$PATH"
  if [ -d "\${o}/bin" ]; then
    p="\${o}/bin:\$(rm_path \${o}/bin \$p)"
  fi
  if [ -d "\${h}/sbin" ]; then
    p="\$(norm_path \${h}/sbin:\$(rm_path \${h}/sbin \$p))"
  fi
  if [ -d "\${h}/bin" ]; then
    p="\$(norm_path \${h}/bin:\$(rm_path \${h}/bin \$p))"
  fi
  [ -z "\$p" ] || export PATH="\$p"
}

export_macports_libpath () {
  local h="\$(check_macports_env)"
  if [ -z "\$h" ]; then
    return 1
  fi
  local p=
  local o=
  o="\$(check_macports_llvm_env)"
  p="\$DYLD_LIBRARY_PATH"
  if [ -d "\${o}/lib" ]; then
    p="\$(norm_path \${o}/lib:\$(rm_path \${o}/lib \$p))"
  fi
  if [ -d "\${h}/lib" ]; then
    p="\$(norm_path \${h}/lib:\$(rm_path \${h}/lib \$p))"
  fi
  [ -z "\$p" ] || export DYLD_LIBRARY_PATH="\$p"
}

if [ "\$o_export_path_env" = "yes" ]; then
  export_macports_path
fi

if [ "\$o_export_libpath_env" = "yes" ]; then
  export_macports_libpath
fi

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
  if ! podman -v &>/dev/null; then
     return 1
  fi
  local r="\${HOME}/.config/registries.conf"
  [ -r "\$r" ] && $printf "%s\n" "\$(where podman)"
}

check_podman_registry () {
  $printf "%s\n" 'docker.io'
  $printf "%s\n" 'registry.access.redhat.com'
  $printf "%s\n" 'registry.redhat.io'
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
$(if [ -f "${f}.pre" ]; then
  echo "# prvious backup: ${f}.pre"
fi)
# https://www.python.org
# https://virtualenv.pypa.io
# https://pypi.org/project/pip/
#------------------------------------------------

check_python_env () {
  local p3="\$(where python3 2>/dev/null)"
  if "\$p3" -V &>/dev/null; then
    $printf "%s\n" "\$p3"
    return 0
  fi
  p3="\$(where python 2>/dev/null)"
  if ! "\$p3" -V &>/dev/null; then
    return 1
  fi
  local v3="\$(\$p3 -V|sed 's/^Python \([0-9]*\)\..*$/\1/' 2>/dev/null)"
  [ "\$v3" -ge "3" ] && $printf "%s\n" "\$p3"
}

check_python_pip () {
  local p3="\$(where pip3 2>/dev/null)"
  if "\$p3" -V &>/dev/null; then
    $printf "%s\n" "\$p3"
    return 0
  fi
  p3="\$(where pip 2>/dev/null)"
  if ! "\$p3" -V &>/dev/null; then
    return 1
  fi
  local v3="\$(\$p3 -V|sed 's/.*(python \([0-9]*\)\..*).*/\1/' 2>/dev/null)"
  [ \$v3 -ge 3 ] && $printf "%s\n" "\$p3"
}

make_python_venv () {
  local d="\${1:-\$(pwd)}"
  local p="\$(check_python_env)"
  if [ -z "\$p" ]; then
    return 1
  fi
  \$p -m venv "\$d" && $printf "%s\n" "\$d"
}

check_python_pip_mirror () {
  $printf "%s\n" 'https://pypi.tuna.tsinghua.edu.cn/simple/'
  $printf "%s\n" 'https://pypi.mirrors.ustc.edu.cn/simple/'
  $printf "%s\n" 'http://mirrors.aliyun.com/pypi/simple/'
  $printf "%s\n" 'http://pypi.hustunique.com/'
  $printf "%s\n" 'http://pypi.sdutlinux.org/'
  $printf "%s\n" 'http://pypi.douban.com/simple/'
}

make_python_pip_mirror () {
  local m="\${1:-\$(check_python_pip_mirror|$sed -n '1p')}"
  local p="\$(check_python_pip)"
  if [ -z "\$p" ]; then
    return 1
  fi
  \$p config set global.index-url "\$m"
}

make_python_lsp () {
  local py="\$(check_python_env)"
  if [ -z "\$py" ]; then
    return 1
  fi
  local pip="\$(check_python_pip)"
  if [ -z "\$pip" ]; then
    return 1
  fi
  local opt_bin="\$(check_opt_dir)/run/bin"
  if [ ! -d "\$opt_bin" ]; then
    return 1
  fi
  if ! \$pip show python-lsp-server &>/dev/null; then
    \$pip install python-lsp-server
  fi
  local sr="\$(\$py -c'import sys;print(sys.prefix)' 2>/dev/null)"
  local pylsp="\${sr}/bin/pylsp"
  if [ ! -f "\$pylsp" ]; then
    return 1
  fi
  local ve="\${sr}/bin/activate"
  local pylsp_sh="\${opt_bin}/pylsp.sh"
  cat <<END > "\$pylsp_sh"
#!$(where sh)
\$(if [ -f "\$ve" ]; then
  echo ". \"\$ve\""
fi)
exec \$pylsp \\\$@
END
  $chmod u+x "\$pylsp_sh"
$(echo "}")

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
  local rc="\${HOME}/.cargo/bin/rustc"
  if [ ! -x "\$rc" ]; then
    return 1
  fi
  local sr="\$(\$rc --print sysroot 2>/dev/null)"
  if [ -z "\$sr" ]; then
    return 1
  fi
  [ -x "\$sr/bin/rustc" ] && $printf "%s\n" "\$sr"
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

check_rust_etc () {
  local sr="\$(check_rust_env)"
  if [ -z "\$sr" ]; then
    return 1
  fi
  local etc="\${sr}/lib/rustlib/etc"
  [ -d "\$etc" ] && echo "\$etc"
}

check_rust_src () {
  local sr="\$(check_rust_env)"
  if [ -z "\$sr" ]; then
    return 1
  fi
  local src="\${sr}/lib/rustlib/src/rust"
  [ -d "\$src" ] && echo "\$src"
}

check_rust_hash () {
  local sr="\$(check_rust_env)"
  if [ -z "\$sr" ]; then
    return 1
  fi
  local hash="\$(\${sr}/bin/rustc -vV|$sed -n '/^commit-hash/s;^commit-hash: \(.*\)$;\1;p' 2>/dev/null)"
  [ -n "\$hash" ] && echo "\$hash"
}

make_rust_debug () {
  local sr="\$(check_rust_env)"
  if [ -z "\$sr" ]; then
    return 1
  fi
  local hash="\$(check_rust_hash)"
  if [ -z "\$hash" ]; then
    return 1
  fi
  local etc="\$(check_rust_etc)"
  if [ -z "\$etc" ]; then
    return 1
  fi
  local src="\$(check_rust_src)"
  if [ -z "\$src" ]; then
    return 1
  fi
  local gdb="\${etc}/gdb_load_rust_pretty_printers.py"
  local lldb="\${etc}/lldb_commands"
  local from="/rustc/\${hash}"
  if [ -f "\$gdb" ]; then
     if ! $grep 'set substitute-path' \$gdb &>/dev/null; then
       $cp \$gdb \${gdb}.b0
     fi
     $sed -i.b1 '/set substitute-path/d' \$gdb
     $printf "gdb.execute('set substitute-path \$from \$src')" >> \$gdb
  fi
  if [ -f "\$lldb" ]; then
    if ! $grep 'settings set target.source-map' \$lldb &>/dev/null; then
      $cp \$lldb \${lldb}.b0
    fi
    $sed -i.b1 '/settings set target\.source-map/d' \$lldb
    $printf "settings set target.source-map \$from \$src" >> \$lldb
  fi
}

check_rust_tags_option () {
  local etc="\$(check_rust_etc)"
  if [ -z "\$etc" ]; then
    return 1
  fi
  $printf "%s\n" "\${etc}/ctags.rust"
}

check_rust_tags_file () {
  local etc="\$(check_rust_etc)"
  if [ -z "\$etc" ]; then
    return 1
  fi
  $printf "%s\n" "\${etc}/.tags_emacs"
}

make_rust_tags () {
  local args="\$@"
  local sr="\$(check_rust_env)"
  if [ -z "\$sr" ]; then
    return 1
  fi
  local etc="\$(check_rust_etc)"
  if [ -z "\$etc" ]; then
    return 1
  fi
  local src="\$(check_rust_src)"
  if [ -z "\$src" ]; then
    return 1
  fi
  local tag_opt="\$(check_rust_tags_option)"
  if [ ! -f "\$tag_opt" ]; then
    local opt_src="https://raw.githubusercontent.com/rust-lang/rust/master/src/etc/ctags.rust"
    $mkdir -p "\${etc}"
    curl --proto '=https' --tlsv1.2 -sSf "\$opt_src" -o "\$tag_opt"
  fi
  if ! where ctags &>/dev/null; then
    return 1
  fi
  local d="\$(check_rust_tags_file)"
  [ -f "\$d" ] && rm "\$d"
  ctags \$args -R -e -o \$d --options="\$tag_opt" \$src
  $printf "%s\n" "\$d"
}

export_rust_env () {
  local h="\$(check_rust_env)";
  unset CARGO_HOME
  if [ -d "\$h" ]; then
    local o="\${HOME}/.cargo"
    local p="\$PATH"
    if [ -d "\${o}/bin" ]; then
      p="\$(norm_path \${o}/bin:\$(rm_path \${o}/bin \$p))"
      CARGO_HOME="\${o}"
    fi
    if [ -d "\${h}/bin" ]; then
      p="\$(norm_path \${h}/bin:\$(rm_path \${h}/bin \$p))"
    fi
    export PATH="\$p"
  fi
}

if [ "\$o_export_path_env" = "yes" ]; then
  export_rust_env
fi

if [ "\$o_check_completion_env" = "yes" ]; then
  : # check_rust_completion
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

gen_shell_prompt_env
gen_shell_locale_env
gen_shell_completion_env

gen_bun_env
gen_java_env
gen_kube_env
gen_llvm_env
gen_nvm_env
gen_podman_env
gen_python_env
gen_racket_env
gen_rust_env
if on_darwin; then
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
