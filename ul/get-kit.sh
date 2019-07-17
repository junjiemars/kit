#!/bin/bash
#------------------------------------------------
# target: download and configure kit via web
# author: junjiemars@gmail.com
# source: https://github.com/junjiemars/kits
#------------------------------------------------

PLATFORM="`uname -s 2>/dev/null`"
MACHINE="`uname -m 2>/dev/null`"
ECHO_QUIET=${ECHO_QUIET:-no}
ECHO_LOG="${ECHO_LOG:-${TMP%/}/`basename ${0}`.log}"

inside_kit_bash_env_p() {
  echo $INSIDE_KIT_BASH_ENV | grep 'junjiemars/kit' &>/dev/null
}

on_windows_nt() {
  case "$PLATFORM" in
    MSYS_NT*|MINGW*) 
      return 0 
    ;;
  *) 
    return 1 
  ;;
  esac
}

on_darwin() {
  case "$PLATFORM" in
    Darwin) 
      return 0
    ;;
    *)
      return 1
    ;;
  esac
}

if `on_windows_nt`; then
 if [ -d "/d/" ]; then
   PREFIX="${PREFIX:-/d/opt}"
 else
   PREFIX="${PREFIX:-/c/opt}"
 fi
else
 PREFIX="${PREFIX:-/opt}"
fi


RUN_DIR="${OPT_RUN:-${PREFIX}/run}"
OPEN_DIR="${OPT_OPEN:-${PREFIX}/open}"
TMP_DIR="${TMP:-${PREFIX}/tmp}"

SED_OPT_I="-i.pre"
if `on_darwin`; then
  SED_OPT_I="-i .pre"
fi

CURL_OPTS="${CURL_OPTS:--f}"

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

save_as() {
  local f="$1"
	local ori="${f}.ori"
  local pre="${f}.pre"

  if [ -f ${f} ]; then
		if [ -f ${ori} ]; then
      cp $f $pre
    else
      cp $f $ori
    fi
  fi
}

append_kit_path() {
  local name="PATH"
  local val="\${PATH:+\$PATH:}$1"
  local flag="$2"
  local var="${name}=\"${val}\""
  local f_paths="$HOME/.bash_paths"
  
  if `inside_kit_bash_env_p` && test -f "${f_paths}"; then
    save_as "${f_paths}"
    if `grep "^${name}=\".*${flag}.*\"" "${f_paths}" &>/dev/null`; then
      sed $SED_OPT_I -e "s#^${name}=\".*${flag}\"#${var}#g" "${f_paths}"
    else
      echo -e "${var}" >> "${f_paths}"
    fi
  else
    return 0
  fi
}

append_kit_var() {
 local name="$1"
 local val="$2"
 local f_vars="$HOME/.bash_vars"
 local var="export ${name}='${val}'"

 if `inside_kit_bash_env_p`; then
   if `grep "^export ${name}='.*'" "${f_vars}" &>/dev/null`; then
     sed $ "s#^export ${name}='.*'#${var}#g" "${f_vars}"
   else
     echo -e "${var}" >> "${f_vars}"
   fi
   . "${f_vars}"   
 else
   return 0
 fi
}

download_kit() {
  local url="$1"
  local fn="$2"
  local d="`dirname $fn`"
  local t=0

  [ -d "$d" ] || mkdir -p "$d"
  curl $CURL_OPTS -L -o "${fn}" -C - "${url}"
  t=$?
  if [ 33 -eq $t ]; then
    curl $CURL_OPTS -L -o "${fn}" "${url}"
  elif [ 60 -eq $t -o 22 -eq $t ]; then
    [ -f "${fn}" ] && rm "${fn}"
    curl $CURL_OPTS -k -L -o "${fn}" "${url}"
  else
    return $t
  fi
}

extract_kit() {
  local src="$1"
  local dst="$2"
  local clean="${3:-yes}"
  local x="${src##*.}"
  local t=0

  if test -d "${dst}"; then
		test "yes" = "${clean}" && rm -rf "${dst}"
	else
		mkdir -p "${dst}"		
  fi
  
  case "$x" in
    gz|tgz)
      tar xf "${src}" -C "${dst}" --strip-components=1
      ;;
    zip)
      cd `dirname ${src}` && unzip -q -o "${src}" -d"${dst}"
      ;;
    jar)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

install_kit() {
  local cmd="$1"
  local url="$2"
  local src="$3"
  local dst="$4"
	local clean="$5"

  if `test -f "${src}"`; then
		extract_kit "${src}" "${dst}" "${clean}"
	fi

  if `download_kit "$url" "$src"`; then
    extract_kit "${src}" "${dst}" "${clean}"
  else
    return 1
  fi
}

check_kit() {
  local cmd="$1"
  local home="$2"
	local ver="$3"

  if `${cmd} &>/dev/null` || `${home%/}/${cmd} &>/dev/null`; then
		if [ -n "$ver" ]; then
			test "`${cmd} 2>/dev/null`" = "$ver"
		else
    	return 0
		fi
	else
    return 1
  fi
}

kit_version() {
  local ver=()
  IFS='.' read -a ver <<< "$1"
  echo "${ver[@]}"
}

kit_major_version() {
  local ver=(`kit_version $1`)
  if [ 0 -lt ${#ver} ]; then
    echo "${ver[0]}"
  else
    echo "${ver}"
  fi
}

check_git_repo() {
  local d="$1"
  local f="$2"
  [ -d "$d" ] || return 1
	cd $d && git remote -v 2>/dev/null | grep "$f" &>/dev/null
}

check_git_branch() {
  local d="$1"
  [ -d "$d" ] || return 1
  cd $d && git rev-parse --abbrev-ref HEAD
}

call_git() {
  local repo="$1"
  local argv="${@:2}"
  if [ "no" = "${ECHO_QUIET}" ]; then
    cd ${repo} && git ${argv}
  else
    cd ${repo} && git ${argv} &>> ${ECHO_LOG}
  fi
}

if [ -f "${ECHO_LOG}" ]; then
  rm "${ECHO_LOG}"
fi

export INCLUDE_GET_KIT="yes"
