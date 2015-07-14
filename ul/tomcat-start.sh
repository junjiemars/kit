#!/bin/bash

RUN=${RUN:="stop"}
VER="${VER:=7062}"
DEBUG="${DEBUG:=0}"
MODE="NORMAL"
CATALINA_OPTS="${CATALINA_OPTS}"
JPDA=""
HTTP_PORT=${HTTP_PORT:=8080}
STOP_PORT=${STOP_PORT:=8005}
BASE=${BASE:="/opt/bin/tomcat"}

export CATALINA_BASE=${CATALINA_BASE:="${BASE}/${VER}"}

if [ "$DEBUG" -gt 0 ]; then
    MODE="DEBUG"
    JPDA=jpda
    CATALINA_OPTS="${CATALINA_OPTS}             \
        -XX:+HeapDumpOnOutOfMemoryError         \
        -XX:HeapDumpPath=${CATALINA_BASE}/logs"
fi
CATALINA_OPTS=$(echo $CATALINA_OPTS | tr -s " ")

JAVA_OPTS="${JAVA_OPTS}                      \
    -Dhttp.port=${HTTP_PORT}                 \
    -Dshutdown.port=${STOP_PORT}             \
    -Dcom.sun.management.jmxremote"
JAVA_OPTS=$(echo $JAVA_OPTS | tr -s " ")
BIN="$CATALINA_BASE/bin/catalina.sh $JPDA"

if [ "$#" -gt 0 ];then
    RUN=$1
fi
case ".$RUN" in
    ".stop") $BIN stop ;;
    ".start") $BIN start ;;
    *) echo "#unknown command:$RUN" ;;
esac

echo "---------------------------------"
echo "JAVA_OPTS=$JAVA_OPTS"
echo "CATALINA_OPTS=$CATALINA_OPTS"
echo "Tomcat $VER {$RUN} in $MODE mode"
