#!/bin/bash
#------------------------------------------------
# target: setup Win32 programming environment
# author: junjiemars@gmail.com
#------------------------------------------------

KIT_BRANCH="${KIT_BRANCH:-master}"
GITHUB_R="${GITHUB_R:-https://raw.githubusercontent.com/junjiemars}/kit"
GITHUB_H="${GITHUB_H:-https://github.com/junjiemars}"
GET_KIT_URL="${GET_KIT_URL:-${GITHUB_R}/${KIT_BRANCH}/ul/get-kit.sh}"

TMP_DIR=${TMP:-$HOME/Downloads}
GET_KIT_L=${TMP}/get-kit.sh
ECHO_QUIET=${ECHO_QUIET:-NO}

curl -fsqL -o ${TMP_DIR}/get-kit.sh ${GET_KIT_URL}
if [ -f "${GET_KIT_L}" ]; then
  . ${GET_KIT_L}
  if [ "yes" != "$INCLUDE_GET_KIT" ]; then
    exit 1
  fi
else
  exit 1
fi



EMACS_VER="${EMACS_VER:-25.3_1}"
GMAKE_VER="${GMAKE_VER:-4.2.90}"

#to_win_path() {
#  echo "$1" | \
#    sed -e 's#^\/\([a-zA-Z]\)\/#\u\1:\/#' | \
#    sed -e 's#\/#\\#g'
#}
#
#set_win_var() {
#  setx "$1=$2" 
#}
#
#append_win_path() {
#  local p="$@"
#	if [ "function" = "`type -t append_path 2>/dev/null`" ]; then
#		append_path "$p" "$PATH"
#  fi
#}
#
##set_path() {
## can not get user specific PATH vars
##}
#
#download_winport() {
#  local ezwinports="https://sourceforge.net/projects/ezwinports"
#  local dest_dir=$1
#  local dest_file=$2
#  local port_url="${ezwinports}/files/${dest_file}/download"
#  curl -Lo "${dest_dir}/${dest_file}" -C - "${port_url}"; echo $?
#}
#
install_emacs() {
  local e_major_ver="`kit_major_version ${EMACS_VER}`"
  local e_zip="emacs-${EMACS_VER}-${MACHINE}.zip"
  local e_dep_zip="emacs-${e_major_ver}-${MACHINE}-deps.zip"
  local e_url_h="https://ftp.gnu.org/gnu/emacs/windows"
  local e_url="${e_url_h}/${e_zip}"
	local e_dep_url="${e_url_h}/${e_dep_zip}"
  local e_home="${OPEN_DIR}/emacs"
  local e_vhome="${e_home}/${EMACS_VER}"
  local bin_dir="${e_vhome}/bin"
  local cmd="emacs -nw --batch --eval='(emacs-version)'"

  [ 25 -le $e_major_ver ] || return 1
  
  `check_kit "${cmd}" "${bin_dir}"` && return 0

  install_kit "${bin_dir}/emacs.exe" \
              "${bin_dir}/${cmd}" \
              "${e_url}" \
              "${e_home}/${e_zip}" \
              "${e_vhome}" \
    || return $?

  if `${bin_dir}/${cmd} &>/dev/null`; then
    append_kit_path "${bin_dir}" "${e_home}"
  else
    return 1
  fi

  if [ ! -f "${e_home}/${e_dep_zip}" ]; then
    download_kit "${e_dep_url}" "${e_home}/${e_dep_zip}"
  fi

  if [ -f "${e_home}/${e_dep_zip}" ]; then
    extract_kit "${e_home}/${e_dep_zip}" "${e_vhome}" "clean=no"
  fi
}

# install_emacs() {
# 	local emacs_arch="i686"
# 	case $MACHINE in
# 		x86_64) emacs_arch="${MACHINE}" ;;
# 		*) ;;
# 	esac
# 	local emacs_version=
# 	IFS='.' read -a emacs_version <<< "${EMACS_VER}"
# 	local emacs_major="${emacs_version[0]}"
# 	local emacs_minor="${emacs_version[1]}"
# 	if [ ${emacs_major} -lt 25 ]; then
# 		emacs_arch="bin-i686"
# 	elif [ ${emacs_major} -ge 25 -a ${emacs_minor} -gt 1 ]; then
# 		emacs_arch="${emacs_arch}"
# 	fi
#  local emacs_zip="emacs-${EMACS_VER}-${emacs_arch}-mingw32.zip"
# 	if [ ${emacs_major} -ge 25 -a ${emacs_minor} -ge 1 ]; then
#  	emacs_zip="emacs-${EMACS_VER}-${emacs_arch}.zip"
# 	fi
#  local emacs_url="http://ftp.gnu.org/gnu/emacs/windows/${emacs_zip}"
#  local emacs_home="${OPT_RUN}/emacs"
#  local bin_dir="${emacs_home}/bin"

#  [ -d "${emacs_home}" ] || mkdir -p "${emacs_home}"

#  if [ ! -x "${bin_dir}/runemacs.exe" ]; then
#    curl -Lo "${emacs_home}/${emacs_zip}" -C - "${emacs_url}"
#    if [ ! -f "${emacs_home}/${emacs_zip}" ]; then
#      return 1
#    fi
#    cd "${emacs_home}" && unzip -qo "${emacs_home}/${emacs_zip}"
#  fi

# 	if [ ${emacs_major} -ge 25 ]; then
# 		local dep_zip="emacs-${emacs_major}-${MACHINE}-deps.zip"
# 		local dep_url="https://ftp.gnu.org/gnu/emacs/windows/${dep_zip}"
# 		curl -Lo "${emacs_home}/${dep_zip}" -C - "${dep_url}"
# 		if [ ! -f "${emacs_home}/${dep_zip}" ]; then
# 			return 1
# 		fi
#    cd "${emacs_home}" && unzip -qo "${emacs_home}/${dep_zip}"
# 	else
#  	if [ ! -x "${bin_dir}/gnutls-cli.exe" ]; then
# 			local gnutls_zip="gnutls-3.3.11-w32-bin.zip"
# 			download_winport "${emacs_home}" "${gnutls_zip}"
# 			if [ ! -f "${emacs_home}/${gnutls_zip}" ]; then
# 				return 1
# 			fi
# 			unzip -qo "${emacs_home}/${gnutls_zip}" 'bin/*' -d"${emacs_home}"
# 			unzip -qo "${emacs_home}/${gnutls_zip}" 'lib/*' -d"${emacs_home}"
# 		fi

# 		if [ ! -f "${bin_dir}/libxml2-2.dll" ]; then
# 			local libxml2_zip="libxml2-2.7.8-w32-bin.zip"
#    	download_winport "${emacs_home}" "${libxml2_zip}"
#    	if [ ! -f "${emacs_home}/${libxml2_zip}" ]; then
#      	return 1
#    	fi
#    	unzip -qo "${emacs_home}/${libxml2_zip}" \
#          	'bin/libxml2-2.dll' -d"${emacs_home}"
#  	  fi  
# 	fi

#  return 0
# }
#
#install_emacs_source() {
#  local emacs_git_ver=
#  local emacs_git_url="https://github.com/emacs-mirror/emacs.git"
#  IFS='.' read -a emacs_git_ver <<< "$EMACS_VER"
#  emacs_git_ver="emacs-${emacs_git_ver[0]}"
#
#  [ -z "$OPT_OPEN" ] && return 1
#  local emacs_git_home="$OPT_OPEN/${emacs_git_ver}"
#  
#  if [ -d "${emacs_git_home%/}/.git" ]; then
#    cd "${emacs_git_home}"
#    git reset --hard
#    git pull origin "${emacs_git_ver}"
#  else
#    cd "$OPT_OPEN"
#    git clone --depth=1 -b"${emacs_git_ver}" "${emacs_git_url}" "${emacs_git_ver}"
#  fi
#
#  return $?
#}
#
#install_pstools() {
#  local pstools_zip="PSTools.zip"  
#  local pstools_url="https://download.sysinternals.com/files/${pstools_zip}"
#  local pstools_home="${OPT_RUN}/pstools"
#
#  `pslist &>/dev/null` && return 0
#  [ -d "${pstools_home}" ] || mkdir -p "${pstools_home}"
#
#  curl -Lo "${pstools_home}/${pstools_zip}" -C - "${pstools_url}" 
#  if [ ! -x "${pstools_home}/pslist" ]; then
#    unzip -qo "${pstools_home}/${pstools_zip}" -d"${pstools_home}"
#  fi
#
#  return 0
#}
#
#install_procexp() {
#  local procexp_zip="ProcessExplorer.zip"  
#  local procexp_url="https://download.sysinternals.com/files/${procexp_zip}"
#  local bin_dir="${OPT_RUN}/bin"
#  local procexp_tmp="$HOME/Downloads"
#
#  `type -p procexp &>/dev/null` && return 0
#
#  if [ ! -f "${bin_dir}/procexp" ]; then
#    curl -Lo "${procexp_tmp}/${procexp_zip}" -C - "${procexp_url}" 
#  fi
#
#  if [ -f "${procexp_tmp}/${procexp_zip}" ]; then
#    unzip -qo "${procexp_tmp}/${procexp_zip}" 'procexp.exe' -d"${bin_dir}"
#  else
#    return 1
#  fi
#
#  return 0
#}
#
#install_netcat() {
#  local nc_zip="netcat-win32-1.12.zip"
#  local nc_url="https://eternallybored.org/misc/netcat/${nc_zip}"
#  local bin_dir="${OPT_RUN}/bin"
#  local nc_tmp="$HOME/Downloads"
#  
#  `nc -h &>/dev/null` && return 0
#
#  if [ ! -f "${bin_dir}/nc" ]; then
#    curl -Lo "${nc_tmp}/${nc_zip}" -C - "${nc_url}"
#  fi
#
#  if [ -f "${nc_tmp}/${nc_zip}" ]; then
#    case `uname -m 2>/dev/null` in
#      x86_64) 
#        unzip -qo "${nc_tmp}/${nc_zip}" 'nc64.exe' -d"${bin_dir}" && \
#          mv "${bin_dir}/nc64.exe" "${bin_dir}/nc.exe"
#      ;;
#      *)
#        unzip -qo "${nc_tmp}/${nc_zip}" 'nc.exe' -d"${bin_dir}"
#      ;;
#    esac
#  else
#    return 1
#  fi
#
#  return 0
#}
#

install_gmake() {
	local gm_tgz="gnumake-${GMAKE_VER}-${MACHINE}.tar.gz"
  local gm_url="${GITHUB_H}/make/releases/download/${GMAKE_VER}/${gm_tgz}"
  local gm_home="${OPEN_DIR}/gmake"
	local bin_dir="${gm_home}/${GMAKE_VER}"
  local cmd="${bin_dir}/make -v"

  `check_kit "make -v" "${bin_dir}"` && return 0

  install_kit "${bin_dir}/make.exe" \
              "${cmd}" \
              "${gm_url}" \
              "${gm_home}/${gm_tgz}" \
              "${bin_dir}" \
    || return $?

  if `${cmd} &>/dev/null`; then
    append_kit_path "${bin_dir}" "${gm_home}"
  else
    return 1
  fi
}

echo_head() {
  if [ "NO" = "$ECHO_QUIET" ]; then
    echo -n "$@"
  fi
}

echo_tail() {
  if [ "NO" = "$ECHO_QUIET" ]; then
    if [ 0 -eq $1 ]; then
      echo "ok"
    else
      echo "failed"
    fi  
  fi
}


HAS_ALL=${HAS_ALL:-"NO"}
HAS_EMACS=${HAS_EMACS:-0}
HAS_EMACS_SOURCE=${HAS_EMACS_SOURCE:-0}
HAS_PSTOOLS=${HAS_PSTOOLS:-0}
HAS_PROCEXP=${HAS_PROCEXP:-0}
HAS_NETCAT=${HAS_NETCAT:-0}
HAS_GMAKE=${HAS_GMAKE:-0}

if [ "YES" == "${HAS_ALL}" ]; then
  HAS_EMACS=1
  HAS_EMACS_SOURCE=0
  HAS_PSTOOLS=1
  HAS_PROCEXP=1
  HAS_NETCAT=1
	HAS_GMAKE=1
fi

[ 0 -lt "${HAS_EMACS}" ]          && KITS+=('install_emacs')
[ 0 -lt "${HAS_EMACS_SOURCE}" ]   && KITS+=('install_emacs_source')
[ 0 -lt "${HAS_PSTOOLS}" ]        && KITS+=('install_pstools')
[ 0 -lt "${HAS_PROCEXP}" ]        && KITS+=('install_procexp')
[ 0 -lt "${HAS_NETCAT}" ]         && KITS+=('install_netcat')
[ 0 -lt "${HAS_GMAKE}" ]          && KITS+=('install_gmake')


for i in "${KITS[@]}"; do
  echo_head " + ${i} ... "
  ${i}
  echo_tail $?
done

