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
  echo -e "  --tomcat-version\t\ttomcat version, default is $VER"
  echo -e "  --java-options\t\tjava options, JAVA_OPTS"
  echo -e "  --ipv4\t\t\t\tprefer IPv4 option"
  echo -e "  --listen-on\t\t\tlisten on what address: localhost,0.0.0.0,etc.,"
  echo -e "  --catalina-base\t\tcatalina base dir"
  echo -e "  --catalina-options\tcatalina options, CATALINA_OPTS"
  echo -e "  --stop-timeout\t\twaiting up n($STOP_TIMEOUT) seconds to stop"
  echo -e "  --start-port\t\t\ttomcat start port, default is $START_PORT"
  echo -e "  --stop-port\t\t\ttomcat stop port, default is $STOP_PORT"
  echo -e "  --jpda-port\t\t\ttomcat debug port, default is $JPDA_PORT\n"
  echo -e "A tiny-handy console for tomcat.\n"
  echo -e "Commands:"
  echo -e "  start\t\t\t\t\tstart a tomcat instance"
  echo -e "  stop\t\t\t\t\tstop a tomcat instance"
  echo -e "  debug\t\t\t\t\tstart a tomcat instance in debug mode"
  echo -e "  parameterize\t\t\tparameterize tomcat's configurations"
  echo -e "  check-env\t\t\t\tcheck environment"
  echo -e "  install\t\t\t\tinstall tomcat"
}

export_catalina_opts() {
  export CATALINA_OPTS=`echo "${CATALINA_OPTS}" | tr -s " "`
}

parameterize() {
  local server_xml="${CATALINA_BASE}/conf/server.xml"
  if [ -r "${server_xml}" ]; then
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
    
  else
    echo -e "artified ports failed, ${server_xml} no found, panic!"
    return 1
  fi
}

export_java_opts() {
  parameterize
  JAVA_OPTS="-Dstart.port=${START_PORT}      \
             -Dstop.port=${STOP_PORT}        \
             -Dlisten.address=${LISTEN_ON}   \
             ${JAVA_OPTS}"
  export JAVA_OPTS=`echo "${JAVA_OPTS}" | tr -s " "`
}

export_pid_var() {
  export CATALINA_PID="${CATALINA_PID:-${CATALINA_BASE%/}/logs/pid}"
}

check_env() {
  local pid=`check_pid`
  local run="Stopped"
  if [ 0 -eq `ps -p $pid &>/dev/null;echo $?` ]; then
    run="Running"
  fi
  echo -e "+ check Tomcat environment ...$run"
  echo -e "\tCATALINA_PID[$pid]=${CATALINA_PID}"
  echo -e "\tJPDA_PORT=${JPDA_PORT}"
  echo -e "\tJAVA_OPTS=${JAVA_OPTS}"
  echo -e "\tCATALINA_OPTS=${CATALINA_OPTS}"
  echo -e "\tCATALINA_BASE=${CATALINA_BASE}"
}

install_tomcat() {
  if [ 0 -eq `${CATALINA_BIN} version &>/dev/null; echo $?` ]; then
    echo -e "tomcat is good."
    return 0
  fi

  local tgz="apache-tomcat-${VER}.tar.gz"
  local major="${VER%%.*}"
	local url="http://archive.apache.org/dist/tomcat/tomcat-${major}/v${VER}/bin/${tgz}"

  [ -d "${CATALINA_BASE}" ] || mkdir -p "${CATALINA_BASE}"
  if [ ! -f "${CATALINA_BASE}/build.xml" ]; then
    cd "${PREFIX}" && \
    curl -sLO -C - "${url}" && \
    tar -xf "${tgz}" -C "${CATALINA_BASE}" --strip-components=1
  fi
   
  if [ 0 -eq `${CATALINA_BIN} version &>/dev/null; echo $?` ]; then
    echo -e "install tomcat successed."
    return 0
  fi
  
  echo -e "install tomcat failed, panic!"
  return 1
}

check_catalina_bin() {
  if [ -x "${CATALINA_BIN}" ]; then
    return 0
  else
    return 1
  fi
}

check_pid() {
	if [ -f "${CATALINA_PID}" ]; then
		cat "${CATALINA_PID}" 2>/dev/null
	else
		return 1
	fi
}

check_catalina_ver() {
  if `check_catalina_bin`; then
    "${CATALINA_BIN}" version
  else
    echo "checking ${CATALINA_BIN} ...failed, panic!"
	fi
}

stop_tomcat() {
  if `check_catalina_bin`; then
    "${CATALINA_BIN}" stop "${STOP_TIMEOUT}" "${STOP_FORCE}"
	else
  	echo -e "checking ${CATALINA_BIN} ...failed, panic!"
    return 1
  fi
}

start_tomcat() {
  if `check_catalina_bin`; then
    "${CATALINA_BIN}" start
    return $?
	else
  	echo -e "checking ${CATALINA_BIN} ...failed, panic!"
    return 1
  fi
}

debug_tomcat() {
  if `check_catalina_bin`; then
    JPDA_ADDRESS="${JPDA_PORT}" "${CATALINA_BIN}" jpda start
	else
  	echo -e "checking ${CATALINA_BIN} ...failed, panic!"
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

command="`echo $command | tr '[:upper:]' '[:lower:]'`"
case "$command" in
  parameterize)
    parameterize
    ;;
  check-env)
    check_env
    exit $?
    ;;
  start)
    start_tomcat
    exit $?
    ;;
  stop)
    stop_tomcat
    exit $?
    ;;
  debug)
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
