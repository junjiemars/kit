#!/bin/bash

PREFIX=${PREFIX:-'/opt/run/bin'}
OPEN_DIR=${OPEN_DIR:-'/opt/open'}
ANT_URL=${ANT_URL:-'https://github.com/apache/ant.git'}
BOOT_URL=${BOOT_URL:-'https://github.com/boot-clj/boot-bin/releases/download/latest/boot.sh '}

# install ant
ANT_HOME="${OPEN_DIR}/ant"
cd "${OPEN_DIR}" && \
git clone ${ANT_URL} && \
cd "${ANT_HOME}" && bash ./bootstrap.sh && \
echo -e "PATH=$PATH:$ANT_HOME" >> $HOME/.bash_paths

## install boot
#cd "${PREFIX}" && \
#curl -fsSLo boot ${BOOT_URL} && chmod 755 boot
