#!/bin/bash

CLOJURESCRIPT_JAR=
PORT=${PORT:-"9900"}

[ 0 -eq `type -p rlwrap &>/dev/null;echo $?` ] && RLWRAP=rlwrap

${RLWRAP} java -jar ${CLOJURESCRIPT_JAR} $@

