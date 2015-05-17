#!/bin/sh
VERSION=v6041
##DEBUG=0
MODE="NORMAL"

export CATALINA_BASE="/opt/web/tomcat/$VERSION"
JAVA_OPTS="$JAVA_OPTS -Dshutdown.port=8005"
export JAVA_OPTS
##/usr/share/tomcat6/bin/catalina.sh jpda stop
if [ "$DEBUG" -eq 1 ]; then
    $CATALINA_BASE/bin/catalina.sh jpda stop
    MODE="DEBUG"
fi

echo "---------------------------------"
echo "JAVA_OPTS=$JAVA_OPTS"
echo "CATALINA_OPTS=$CATALINA_OPTS"
echo "Tomcat $VERSION stopped in $MODE mode"
