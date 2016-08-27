#!/bin/bash
#------------------------------------------------
# target: install Win32 programming environment
# author: junjiemars@gmail.com
#------------------------------------------------

HAS_ALL=${HAS_ALL:-"NO"}
HAS_EMACS=${HAS_EMACS:-0}
HAS_PSTOOLS=${HAS_PSTOOLS:-0}
HAS_PROCEXP=${HAS_PROCEXP:-0}
HAS_NETCAT=${HAS_NETCAT:-0}

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
# can not get user specific PATH vars
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

  [ -d "${emacs_home}" ] || mkdir -p "${emacs_home}"

  if [ ! -x "${bin_dir}/runemacs.exe" ]; then
    curl -Lo "${emacs_home}/${emacs_zip}" -C - "${emacs_url}"
    if [ ! -f "${emacs_home}/${emacs_zip}" ]; then
      return 1
    fi
    cd "${emacs_home}" && unzip -qo "${emacs_home}/${emacs_zip}"
  fi

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

install_pstools() {
  local pstools_zip="PSTools.zip"  
  local pstools_url="https://download.sysinternals.com/files/${pstools_zip}"
  local pstools_home="${OPT_RUN}/pstools"

  [ 0 -eq `pslist &>/dev/null;echo $?` ] && return 0
  [ -d "${pstools_home}" ] || mkdir -p "${pstools_home}"

  curl -Lo "${pstools_home}/${pstools_zip}" -C - "${pstools_url}" 
  if [ ! -x "${pstools_home}/pslist" ]; then
    unzip -qo "${pstools_home}/${pstools_zip}" -d"${pstools_home}"
  fi

  return 0
}

install_procexp() {
  local procexp_zip="ProcessExplorer.zip"  
  local procexp_url="https://download.sysinternals.com/files/${procexp_zip}"
  local bin_dir="${OPT_RUN}/bin"
  local procexp_tmp="$HOME/Downloads"

  `type -p procexp &>/dev/null` && return 0

  if [ ! -f "${bin_dir}/procexp" ]; then
    curl -Lo "${procexp_tmp}/${procexp_zip}" -C - "${procexp_url}" 
  fi

  if [ -f "${procexp_tmp}/${procexp_zip}" ]; then
    unzip -qo "${procexp_tmp}/${procexp_zip}" 'procexp.exe' -d"${bin_dir}"
  else
    return 1
  fi

  return 0
}

install_netcat() {
  local nc_zip="netcat-win32-1.12.zip"
  local nc_url="https://eternallybored.org/misc/netcat/${nc_zip}"
  local bin_dir="${OPT_RUN}/bin"
  local nc_tmp="$HOME/Downloads"
  
  [ 0 -eq `nc -h &>/dev/null;echo $?` ] && return 0

  if [ ! -f "${bin_dir}/nc" ]; then
    curl -Lo "${nc_tmp}/${nc_zip}" -C - "${nc_url}"
  fi

  if [ -f "${nc_tmp}/${nc_zip}" ]; then
    case `uname -m 2>/dev/null` in
      x86_64) 
        unzip -qo "${nc_tmp}/${nc_zip}" 'nc64.exe' -d"${bin_dir}" && \
          mv "${bin_dir}/nc64.exe" "${bin_dir}/nc.exe"
      ;;
      *)
        unzip -qo "${nc_tmp}/${nc_zip}" 'nc.exe' -d"${bin_dir}"
      ;;
    esac
  else
    return 1
  fi

  return 0
}

if [ "YES" == "${HAS_ALL}" ]; then
  HAS_EMACS=1
  HAS_PSTOOLS=1
  HAS_PROCEXP=1
  HAS_NETCAT=1
fi

[ 0 -lt "${HAS_EMACS}" ]        && KITS+=('install_emacs')
[ 0 -lt "${HAS_PSTOOLS}" ]      && KITS+=('install_pstools')
[ 0 -lt "${HAS_PROCEXP}" ]      && KITS+=('install_procexp')
[ 0 -lt "${HAS_NETCAT}" ]       && KITS+=('install_netcat')

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
