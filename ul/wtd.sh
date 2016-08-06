#!/bin/bash
#------------------------------------------------
# target: tomcat install/start/stop/debug
# author: junjiemars@gmail.com
#------------------------------------------------

PREFIX=${PREFIX:-"/opt/run/www/tomcat"}
VER=${VER:-"8.5.4"}
CATALINA_BASE=${CATALINA_BASE:-"${PREFIX%/}/${VER}"}

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

start_tomcat() {
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
  *) 
    usage
  ;;
esac

#echo "---------------------------------"
#echo "JAVA_OPTS=$JAVA_OPTS"
#echo "CATALINA_OPTS=$CATALINA_OPTS"
#echo "Tomcat {$RUN-${VER}} in $MODE mode"
