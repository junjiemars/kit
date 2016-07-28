#!/bin/bash

PREFIX=${PREFIX:-'/opt/run/bin'}
OPEN_DIR=${OPEN_DIR:-'/opt/open'}

HAS_ANT=${HAS_ANT:-0}
HAS_MAVEN=${HAS_MAVEN:-0}
HAS_BOOT=${HAS_BOOT:-0}
HAS_GRADLE=${HAS_GRADLE:-0}
HAS_GROOVY=${HAS_GROOVY:-0}
HAS_SCALA=${HAS_SCALA:-0}

declare -a KITS=()


install_ant() {
  ANT_HOME="${OPEN_DIR}/ant"
  ANT_URL=${ANT_URL:-'https://github.com/apache/ant.git'}

  cd "${OPEN_DIR}"
  [ -f "${ANT_HOME}/bootstrap.sh" ] || git clone --depth=1 ${ANT_URL} 
  cd "${ANT_HOME}" && bash ./bootstrap.sh && \
  echo -e "PATH=$PATH:$ANT_HOME" >> $HOME/.bash_paths
}

install_boot() {
  BOOT_URL=${BOOT_URL:-'https://github.com/boot-clj/boot-bin/releases/download/latest/boot.sh '}

  cd "${PREFIX}" && \
  curl -fsSLo boot ${BOOT_URL} && chmod 755 boot
}

[ 0 -lt "${HAS_ANT}" ]      && KITS+=('install_ant')
[ 0 -lt "${HAS_MAVEN}" ]    && KITS+=('install_maven')
[ 0 -lt "${HAS_BOOT}" ]     && KITS+=('install_boot')
[ 0 -lt "${HAS_GRADLE}" ]   && KITS+=('install_gradle')
[ 0 -lt "${HAS_GROOVY}" ]   && KITS+=('install_groovy')
[ 0 -lt "${HAS_SCALA}" ]    && KITS+=('install_scala')


for i in "${KITS[@]}"; do
  echo -e "call ${i} ..." && \
  $(${i}) && \
  echo -e "${i} installed.\n"
done
