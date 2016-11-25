#!/bin/bash
#------------------------------------------------
# target: tomcat console
# author: junjiemars@gmail.com
#------------------------------------------------

OPT_RUN=${OPT_RUN:-"/opt/run"}
PREFIX=${PREFIX:-"${OPT_RUN%/}/www/tomcat"}
VER=${VER:-"8.5.4"}
CATALINA_BASE=${CATALINA_BASE:-"${PREFIX%/}/${VER}"}
export CATALINA_PID=${CATALINA_PID:-"${CATALINA_BASE%/}/logs/pid"}

PLATFORM=`uname -s 2>/dev/null`
CATALINA_BIN="${CATALINA_BASE}/bin/catalina.sh"

STOP_TIMEOUT=${STOP_TIMEOUT:-10}
STOP_FORCE=${STOP_FORCE:-"-force"}

CATALINA_OPTS=${CATALINA_OPTS}
JAVA_OPTS=${JAVA_OPTS}

START_PORT=${START_PORT:-8080}
STOP_PORT=${STOP_PORT:-8005}
JPDA_PORT=${JPDA_PORT:-8000}


export_catalina_opts() {
  CATALINA_OPTS="${1}${CATALINA_OPTS}"
  if [ -n "${CATALINA_OPTS}" ]; then
    export CATALINA_OPTS=`echo "${CATALINA_OPTS}" | tr -s " "`
  fi
}

artified_ports() {
  local server_xml="${CATALINA_BASE}/conf/server.xml"
  if [ -r "${server_xml}" ]; then
    local stop_soft='<Server port="\${stop\.port}" shutdown="SHUTDOWN">'
    local start_soft='<Connector port="\${start\.port}" protocol="HTTP'
    local stop_old='<Server port="\([0-9]*\)" shutdown="SHUTDOWN">'
    local stop_new='<Server port="\${stop\.port}" shutdown="SHUTDOWN">'
    local start_old='<Connector port="\([0-9]*\)" protocol="HTTP'
    local start_new='<Connector port="\${start\.port}" protocol="HTTP'

    [ -f "${server_xml}.ori" ] || cp "${server_xml}" "${server_xml}.ori"
    
    if [ 0 -ne `grep "${stop_soft}" "${server_xml}" &>/dev/null; echo $?` ]; then
       sed -i -e "s/${stop_old}/${stop_new}/" "${server_xml}"
    fi

    if [ 0 -ne `grep "${start_soft}" "${server_xml}" &>/dev/null; echo $?` ]; then
      sed -i -e "s/${start_old}/${start_new}/" "${server_xml}"
    fi
  else
    echo -e "artified ports failed, ${server_xml} no found, panic!"
  fi
}

export_java_opts() {
  artified_ports
  JAVA_OPTS="-Dstart.port=${START_PORT} \
             -Dstop.port=${STOP_PORT} \
             ${JAVA_OPTS}"
  export JAVA_OPTS=`echo "${JAVA_OPTS}" | tr -s " "`
}

show_env() {
  echo -e "---------------------------------"
  echo -e "CATALINA_PID[${1}]=${CATALINA_PID}"
  echo -e "JPDA_PORT=${JPDA_PORT}"
  echo -e "JAVA_OPTS=${JAVA_OPTS}"
  echo -e "CATALINA_OPTS=${CATALINA_OPTS}"
  echo -e "CATALINA_BASE=${CATALINA_BASE}"
}

install_tomcat() {
  if [ 0 -eq `${CATALINA_BIN} version &>/dev/null; echo $?` ]; then
    echo -e "tomcat is good."
    return 0
  fi

  if [ 0 -ne `ant -version &>/dev/null; echo $?` ]; then 
    echo -e "install tomcat needs Ant first, panic!"
    return 1
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

show_version() {
  if `check_catalina_bin`; then
    "${CATALINA_BIN}" version
	fi
}

stop_tomcat() {
  local pid=`check_pid`
  if `check_catalina_bin`; then
    export_java_opts
    "${CATALINA_BIN}" stop "${STOP_TIMEOUT}" "${STOP_FORCE}"
	else
  	echo -e "checking ${CATALINA_BIN} ...failed, panic!"
  fi
  show_env "${pid}"
}

start_tomcat() {
  if `check_catalina_bin`; then
    export_java_opts
    "${CATALINA_BIN}" start
	else
  	echo -e "checking ${CATALINA_BIN} ...failed, panic!"
  fi
  show_env "`check_pid`"
}

debug_tomcat() {
  if `check_catalina_bin`; then
    export_java_opts
    export_catalina_opts "-XX:+HeapDumpOnOutOfMemoryError \
                          -XX:HeapDumpPath=${CATALINA_BASE}/logs"
    JPDA_ADDRESS="${JPDA_PORT}" "${CATALINA_BIN}" jpda start
	else
  	echo -e "checking ${CATALINA_BIN} ...failed, panic!"
  fi
  show_env "`check_pid`"
}

usage() {
  echo -e "Usage: $(basename $0) [OPTIONS] COMMAND [arg...]"
  echo -e "       $(basename $0) [ -h | --help | -v | --version ]\n"
  echo -e "Options:"
  echo -e "  -h, --help\t\tPrint usage"
  echo -e "  -v, --version\t\tPrint version information and quit\n"
  echo -e "A tiny-handy console for tomcat.\n"
  echo -e "Commands:"
  echo -e "\tstart\t\tStart a tomcat instance"
  echo -e "\tstop\t\tStop a tomcat instance"
  echo -e "\tdebug\t\tStart a tomcat instance in debug mode"
  echo -e "\tinstall\t\tInstall tomcat"
}

case ".$@" in
  .install) install_tomcat ;;
  .start) start_tomcat ;;
  .stop) stop_tomcat ;;
  .debug) debug_tomcat ;;
  .-v|.--version) show_version ;;
  .-h|.--help) usage ;;
  .*) usage ;;
esac
