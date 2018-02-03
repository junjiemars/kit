#!/bin/bash
#------------------------------------------------
# target: install java programming environment
# author: junjiemars@gmail.com
# source: https://github.com/junjiemars/kits
#------------------------------------------------

PLATFORM="`uname -s 2>/dev/null`"
MACHINE="`uname -m 2>/dev/null`"

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
  local t=0

  curl $CURL_OPTS -L -o "${fn}" -C - "${url}"
  t=$?
  if [ 33 -eq $t ]; then
    curl $CURL_OPTS -L -o "${fn}" "${url}"
  elif [ 60 -eq $t ]; then
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

  if test -d "${dst}" && test "yes" = "${clean}"; then
    rm -r "${dst}"
  fi
  mkdir -p "${dst}"
  
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
  local bin="$1"
  local cmd="$2"
  local url="$3"
  local src="$4"
  local dst="$5"

  if `test -f "${bin}"`; then
		$cmd &>/dev/null && return 0
	fi

  if `test -f "${src}"` && `extract_kit "${src}" "${dst}"`; then
    $cmd &>/dev/null && return 0
	fi

  if `download_kit "$url" "$src"`; then
    extract_kit "${src}" "${dst}"
  else
    return 1
  fi
}

check_kit() {
  local cmd="$1"
  local home="$2"

  if `${cmd} &>/dev/null`; then
    return 0
  else
    [ -d "${home}" ] || mkdir -p "${home}"
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

export INCLUDE_GET_KIT="yes"
