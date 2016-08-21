#!/bin/bash
#------------------------------------------------
# target: install Win32 programming environment
# author: junjiemars@gmail.com
#------------------------------------------------

HAS_ALL=${HAS_ALL:-"NO"}
HAS_EMACS=${HAS_EMACS:-0}

EMACS_VER=${EMACS_VER:-"24.5"}

to_win_path() {
  echo "$1" | \
    sed -e 's#^\/\([a-zA-Z]\)\/#\u\1:\/#' | \
    sed -e 's#\/#\\#g'
}

to_win_var() {
  setx "$1=$2" 
}

#set_path() {
#
#}

download_winport() {
  local ezwinports="https://sourceforge.net/projects/ezwinports"
  local dest_dir=$1
  local dest_file=$2
  local port_url="${ezwinports}/files/${dest_file}/download"
  curl -Lo "${dest_dir}/${dest_file}" -C - "${port_url}"; echo $?
}

install_emacs() {
  local emacs_zip="emacs-${EMACS_VER}-bin-i686-mingw32.zip"
  local emacs_url="http://ftp.gnu.org/gnu/emacs/windows/${emacs_zip}"
  local emacs_home="${OPT_RUN}/emacs"
  local bin_dir="${emacs_home}/bin"
  local lib_dir="${emacs_home}/lib"
  local tmp_dir="${emacs_home}/tmp"

  [ -d "${emacs_home}" ] || mkdir -p "${emacs_home}"
  if [ ! -x "${bin_dir}/runemacs.exe" ]; then
    curl -Lo "${emacs_home}/${emacs_zip}" -C - "${emacs_url}"
    if [ -f "${emacs_home}/${emacs_zip}" ]; then
      return 1
    fi
    cd "${emacs_home}" && unzip -qo "${emacs_home}/${emacs_zip}"
  fi

  [ -d "${lib_dir}" ] || mkdir -p "${lib_dir}"

  if [ ! -x "${bin_dir}/gnutls-cli.exe" ]; then
    local gnutls_zip="gnutls-3.3.11-w32-bin.zip"
    download_winport "${emacs_home}" "${gnutls_zip}"
    if [ ! -f "${emacs_home}/${gnutls_zip}" ]; then
      return 1
    fi
    unzip -qo "${emacs_home}/${gnutls_zip}" 'bin/*' -d"${emacs_home}"
    unzip -qo "${emacs_home}/${gnutls_zip}" 'lib/*' -d"${emacs_home}"
  fi
  
  return 0
}

if [ "YES" == "${HAS_ALL}" ]; then
  HAS_EMACS=1
fi

[ 0 -lt "${HAS_EMACS}" ]      && KITS+=('install_emacs')

# check OPT_* env vars
if [ -z "$OPT_RUN" ]; then
  echo -e "# \$OPT_RUN not set, run setup-bash.sh first, panic!"
  echo - "bash <(curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/setup-bash.sh)"
  exit 1
fi

for i in "${KITS[@]}"; do
  echo -e "# ${i} ..." 
  if [ 0 -eq `${i} &>/dev/null;echo $?` ]; then
    echo -e "# ${i} good."
  else
    echo -e "# ${i} panic!"
  fi
done
