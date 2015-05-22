#!/bin/bash
VERSION=v7061
DEBUG="${DEBUG}0"
MODE="NORMAL"
JPDA=""
export CATALINA_BASE="/opt/web/tomcat/$VERSION"
JAVA_OPTS="$JAVA_OPTS -Dhttp.port=8080 -Dshutdown.port=8005 -Dcom.sun.management.jmxremote "
export JAVA_OPTS
##/usr/share/tomcat6/bin/catalina.sh jpda start
if [ "$DEBUG" -gt 0 ]; then
    MODE="DEBUG"
    JPDA=jpda
fi
$CATALINA_BASE/bin/catalina.sh $JPDA start

echo "---------------------------------"
echo "JAVA_OPTS=$JAVA_OPTS"
echo "CATALINA_OPTS=$CATALINA_OPTS"
echo "Tomcat $VERSION started in $MODE mode"
