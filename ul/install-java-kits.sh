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

append_path() {
  [ `echo $PATH | tr ':' '\n' | grep "^$1$" &>/dev/null; echo $?` ] && \
    echo -e "PATH=$PATH:$1" >> $HOME/.bash_paths
}

install_ant() {
  local ant_home="${OPEN_DIR}/ant"
  local ant_url='https://github.com/apache/ant.git'

  cd "${OPEN_DIR}"
  [ -f "${ant_home}/bootstrap.sh" ] || git clone --depth=1 ${ant_url} 
  [ 0 -ne `type -p ant &>/dev/null; echo $?` ] && cd "${ant_home}" && \
  bootstrap.sh && append_path "$ant_home/bootstrap/bin"
}

install_maven() {
  local maven_home="${OPEN_DIR}/maven"
  local maven_url='https://github.com/apache/maven.git'
  
  cd "${OPEN_DIR}"
  [ -f "${maven_home}/build.xml" ] || \
    git clone -b 'maven-3.2.6' --depth=1 ${maven_url} 
  [ 0 -eq `type -p ant &>/dev/null; echo $?` ] && \
  cd "${maven_home}" && ant -f build.xml 
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
  . $HOME/.bashrc
  echo -e "# ${i} ..." && \
  ${i} && \
  echo -e "# ${i} completed.\n"
done
