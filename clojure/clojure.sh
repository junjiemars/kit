#!/bin/bash

CLOJURE_JAR=
PORT=${PORT:-"9900"}

[ 0 -eq `type -p rlwrap &>/dev/null;echo $?` ] && RLWRAP=rlwrap

if [ -z "$PORT" ]; then
  ${RLWRAP} java -cp ${CLOJURE_JAR} clojure.main
else
  ${RLWRAP} java -cp ${CLOJURE_JAR} \
    -Dclojure.server.repl="{:port $PORT :accept clojure.core.server/repl}" \
    clojure.main
fi
