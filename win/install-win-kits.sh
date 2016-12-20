#!/bin/bash
#------------------------------------------------
# target: install Win32 programming environment
# author: junjiemars@gmail.com
#------------------------------------------------

MACHINE="`uname -m 2>/dev/null`"

HAS_ALL=${HAS_ALL:-"NO"}
HAS_EMACS=${HAS_EMACS:-0}
HAS_PSTOOLS=${HAS_PSTOOLS:-0}
HAS_PROCEXP=${HAS_PROCEXP:-0}
HAS_NETCAT=${HAS_NETCAT:-0}
HAS_GMAKE=${HAS_GMAKE:-0}

EMACS_VER=${EMACS_VER:-"24.5"}

to_win_path() {
  echo "$1" | \
    sed -e 's#^\/\([a-zA-Z]\)\/#\u\1:\/#' | \
    sed -e 's#\/#\\#g'
}

set_win_var() {
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
	local emacs_arch="i686"
	case $MACHINE in
		x86_64) emacs_arch="${MACHINE}" ;;
		*) ;;
	esac
	local emacs_major="`echo ${EMACS_VER}|sed 's#^\([0-9][0-9]\)*\..*$#\1#'`"
	if [ ${emacs_major} -lt 25 ]; then
		emacs_arch="bin-i686"
	else
		emacs_arch="${emacs_arch}-w64"
	fi
  local emacs_zip="emacs-${EMACS_VER}-${emacs_arch}-mingw32.zip"
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

  if [ ! -f "${bin_dir}/libxml2-2.dll" ]; then
    local libxml2_zip="libxml2-2.7.8-w32-bin.zip"
    download_winport "${emacs_home}" "${libxml2_zip}"
    if [ ! -f "${emacs_home}/${libxml2_zip}" ]; then
      return 1
    fi
    unzip -qo "${emacs_home}/${libxml2_zip}" \
          'bin/libxml2-2.dll' -d"${emacs_home}"
  fi  
 
  return 0
}

install_pstools() {
  local pstools_zip="PSTools.zip"  
  local pstools_url="https://download.sysinternals.com/files/${pstools_zip}"
  local pstools_home="${OPT_RUN}/pstools"

  `pslist &>/dev/null` && return 0
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
  
  `nc -h &>/dev/null` && return 0

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

install_gmake() {
	local gm_bin_zip="make-3.81-bin.zip"
  local gm_url="https://sourceforge.net/projects/gnuwin32/files/make/3.81"
	local gm_bin_url="${gm_url}/${gm_bin_zip}/download"
	local gm_dep_zip="make-3.81-dep.zip"
	local gm_dep_url="${gm_url}/${gm_dep_zip}/download"
	local bin_dir="${OPT_RUN}/gmake"
	local gm_tmp="$HOME/Downloads"

	#[ `make -v $>/dev/null` ] && return 0
	[ -d "${bin_dir}" ] || mkdir -p "${bin_dir}"

	if [ ! -f "${bin_dir}/make.exe" ]; then
		curl -Lo "${gm_tmp}/${gm_bin_zip}" -C - "${gm_bin_url}"
	fi
	if [ -f "${gm_tmp}/${gm_bin_zip}" ]; then
		unzip -qo "${gm_tmp}/${gm_bin_zip}" 'bin/make.exe' -d"${gm_tmp}/gm_bin" && \
      cp "${gm_tmp}/gm_bin/bin/make.exe" "${bin_dir%/}/"
	else
		return 1
	fi

	if [ ! -f "${bin_dir}/libiconv2.dll" ]; then
		curl -Lo "${gm_tmp}/${gm_dep_zip}" -C - "${gm_dep_url}"
	fi
	if [ -f "${gm_tmp}/${gm_dep_zip}" ]; then
		unzip -qo "${gm_tmp}/${gm_dep_zip}" 'bin/*' -d"${gm_tmp}/gm_dep" 
    [ -f "${gm_tmp}/gm_dep/bin/libiconv2.dll" ] && \
      find "${gm_tmp}/gm_dep/bin" -type f -name '*.dll' \
				-exec cp -t "${bin_dir}" {} +
	else
		return 1
	fi

	[ "function" = `type -t append_paths 2>/dev/null` ] && \
		append_paths "${bin_dir}"
	
	return 0	
}

if [ "YES" == "${HAS_ALL}" ]; then
  HAS_EMACS=1
  HAS_PSTOOLS=1
  HAS_PROCEXP=1
  HAS_NETCAT=1
	HAS_GMAKE=1
fi

[ 0 -lt "${HAS_EMACS}" ]        && KITS+=('install_emacs')
[ 0 -lt "${HAS_PSTOOLS}" ]      && KITS+=('install_pstools')
[ 0 -lt "${HAS_PROCEXP}" ]      && KITS+=('install_procexp')
[ 0 -lt "${HAS_NETCAT}" ]       && KITS+=('install_netcat')
[ 0 -lt "${HAS_GMAKE}" ]        && KITS+=('install_gmake')

# check OPT_* env vars
if [ -z "$OPT_RUN" ]; then
  echo -e "# \$OPT_RUN not set, run setup-bash.sh first, panic!"
  echo - "bash <(curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/setup-bash.sh)"
  exit 1
fi

for i in "${KITS[@]}"; do
  echo -e "# ${i} ..." 
  if `${i} &>/dev/null`; then
    echo -e "# ${i} good."
  else
    echo -e "# ${i} panic!"
  fi
done
