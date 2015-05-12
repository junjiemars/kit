#!/bin/sh
VERSION=v6041
##DEBUG=0
MODE="NORMAL"

echo "vars: $#2"
export CATALINA_BASE="/opt/web/tomcat/$VERSION"
JAVA_OPTS="$JAVA_OPTS -Dhttp.port=8080 -Dshutdown.port=8005 -Dcom.sun.management.jmxremote "
export JAVA_OPTS
##/usr/share/tomcat6/bin/catalina.sh jpda start
if [ "$DEBUG" -eq 1 ]; then
    $CATALINA_BASE/bin/catalina.sh jpda start
    MODE="DEBUG"
fi

echo "---------------------------------"
echo "JAVA_OPTS=$JAVA_OPTS"
echo "CATALINA_OPTS=$CATALINA_OPTS"
echo "Tomcat $VERSION started in $MODE mode"
