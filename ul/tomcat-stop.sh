#!/bin/bash
VERSION=v7062
DEBUG="${DEBUG:=0}"
MODE="NORMAL"
JPDA=""

export CATALINA_BASE="/opt/web/tomcat/$VERSION"
JAVA_OPTS="$JAVA_OPTS -Dshutdown.port=8005"
export JAVA_OPTS
##/usr/share/tomcat6/bin/catalina.sh jpda stop
if [ "$DEBUG" -gt 0 ]; then
    MODE="DEBUG"
    JPDA=jpda
fi
$CATALINA_BASE/bin/catalina.sh $JPDA stop

echo "---------------------------------"
echo "JAVA_OPTS=$JAVA_OPTS"
echo "CATALINA_OPTS=$CATALINA_OPTS"
echo "Tomcat $VERSION stopped in $MODE mode"
