#!/bin/bash

RUN=${RUN:="stop"}
VER="${VER:=7062}"
DEBUG="${DEBUG:=0}"
MODE="NORMAL"
DUMP="${DUMP:=0}"
HEAP_DUMP=""
JPDA=""
HTTP_PORT=${HTTP_PORT:=8080}
STOP_PORT=${STOP_PORT:=8005}
BASE=${BASE:="/opt/tomcat"}

export CATALINA_BASE=${CATALINA_BASE:="${BASE}/${VER}"}

if [ "$DUMP" -gt 0 ]; then
    HEAP_DUMP="-XX:+HeapDumpOnOutOfMemoryError  \
        -XX:HeapDumpPath=${CATALINA_BASE}/logs"
    HEAP_DUMP=$(echo $HEAP_DUMP | tr -s " ")
fi

if [ "$DEBUG" -gt 0 ]; then
    MODE="DEBUG"
    JPDA=jpda
fi

JAVA_OPTS="${JAVA_OPTS}                      \
    -Dhttp.port=${HTTP_PORT}                 \
    -Dshutdown.port=${STOP_PORT}             \
    -Dcom.sun.management.jmxremote           \
    ${HEAP_DUMP} "
JAVA_OPTS=$(echo $JAVA_OPTS | tr -s " ")

BIN="$CATALINA_BASE/bin/catalina.sh $JPDA"

if [ "$#" -gt 0 ];then
    RUN=$1
fi
case $RUN in
    "stop") $BIN stop ;;
    "start") $BIN start ;;
    *) echo "#unknown command:$RUN" ;;
esac

echo "---------------------------------"
echo "JAVA_OPTS=$JAVA_OPTS"
echo "CATALINA_OPTS=$CATALINA_OPTS"
echo "Tomcat $VER {$RUN} in $MODE mode"
