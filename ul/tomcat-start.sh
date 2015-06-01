#!/bin/bash
VERSION=${VERSION:="v7062"}
DEBUG="${DEBUG:=0}"
MODE="NORMAL"
DUMP="${DUMP:=0}"
HEAP_DUMP=""
JPDA=""
export CATALINA_BASE=${CATALINA_BASE:="/opt/web/tomcat/${VERSION}"}

if [ "$DUMP" -gt 0 ]; then
    HEAP_DUMP="-XX:+HeapDumpOnOutOfMemoryError " \
        "-XX:HeapDumpPath=${CATALINA_BASE}/logs"
fi

JAVA_OPTS="$JAVA_OPTS "                 \
    "-Dhttp.port=8080 "                 \
    "-Dshutdown.port=8005 "             \
    "-Dcom.sun.management.jmxremote "   \
    "$HEAP_DUMP "
export JAVA_OPTS

if [ "$DEBUG" -gt 0 ]; then
    MODE="DEBUG"
    JPDA=jpda
fi

$CATALINA_BASE/bin/catalina.sh $JPDA start

echo "---------------------------------"
echo "JAVA_OPTS=$JAVA_OPTS"
echo "CATALINA_OPTS=$CATALINA_OPTS"
echo "Tomcat $VERSION started in $MODE mode"
