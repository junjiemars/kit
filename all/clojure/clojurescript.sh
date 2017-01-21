#!/bin/bash

CLOJURESCRIPT_JAR=

[ 0 -eq `type -p rlwrap &>/dev/null;echo $?` ] && RLWRAP=rlwrap

${RLWRAP} java -jar ${CLOJURESCRIPT_JAR} $@

