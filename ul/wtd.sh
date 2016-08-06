#!/bin/bash
#------------------------------------------------
# target: tomcat install/start/stop/debug
# author: junjiemars@gmail.com
#------------------------------------------------

PREFIX=${PREFIX:-"/opt/run/www/tomcat"}
VER=${VER:-"8.5.4"}
CATALINA_BASE=${CATALINA_BASE:-"${PREFIX%/}/${VER}"}
export CATALINA_PID=${CATALINA_PID:-"${CATALINA_BASE%/}/logs/pid"}

PLATFORM=`uname -s 2>/dev/null`
case "${PLATFORM}" in
  MSYS_NT*)
    VERSION_BIN="${CATALINA_BASE}/bin/version.bat"
    START_BIN="${CATALINA_BASE}/bin/startup.bat"
    SHUTDOWN_BIN="${CATALINA_BASE}/bin/shutdown.bat"
  ;;
  *)
    VERSION_BIN="${CATALINA_BASE}/bin/version.sh"
    START_BIN="${CATALINA_BASE}/bin/startup.sh"
    SHUTDOWN_BIN="${CATALINA_BASE}/bin/shutdown.sh"
  ;;
esac

KILL_TIMEOUT=${KILL_TIMEOUT:-10}
KILL_RETRY=${KILL_RETRY:-3}

RUN=${RUN:-"stop"}
DEBUG="${DEBUG:=0}"
MODE="NORMAL"
CATALINA_OPTS="${CATALINA_OPTS}"
JPDA=""
HTTP_PORT=${HTTP_PORT:=8080}
STOP_PORT=${STOP_PORT:=8005}
BASE=${BASE:="/opt/bin/tomcat"}

usage() {
  echo -e "Usage: $(basename $0) [OPTIONS] COMMAND [arg...]"
  echo -e "       $(basename $0) [ -h | --help | -v | --version ]\n"
  echo -e "Options:"
  echo -e "  -h, --help\t\tPrint usage"
  echo -e "  -v, --version\t\tPrint version information and quit\n"
  echo -e "A tiny-handy tool for tomcat.\n"
  echo -e "Commands:"
  echo -e "\tstart\t\tStart a tomcat instance"
  echo -e "\tstop\t\tStop a tomcat instance"
  echo -e "\tdebug\t\tStart a tomcat instance in debug mode"
  echo -e "\tinstall\t\tInstall tomcat"
}

install_tomcat() {
  if [ 0 -eq `${VERSION_BIN} &>/dev/null; echo $?` ]; then
    echo -e "tomcat is good."
    return 0
  fi

  if [ 0 -ne `ant -version &>/dev/null; echo $?` ]; then 
    echo -e "install tomcat needs Ant first, panic!"
    return 1
  fi

  local tgz="apache-tomcat-${VER}.tar.gz"
  local major="${VER%%.*}"
  local url="http://apache.fayea.com/tomcat/tomcat-${major}/v${VER}/bin/${tgz}"

  [ -d "${CATALINA_BASE}" ] || mkdir -p "${CATALINA_BASE}"
  if [ ! -f "${CATALINA_BASE}/build.xml" ]; then
    cd "${PREFIX}" && \
    curl -sLO -C - "${url}" && \
    tar -xf "${tgz}" -C "${CATALINA_BASE}" --strip-components=1
  fi
   
  if [ 0 -eq `${VERSION_BIN} &>/dev/null; echo $?` ]; then
    echo -e "install tomcat successed."
    return 0
  fi
  
  echo -e "install tomcat failed, panic!"
  return 1
}

show_version() {
  [ -x "${VERSION_BIN}" ] && "${VERSION_BIN}"
}

pid_exists() {
  ps -p"$1" &>/dev/null; echo $?
}

kill_tomcat() {
  local pid="$1"
  local cnt="${KILL_RETRY}"
  
  if [ -z "${pid}"]; then
    echo -e "kill tomcat failed, [pid:${pid}] no found, panic!"
    return 1
  fi

  while [ 0 -eq `pid_exists ${pid}` ]; do
    sleep "${KILL_TIMEOUT}"
    let cnt-=1
    [ 0 -ge "${cnt}" ] && break;
  done

  local signal=15
  while [ 0 -eq `pid_exists ${pid}` ]; do
    kill -${signal} "${pid}"
    sleep $(( 3*"${KILL_TIMEOUT}" ))
    let signal=9
  done
}

stop_tomcat() {
  local pid=`cat ${CATALINA_PID} 2>/dev/null`
  if [ -x "${SHUTDOWN_BIN}" ]; then
    "${SHUTDOWN_BIN}" || kill_tomcat "${pid}"
  else
    echo -e "shutdown tomcat failed, ${SHUTDOWN_BIN} no found, panic!"
  fi
}

start_tomcat() {
  if [ -x "${START_BIN}" ]; then
    "${START_BIN}"
  else
    echo -e "$start tomcat failed, ${START_BIN} no found, panic! "
  fi
}

#export CATALINA_BASE="${CATALINA_BASE:=${BASE}/${VER}}"
#export CATALINA_PID="${CATALINA_BASE}/pid"
#
#if [ "$DEBUG" -gt 0 ]; then
#    MODE="DEBUG"
#    JPDA=jpda
#    CATALINA_OPTS="${CATALINA_OPTS}             \
#        -XX:+HeapDumpOnOutOfMemoryError         \
#        -XX:HeapDumpPath=${CATALINA_BASE}/logs"
#fi
#export CATALINA_OPTS=$(echo $CATALINA_OPTS | tr -s " ")
#
#JAVA_OPTS="${JAVA_OPTS}                      \
#    -Dhttp.port=${HTTP_PORT}                 \
#    -Dshutdown.port=${STOP_PORT}             \
#    -Dcom.sun.management.jmxremote"
#export JAVA_OPTS=$(echo $JAVA_OPTS | tr -s " ")
#
#BIN="$CATALINA_BASE/bin/catalina.sh $JPDA"
#
#if [ "$#" -gt 0 ];then
#    RUN=$1
#fi
case ".$@" in
  .install)
    install_tomcat
  ;;
  .start)
    start_tomcat
  ;;
  .stop)
    stop_tomcat
  ;;
    #.stop) $BIN stop ;;
    #.start) $BIN start ;;
    #.run) $BIN run ;;
    #.debug) $BIN debug ;;
    #.version) $BIN version ;;
  .-v)
    show_version
  ;;
  .--version)
    show_version
  ;;
  .-h)
    usage
  ;;
  .--help)
    usage
  ;;
  .*) 
    usage
  ;;
esac

#echo "---------------------------------"
#echo "JAVA_OPTS=$JAVA_OPTS"
#echo "CATALINA_OPTS=$CATALINA_OPTS"
#echo "Tomcat {$RUN-${VER}} in $MODE mode"
