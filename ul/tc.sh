#!/bin/bash
#------------------------------------------------
# target: tomcat console
# author: junjiemars@gmail.com
#------------------------------------------------

PLATFORM="`uname -s 2>/dev/null`"
OPT_RUN="${OPT_RUN:-/opt/run}"
PREFIX="${PREFIX:-${OPT_RUN%/}/www/tomcat}"
VERSION="1.1.3"

VER="${VER:-8.5.8}"
CATALINA_BASE="${CATALINA_BASE:-${PREFIX%/}/${VER}}"
CATALINA_OPTS="${CATALINA_OPTS}"

JAVA_OPTS="${JAVA_OPTS}"
IP4_OPT='-Djava.net.preferIPv4Stack=true'
LISTEN_ON=("localhost" "127.0.0.1" "0.0.0.0")

STOP_TIMEOUT="${STOP_TIMEOUT:-10}"
STOP_FORCE="${STOP_FORCE:--force}"

START_PORT=${START_PORT:-8080}
STOP_PORT=${STOP_PORT:-8005}
JPDA_PORT=${JPDA_PORT:-8000}



usage() {
  echo -e "Usage: $(basename $0) [OPTIONS] COMMAND [arg...]"
  echo -e "       $(basename $0) [ -h | --help | -v | --version ]\n"
  echo -e "Options:"
  echo -e "  --help\t\t\t\tPrint this message"
  echo -e "  --version\t\t\t\tPrint version information and quit"
  echo -e "  --prefix\t\t\t\tcatalina prefix dir"
  echo -e "  --tomcat-version\t\t\ttomcat version, default is $VER"
  echo -e "  --java-options\t\t\tjava options, JAVA_OPTS"
  echo -e "  --ipv4\t\t\t\tprefer IPv4 option"
  echo -e "  --listen-on\t\t\t\tlisten on what address: localhost,0.0.0.0,etc.,"
  echo -e "  --catalina-base\t\t\tcatalina base dir"
  echo -e "  --catalina-options\t\t\tcatalina options, CATALINA_OPTS"
  echo -e "  --stop-timeout\t\t\twaiting up n($STOP_TIMEOUT) seconds to stop"
  echo -e "  --start-port\t\t\t\ttomcat start port, default is $START_PORT"
  echo -e "  --stop-port\t\t\t\ttomcat stop port, default is $STOP_PORT"
  echo -e "  --jpda-port\t\t\t\ttomcat debug port, default is $JPDA_PORT\n"
  echo -e "A tiny-handy console for tomcat.\n"
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
  export CATALINA_OPTS=`echo "${CATALINA_OPTS}" | tr -s " "`
}

function parameterize() {
  local server_xml="${CATALINA_BASE}/conf/server.xml"
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
  JAVA_OPTS="-Dstart.port=${START_PORT}      \
             -Dstop.port=${STOP_PORT}        \
             -Dlisten.address=${LISTEN_ON}   \
             ${JAVA_OPTS}"
  export JAVA_OPTS=`echo "${JAVA_OPTS}" | tr -s " "`
}

function export_pid_var() {
  export CATALINA_PID="${CATALINA_PID:-${CATALINA_BASE%/}/logs/pid}"
}

function check_env() {
  local pid=`get_ip`
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
  local pid="`get_ip`"
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

function install_tomcat() {
  echo -e "+ install Tomcat[$VER] ..."
  if `check_exist`; then
    echo -e "# install Tomcat[$VER]  =existing"
    return 0
  fi

  local tgz="apache-tomcat-${VER}.tar.gz"
  local major="${VER%%.*}"
	local url="http://archive.apache.org/dist/tomcat/tomcat-${major}/v${VER}/bin/${tgz}"

  [ -d "${CATALINA_BASE}" ] || mkdir -p "${CATALINA_BASE}"

  if [ ! -f "${CATALINA_BASE}/bin/catalina.sh" ]; then

    if [ -f "${PREFIX}/$tgz" ]; then
      cd "${PREFIX}" && \
        tar -xf "${tgz}" -C "${CATALINA_BASE}" --strip-components=1
      if `check_exist`; then
        echo -e "# install Tomcat[$VER]  =succeed"
        return 0
      fi
    fi
    
    cd "${PREFIX}" && \
    curl -sLO -C - "${url}" && \
    tar -xf "${tgz}" -C "${CATALINA_BASE}" --strip-components=1
  fi
   
  if `check_exist`; then
    echo -e "# install Tomcat[$VER]  =succeed"
    return 0
  fi
  
  echo -e "! install Tomcat[$VER]  =failed"
  return 1
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

function get_ip() {
	if [ -f "${CATALINA_PID}" ]; then
		cat "${CATALINA_PID}" 2>/dev/null
	else
		return 1
	fi
}

function stop_tomcat() {
  local pid="`get_ip`"
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
    --tomcat-version=*)      tomcat_ver="$value"        ;;
    --catalina-base=*)       catalina_base="$value"     ;;
    --catalina-options=*)    catalina_opts="$value"		  ;;

    --java-options=*)        java_opts="$value"		      ;;
    --ipv4)                  ipv4=yes                   ;;
    --listen-on=*)           LISTEN_ON="$value"         ;;

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

if [ -n "$java_opts" ]; then
  JAVA_OPTS="${JAVA_OPTS:+$JAVA_OPTS }${java_opts}"
fi


export_pid_var
export_java_opts

retval=
command="`echo $command | tr '[:upper:]' '[:lower:]'`"
case "$command" in
  parameterize)
    parameterize
    ;;
  check-env)
    check_env
    exit $?
    ;;
  check-pid)
    check_pid
    exit $?
    ;;
  check-exist)
    check_exist
    exit $?
    ;;
  start)
    parameterize
    retval=$?
    [ 0 -eq $retval ] || exit $retval
    check_catalina_bin
    retval=$?
    [ 0 -eq $retval ] || exit $retval

    start_tomcat
    exit $?
    ;;
  stop)
    check_catalina_bin
    retval=$?
    [ 0 -eq $retval ] || exit $retval

    stop_tomcat
    exit $?
    ;;
  debug)
    parameterize
    retval=$?
    [ 0 -eq $retval ] || exit $retval
    check_catalina_bin
    retval=$?
    [ 0 -eq $retval ] || exit $retval

    CATALINA_OPTS="${CATALINA_OPTS:+$CATALINA_OPTS }-XX:+HeapDumpOnOutOfMemoryError"
    CATALINA_OPTS="${CATALINA_OPTS:+$CATALINA_OPTS }-XX:HeapDumpPath=${CATALINA_BASE}/logs"
    export_catalina_opts
    debug_tomcat
    exit $?
    ;;
  install)
    install_tomcat
    exit $?    
    ;;
  *)
    echo "$0: error: invalid command \"$command\""
		usage
    exit 1    
    ;;
esac
