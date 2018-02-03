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

  `check_kit "${cmd}" "${p_home}"` && return 0

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
  if [ "no" = "$ECHO_QUIET" ]; then
    echo -n "$@"
  fi
}

echo_tail() {
  if [ "no" = "$ECHO_QUIET" ]; then
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

