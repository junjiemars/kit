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

install_emacs() {
  local e_major_ver="`kit_major_version ${EMACS_VER}`"
  local e_zip="emacs-${e_major_ver}/emacs-${EMACS_VER}-${MACHINE}.zip"
  local e_dep_zip="emacs-${e_major_ver}/emacs-${EMCACS_VER}-${MACHINE}-deps.zip"
  local e_url_h="https://ftp.gnu.org/gnu/emacs/windows"
  local e_url="${e_url_h}/${e_zip}"
	local e_dep_url="${e_url_h}/${e_dep_zip}"
  local e_home="${OPEN_DIR}/emacs"
  local e_vhome="${e_home}/${EMACS_VER}"
  local bin_dir="${e_vhome}/bin"
  local cmd="emacs -nw --batch --eval='(emacs-version)'"

  [ 25 -le $e_major_ver ] || return 1
  
  `check_kit "${cmd}" "${bin_dir}" "${EMACS_VER}"` && return 0

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

install_emacs_source() {
  local e_major_ver="`kit_major_version ${EMACS_VER}`"
  local e_git_url="https://github.com/emacs-mirror/emacs.git"
  local e_home="${OPEN_DIR}/emacs"
  local e_repo="${e_home}/src-${e_major_ver}"
  local e_branch="emacs-${e_major_ver}"

  if ! `check_git_repo "${e_repo}" "/emacs\.git"`; then
    call_git clone --depth=1 --branch=${e_branch} \
      ${e_git_url} ${e_repo} || return $?
  fi

  if [ "`check_git_branch ${e_repo}`" = "${e_branch}" ]; then
    call_git ${e_repo} pull origin ${e_branch} || return $?
  else
    [ -d "${e_repo}" ] && rm -rf "${e_repo}"
    call_git ${e_repo} clone --depth=1 --branch=${e_branch} \
      ${e_git_url} ${e_repo} || return $?
  fi
}

install_pstools() {
  local p_zip="PSTools.zip"  
  local p_url="https://download.sysinternals.com/files/${p_zip}"
  local p_home="${OPEN_DIR}/pstools"
  local bin_dir="${p_home}/bin"
  local cmd="pslist"

  # `check_kit "${cmd}" "${p_home}"` && return 0

  install_kit "${bin_dir}/pslist.exe" \
              "${bin_dir}/${cmd}" \
              "${p_url}" \
              "${p_home}/${p_zip}" \
              "${bin_dir}" \
    || return $?

  if `${bin_dir}/${cmd} &>/dev/null`; then
    append_kit_path "${bin_dir}" "${p_home}"
  else
    return 1
  fi
}

install_aria2c() {
  local a2c_zip="aria2-1.34.0-win-64bit-build1"
  local a2c_url="https://github.com/aria2/aria2/releases/download/release-1.34.0/${a2c_zip}.zip"
  local cmd="aria2c"
  local a2c_home="${TMP_DIR}/${cmd}"
	local a2c_tmp="${a2c_home}/bin"
  local bin_dir="${RUN_DIR}/bin"
	local exe="${cmd}.exe"
	local a2c_check="${cmd} --version"

	if ! `check_kit "${a2c_check}"`; then
		if `check_kit "${a2c_check}" "${a2c_tmp}/${a2c_zip}"`; then
			cp "${a2c_tmp}/${a2c_zip}/${exe}" "${bin_dir}" \
				&& rm -rf "${a2c_home}"
		fi
	else
		return 0
	fi

  install_kit "${bin_dir}/${cmd}" \
              "${a2c_url}" \
              "${a2c_home}/${a2c_zip}.zip" \
              "${a2c_tmp}" \
							"no"
	[ 0 -eq $? ] || return $?

	if `check_kit "${a2c_check}" "${a2c_tmp}/${a2c_zip}"`; then
		cp "${a2c_tmp}/${a2c_zip}/${exe}" "${bin_dir}" \
			&& rm -rf "${a2c_home}"
	fi
}


install_autoruns() {
  local ar_zip="Autoruns.zip"  
  local ar_url="https://download.sysinternals.com/files/${ar_zip}"
	local arch="`check_arch`"
  local cmd="autorunsc${arch}"
  local ar_home="${TMP_DIR}/${cmd}"
	local ar_tmp="${ar_home}/bin"
  local bin_dir="${RUN_DIR}/bin"
	local exe="${cmd}.exe"
	local ar_check="${exe}"
	local clean="no"
	
	if ! `check_kit "${ar_check}"`; then
		if `check_kit "${ar_check}" "${ar_tmp}"`; then
			cp "${ar_tmp}/${exe}" "${bin_dir}" \
				 && cp "${ar_tmp}/Autoruns${arch}".* "${bin_dir}"
			[ 0 -eq $? ] && rm -rf "${ar_home}"
		fi
	else
		return 0
	fi

  install_kit "${bin_dir}/${cmd}" \
              "${ar_url}" \
              "${ar_home}/${ar_zip}" \
              "${ar_tmp}" \
							"${clean}"
  [ 0 -eq $? ] ||  return $?
	
	if `check_kit "${ar_check}" "${ar_tmp}"`; then
		cp "${ar_tmp}/${exe}" "${bin_dir}" \
			&& cp "${ar_tmp}/Autoruns${arch}".* "${bin_dir}"
		[ 0 -eq $? ] && rm -rf "${ar_home}"
	fi
}


install_procexp() {
  local p_zip="ProcessExplorer.zip"  
  local p_url="https://download.sysinternals.com/files/${p_zip}"
  local p_home="${OPEN_DIR}/procexp"
  local bin_dir="${p_home}/bin"
  local cmd="file ${bin_dir}/procexp.exe"

  `type -p procexp &>/dev/null` && return 0

  mkdir -p "${p_home}"

  install_kit "${bin_dir}/procexp.exe" \
              "${cmd}" \
              "${p_url}" \
              "${p_home}/${p_zip}" \
              "${bin_dir}" \
    || return $?
  
  if `${cmd} &>/dev/null`; then
    append_kit_path "${bin_dir}" "${p_home}"
  else
    return 1
  fi
}

install_netcat() {
  local nc_zip="netcat-win32-1.12.zip"
  local nc_url="https://eternallybored.org/misc/netcat/${nc_zip}"
  local nc_home="${OPEN_DIR}/netcat"
  local bin_dir="${nc_home}/bin"
  local cmd="file ${bin_dir}/nc.exe"
  
  `type -p nc &>/dev/null` && return 0
  mkdir -p "${nc_home}"

  install_kit "${bin_dir}/nc.exe" \
              "${cmd}" \
              "${nc_url}" \
              "${nc_home}/${nc_zip}" \
              "${bin_dir}" \
    || return $?

  if `${cmd} &>/dev/null`; then
    append_kit_path "${bin_dir}" "${nc_home}"
  else
    return 1
  fi
}

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


function usage() {
  echo -e "Usage: $(basename $0) [OPTIONS] COMMAND [arg...]"
  echo -e "       $(basename $0) [ -h | --help | -v | --version ]\n"
  echo -e "Options:"
  echo -e "  --help               Print this message"
  echo -e "  --version            Print version information and quit"
  echo -e ""
  echo -e "  --install-aria2c     install aria2c"
  echo -e "  --install-autoruns   install autoruns"
  echo -e "  --tomcat-version=    tomcat version, VER${VER:+='$VER'}"
  echo -e "  --catalina-options=  catalina options, CATALINA_OPTS='${CATALINA_OPTS}'"
  echo -e "  --download-only      download tomcat tgz file only, DOWNLOAD_ONLY='$DOWNLOAD_ONLY'"
  echo -e ""
  echo -e "  --listen-on=         listen on what address, LISTEN_ON='${LISTEN_ON}'"
  echo -e "  --ip-version=        prefered IP protocol version, IP_VER='${IP_VER}'"
  echo -e "  --stop-timeout=      force waiting STOP_TIMEOUT='$STOP_TIMEOUT' seconds before stop"
  echo -e "  --start-port=        tomcat start port, START_PORT='${START_PORT}'"
  echo -e "  --stop-port=         tomcat stop port, STOP_PORT='${STOP_PORT}'"
  echo -e "  --jpda-port=         tomcat debug port, JPDA_PORT='${JPDA_PORT}'"
}

for option
do
  opt="$opt `echo $option | sed -e \"s/\(--[^=]*=\)\(.* .*\)/\1'\2'/\"`"
  
  case "$option" in
    -*=*) value=`echo "$option" | sed -e 's/[-_a-zA-Z0-9]*=//'` ;;
    *) value="" ;;
  esac
  
  case "$option" in
    --help)                  help=yes                   ;;
    --version)               version=yes      			    ;;

    --install-aria2c)        aria2c="yes"               ;;
    --install-autoruns)      autoruns="yes"             ;;
    --catalina-options=*)    catalina_opts="$value"     ;;
    --download-only=*)       download_only="$value"     ;;

    --listen-on=*)           LISTEN_ON="$value"         ;;
    --ip-version=*)          ip_ver="$value"            ;;
    --stop-timeout=*)        STOP_TIMEOUT="$value"		  ;;
    --start-port=*)          START_PORT="$value"			  ;;
    --stop-port=*)           STOP_PORT="$value" 			  ;;
    --jpda-port=*)           JPDA_PORT="$value"  			  ;;

    *)
			case "$option" in
				-*)
					echo "$0: error: invalid option \"$option\""
					exit 1
				;;

				*) 
      		command="$option"
				;;
			esac
    ;;
  esac
done

if [ "yes" = "$help" -o 0 -eq $# ]; then
	usage
	exit 0
fi

if [ "yes" = "$version" ]; then
	echo -e "$VERSION"
	exit 0
fi

if [ "yes" = "$autoruns" ]; then
	install_autoruns
fi

if [ "yes" = "$aria2c" ]; then
	install_aria2c
fi
# HAS_ALL=${HAS_ALL:-"NO"}
# HAS_AUTORUNS=${HAS_AUTORUNS:-0}
# HAS_EMACS=${HAS_EMACS:-0}
# HAS_EMACS_SOURCE=${HAS_EMACS_SOURCE:-0}
# HAS_PSTOOLS=${HAS_PSTOOLS:-0}
# HAS_PROCEXP=${HAS_PROCEXP:-0}
# HAS_NETCAT=${HAS_NETCAT:-0}
# HAS_GMAKE=${HAS_GMAKE:-0}

# if [ "YES" == "${HAS_ALL}" ]; then
# 	HAS_AUTORUNS=1
# 	HAS_EMACS=0
# 	HAS_EMACS_SOURCE=0
# 	HAS_PSTOOLS=1
# 	HAS_PROCEXP=1
# 	HAS_NETCAT=1
# 	HAS_GMAKE=1
# fi

# [ 0 -lt "${HAS_AUTORUNS}" ]       && KITS+=('install_autoruns')
# [ 0 -lt "${HAS_EMACS}" ]          && KITS+=('install_emacs')
# [ 0 -lt "${HAS_EMACS_SOURCE}" ]   && KITS+=('install_emacs_source')
# [ 0 -lt "${HAS_PSTOOLS}" ]        && KITS+=('install_pstools')
# [ 0 -lt "${HAS_PROCEXP}" ]        && KITS+=('install_procexp')
# [ 0 -lt "${HAS_NETCAT}" ]         && KITS+=('install_netcat')
# [ 0 -lt "${HAS_GMAKE}" ]          && KITS+=('install_gmake')

# for i in "${KITS[@]}"; do
#  echo_head " + ${i} ... "
#  ${i}
#  echo_tail $?
# done


