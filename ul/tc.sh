#!/bin/bash
#------------------------------------------------
# target: tomcat console
# author: junjiemars@gmail.com
#------------------------------------------------

PLATFORM="`uname -s 2>/dev/null`"
OPT_RUN="${OPT_RUN:-/opt/run}"
PREFIX="${PREFIX:-${OPT_RUN%/}/www/tomcat}"
VERSION="1.2.0"

VER="${VER:-8.5.8}"
CATALINA_BASE="${CATALINA_BASE:-${PREFIX%/}/${VER}}"
CATALINA_OPTS="${CATALINA_OPTS}"

JAVA_OPTS="${JAVA_OPTS}"

STOP_TIMEOUT="${STOP_TIMEOUT:-10}"
STOP_FORCE="${STOP_FORCE:--force}"

IP_VER=("4" "6")
IP_IDX=
IP_OPTS=("-Djava.net.preferIPv4Stack=true" "-Djava.net.preferIPv6Addresses=true")

LISTEN_ON=("localhost" "127.0.0.1" "0.0.0.0")
START_PORT=${START_PORT:-8080}
STOP_PORT=${STOP_PORT:-8005}
JPDA_PORT=${JPDA_PORT:-8000}

DOWNLOAD_ONLY=("no" "yes")


usage() {
  echo -e "Usage: $(basename $0) [OPTIONS] COMMAND [arg...]"
  echo -e "       $(basename $0) [ -h | --help | -v | --version ]\n"
  echo -e "Options:"
  echo -e "  --help\t\t\t\tPrint this message"
  echo -e "  --version\t\t\t\tPrint version information and quit"
  echo -e ""
  echo -e "  --prefix=\t\t\t\tcatalina prefix dir, default PREFIX='${PREFIX}'"
  echo -e "  --java-options=\t\t\tjava options, default JAVA_OPTS='${JAVA_OPTS}'"
  echo -e "  --tomcat-version=\t\t\ttomcat version, default VER${VER:+='$VER'}"
  echo -e "  --catalina-base=\t\t\tcatalina base dir, CATALINA_BASE='${CATALINA_BASE}'"
  echo -e "  --catalina-options=\t\t\tcatalina options, CATALINA_OPTS='${CATALINA_OPTS}'"
  echo -e "  --download-only\t\t\tdownload tomcat tgz file only"
  echo -e ""
  echo -e "  --listen-on=\t\t\t\tlisten on what address: `echo ${LISTEN_ON[@]}|tr ' ' ','`, etc.,"
  echo -e "  --ip-version=\t\t\t\tprefered IP protocol version: `echo ${IP_VER[@]}|tr ' ' ','`, default is $IP_VER"
  echo -e "  --stop-timeout=\t\t\tforce stop waiting most $STOP_TIMEOUT seconds"
  echo -e "  --start-port=\t\t\t\ttomcat start port, default START_PORT='${START_PORT}'"
  echo -e "  --stop-port=\t\t\t\ttomcat stop port, default STOP_PORT='${STOP_PORT}'"
  echo -e "  --jpda-port=\t\t\t\ttomcat debug port, default JPDA_PORT='${JPDA_PORT}'"
  echo -e ""
  echo -e "A tiny-handy console for tomcat."
  echo -e ""
  echo -e "Commands:"
  echo -e "  start\t\t\t\t\tstart a tomcat instance"
  echo -e "  stop\t\t\t\t\tstop a tomcat instance"
  echo -e "  debug\t\t\t\t\tstart a tomcat instance in debug mode"
  echo -e "  parameterize\t\t\t\tparameterize tomcat's configurations"
  echo -e "  check-env\t\t\t\tcheck environment of specified tomcat instance"
  echo -e "  check-pid\t\t\t\tcheck pid of specified tomcat instance"
  echo -e "  check-exist\t\t\t\tcheck existing of tomcat installation"
  echo -e "  install\t\t\t\tinstall tomcat"
}


function export_catalina_opts() {
  export CATALINA_OPTS="`echo ${CATALINA_OPTS} | tr -s ' '`"
}


function parameterize() {
  local base_dir="$1"
  local server_xml="${base_dir%/}/conf/server.xml"
  echo -e "+ parameterize Tomcat[server.xml] ..."

  if [ ! -w "${server_xml}" ]; then
    echo -e "! parameterize Tomcat[server.xml]: file no found  =failed"
    return 1
  fi

  local stop_soft='<Server port="\${stop\.port}" shutdown="SHUTDOWN">'
  local start_soft='<Connector port="\${start\.port}" protocol="HTTP\/1\.[10]"'
  local addr_soft='<Connector port="\${start\.port}" protocol="HTTP\/1\.[10]" address="\${listen.address}"'
  local stop_old='<Server port="\([0-9]*\)" shutdown="SHUTDOWN">'
  local stop_new='<Server port="\${stop\.port}" shutdown="SHUTDOWN">'
  local start_old='<Connector port="\([0-9]*\)" protocol="HTTP'
  local start_new='<Connector port="\${start\.port}" protocol="HTTP'
  local addr_old='<Connector port="\(.*\)" protocol="\(HTTP\/1\.[10]\)"'
  local addr_new='<Connector port="\1" protocol="\2" address="\${listen.address}"'

  [ -f "${server_xml}.ori" ] || cp "${server_xml}" "${server_xml}.ori"
  
  if [ 0 -ne `grep "${stop_soft}" "${server_xml}" &>/dev/null; echo $?` ]; then
    sed -i -e "s/${stop_old}/${stop_new}/" "${server_xml}"
  fi

  if [ 0 -ne `grep "${start_soft}" "${server_xml}" &>/dev/null; echo $?` ]; then
    sed -i -e "s/${start_old}/${start_new}/" "${server_xml}"
  fi

  if [ 0 -ne `grep "${addr_soft}" "${server_xml}" &>/dev/null; echo $?` ]; then
    sed -i -e "s/${addr_old}/${addr_new}/" "${server_xml}"
  fi

  echo -e "# parameterize Tomcat[server.xml]  =succeed"
  return 0
}


function export_java_opts() {
	local opts="$@"
  opts="-Dstart.port=${START_PORT}      \
				-Dstop.port=${STOP_PORT}        \
				-Dlisten.address=${LISTEN_ON}   \
        ${opts}"
	opts="`echo $opts | tr -s ' '`"
  export JAVA_OPTS="$opts"
}


function export_pid_var() {
  export CATALINA_PID="${CATALINA_PID:-${CATALINA_BASE%/}/logs/pid}"
}


function check_env() {
  local pid="`get_pid`"
  local run="Stopped"
  local t=

  if [ 0 -eq `ps -p $pid &>/dev/null;echo $?` ]; then
    run="Running"
  fi

  echo -e "+ check Tomcat environment [$pid] ...$run"
  echo -e "+ check Tomcat version ..."

  check_catalina_bin
  t=$?
  if [ 0 -eq $t ]; then
    echo -e "# check Tomcat version  =succeed"
    ${CATALINA_BIN} version
    return $?
  else
    echo -e "! check Tomcat version  =failed"
    return 1
  fi
}


function check_pid() {
  local pid="`get_pid`"
  local t=

  echo "$pid"
  if [ 0 -eq `ps -p $pid &>/dev/null;echo $?` ]; then
    return 0
  else
    return 1
  fi
}


function check_exist() {
  ${CATALINA_BIN} version &>/dev/null
}


function verify_tgz() {
  local lhs="$1"
  local rhs="$2"

  echo -e "+ verify Tomcat[$rhs] ..."

  if [ ! -f "$lhs" -o ! -f "$rhs" ]; then
    echo -e "! verify Tomcat[$rhs]  =failed"
    return 1
  fi

  local rsha1="`cat $rhs | cut -d' ' -f1`"
  if [ -z "$rsha1" ]; then
   echo -e "! verify Tomcat[$rhs]  =failed"
   return 1
  fi

  local lsha1="`sha1sum $lhs 2>/dev/null | cut -d' ' -f1`"
  if [ "$lsha1" = "$rsha1" ]; then
    echo -e "# verify Tomcat[$rhs]  =succeed"
    return 0
  else
    echo -e "! verify Tomcat[$rhs]  =failed"
    return 1
  fi
}


function download_file() {
  local d="$1"
  local lf="$2"
  local rf="$3"
  local t=

  echo -e "+ download Tomcat[$rf] ..."
  cd "$d" && curl -sL -o"${lf}" -C - "${rf}"
  t=$?
  if [ 33 -eq $t ]; then
    cd "$d" && curl -sL -o"${lf}" "${rf}"
  fi

  if [ 0 -ne $t ]; then
    echo -e "! download Tomcat[$rf]  =failed"
  else
    echo -e "# download Tomcat[$rf]  =succeed"    
  fi

  return $t
}


function download_tomcat() {
  local d="$1"
  local ltgz="$2"
  local ltgz_sha1="$3"
  local rtgz="$4"
  local rtgz_sha1="$5"
  local t=

  verify_tgz "$ltgz" "$ltgz_sha1"
  t=$?
  if [ 0 -ne $t ]; then
    download_file "$d" "$ltgz_sha1" "$rtgz_sha1"
    t=$?
    [ 0 -eq $t ] || return $t

    verify_tgz "$ltgz" "$ltgz_sha1"
    t=$?
    [ 0 -ne $t ] || return $t

    download_file "$d" "$ltgz" "$rtgz"
    t=$?
    [ 0 -eq $t ] || return $t
    
    verify_tgz "$ltgz" "$ltgz_sha1"
    t=$?
    return $t
  fi
}


function tomcat_tgz() {
  local ver="$1"
  local tgz="apache-tomcat-${ver}.tar.gz"
  echo "$tgz"
}


function tomcat_tgz_sha1() {
  local ver="$1"
  local sha1="`tomcat_tgz $ver`.sha1"
  echo "$sha1"
}


function tomcat_tgz_path() {
  local h="$1"
  local v="$2"
  local p="${h%/}/`tomcat_tgz $v`"
  echo "$p"
}


function tomcat_tgz_sha1_path() {
  local h="$1"
  local v="$2"
  local p="${h%/}/`tomcat_tgz_sha1 $v`"
  echo "$p"
}


function install_tomcat() {
  local tgz="`tomcat_tgz ${VER}`"
  local tgz_sha1="`tomcat_tgz_sha1 ${VER}`"
  local major="${VER%%.*}"
  local head="https://archive.apache.org/dist/tomcat/tomcat-${major}/v${VER}/bin"
	local url_tgz="${head}/${tgz}"
  local url_sha1="${head}/${tgz_sha1}"
  local ltgz="`tomcat_tgz_path ${PREFIX} ${VER}`"
  local ltgz_sha1="`tomcat_tgz_sha1_path ${PREFIX} ${VER}`"
  local t=

  echo -e "+ install Tomcat[$VER] ..."

  if [ "yes" = "$DOWNLOAD_ONLY" ]; then
    verify_tgz "$ltgz" "$ltgz_sha1"
    t=$?
    if [ 0 -eq $t ]; then
      return $t
    else
      download_tomcat "$PREFIX" "$ltgz" "$ltgz_sha1" "$url_tgz" "$url_sha1"
      t=$?
      if [ 0 -eq $t ]; then
        verify_tgz "$ltgz" "$ltgz_sha1"
        t=$?
      fi
      return $t
    fi
  fi

  echo -e "+ check Tomcat[$VER] existing ..."
  if `check_exist`; then
    echo -e "# check Tomcat[$VER] existing  =succeed"
    echo -e "# install Tomcat[$VER]  =succeed"
    return 0
  fi
  echo -e "! check Tomcat[$VER] existing  =failed"
  
  verify_tgz "$ltgz" "$ltgz_sha1"
  t=$?
  if [ 0 -ne $t ]; then
    download_tomcat "$PREFIX" "$ltgz" "$ltgz_sha1" "$url_tgz" "$url_sha1"
    t=$?
    if [ 0 -ne $t ]; then
      echo -e "! install Tomcat[$VER]  =failed"
      return $t
    fi
  fi

  verify_tgz "$ltgz" "$ltgz_sha1"
  t=$?
  if [ 0 -ne $t ]; then
    echo -e "! install Tomcat[$VER]  =failed"
    return $t
  fi

  [ -d "${CATALINA_BASE}" ] || mkdir -p "${CATALINA_BASE}"
  tar -xf "${ltgz}" -C "${CATALINA_BASE}" --strip-components=1

  if `check_exist`; then
    echo -e "# install Tomcat[$VER]  =succeed"
    return 0
  else
    echo -e "! install Tomcat[$VER]  =failed"
    return 1
  fi
}

function check_catalina_bin() {
  echo -e "+ check CATALINA_BIN ..."
  if [ -x "${CATALINA_BIN}" ]; then
    echo -e "# check CATALINA_BIN  =succeed"
    return 0
  else
    echo -e "! check CATALINA_BIN  =failed"
    return 1
  fi
}


function get_pid() {
	if [ -f "${CATALINA_PID}" ]; then
		cat "${CATALINA_PID}" 2>/dev/null
	else
		return 1
	fi
}


function stop_tomcat() {
  local pid="`get_pid`"
  local t=
  echo -e "+ stop Tomcat[$pid] ..."
  "${CATALINA_BIN}" stop "${STOP_TIMEOUT}" "${STOP_FORCE}"
  t=$?
  if [ 0 -eq $t ]; then
    echo -e "# stop Tomcat[$pid]  =succeed"
  else
    echo -e "! stop Tomcat[$pid]  =failed"
  fi
  return $t
}


function start_tomcat() {
  "${CATALINA_BIN}" start
}


function debug_tomcat() {
  local t=
  echo -e "+ debug Tomcat ..."

  JPDA_ADDRESS="${JPDA_PORT}" "${CATALINA_BIN}" jpda start
  t=$?
  if [ 0 -eq $t ]; then
    echo -e "# debug Tomcat  =succeed"
    return $t
  else
    echo -e "! debug Tomcat  =failed"
    return 1
  fi
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

    --prefix=*)              prefix="$value"   			    ;;
    --java-options=*)        java_opts="$value"		      ;;
    --tomcat-version=*)      tomcat_ver="$value"        ;;
    --catalina-base=*)       catalina_base="$value"     ;;
    --catalina-options=*)    catalina_opts="$value"		  ;;
    --download-only)         DOWNLOAD_ONLY=yes      	  ;;

    --listen-on=*)           LISTEN_ON="$value"         ;;
    --ip-version=*)          ip_ver="$value"            ;;
    --stop-timeout=*)        STOP_TIMEOUT="$value"		  ;;
    --start-port=*)          START_PORT="$value"			  ;;
    --stop-port=*)           STOP_PORT="$value" 			  ;;
    --jpda-port=*)           JPDA_PORT="$value"  			  ;;

    *)
      command="$option"
    ;;
  esac
done


if [ "$help" = "yes" -o 0 -eq $# ]; then
	usage
	exit 0
fi

if [ "$version" = "yes" ]; then
	echo -e "$VERSION"
	exit 0
fi

# setup env vars

if [ -n "$prefix" ]; then
  PREFIX="$prefix"
  CATALINA_BASE="${PREFIX%/}/${VER}"
fi

if [ -n "$tomcat_ver" ]; then
  VER="$tomcat_ver"
  CATALINA_BASE="${PREFIX%/}/${VER}"
fi

if [ -n "$catalina_base" ]; then
  CATALINA_BASE="${catalina_base}"
fi

CATALINA_BIN="${CATALINA_BASE}/bin/catalina.sh"

if [ -n "$catalina_opts" ]; then
  CATALINA_OPTS="${CATALINA_OPTS:+$CATALINA_OPTS }${catalina_opts}"
fi

if [ "$ipv4" = "yes" ]; then
  JAVA_OPTS="${JAVA_OPTS:+$JAVA_OPTS }${IP4_OPT}"
fi

if [ -n "$ip_ver" ]; then
  for i in "${!IP_VER[@]}"; do
    if [ "$ip_ver" = "${IP_VER[$i]}" ]; then
      IP_IDX=$i
      break;
    fi
  done
  if [ -z "$IP_IDX" ]; then
    echo -e "! --ip-version=$ip_ver  =invalid"
    exit 1
  fi
  JAVA_OPTS="${JAVA_OPTS:+$JAVA_OPTS }${IP_OPTS[$IP_IDX]}"
fi


java_opts="${java_opts:+${java_opts} }${JAVA_OPTS}"
export_pid_var
export_java_opts "$java_opts"

retval=
command="`echo $command | tr '[:upper:]' '[:lower:]'`"
case "$command" in
  parameterize)
    parameterize "$CATALINA_BASE"
    ;;
  check-env)
    check_env
    ;;
  check-pid)
    check_pid
    ;;
  check-exist)
    check_exist
    ;;
  start)
    parameterize "$CATALINA_BASE"
    retval=$?
    [ 0 -eq $retval ] || exit $retval
    check_catalina_bin
    retval=$?
    [ 0 -eq $retval ] || exit $retval

    start_tomcat
    ;;
  stop)
    check_catalina_bin
    retval=$?
    [ 0 -eq $retval ] || exit $retval

    stop_tomcat
    ;;
  debug)
    parameterize "$CATALINA_BASE"
    retval=$?
    [ 0 -eq $retval ] || exit $retval
    check_catalina_bin
    retval=$?
    [ 0 -eq $retval ] || exit $retval

    CATALINA_OPTS="${CATALINA_OPTS:+$CATALINA_OPTS }-XX:+HeapDumpOnOutOfMemoryError"
    CATALINA_OPTS="${CATALINA_OPTS:+$CATALINA_OPTS }-XX:HeapDumpPath=${CATALINA_BASE}/logs"
    export_catalina_opts
    debug_tomcat
    ;;
  install)
    install_tomcat
    ;;
  verify)
    verify_tgz "`tomcat_tgz_path $PREFIX $VER`"        \
                 "`tomcat_tgz_sha1_path $PREFIX $VER`"
    ;;
  *)
    echo "$0: error: invalid command \"$command\""
		usage
    exit 1    
    ;;
esac
