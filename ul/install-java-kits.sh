#!/bin/bash

PREFIX=${PREFIX:-'/opt/run'}
OPEN_DIR=${OPEN_DIR:-'/opt/open'}

HAS_ANT=${HAS_ANT:-0}
HAS_MAVEN=${HAS_MAVEN:-0}
HAS_BOOT=${HAS_BOOT:-0}
HAS_GRADLE=${HAS_GRADLE:-0}
HAS_GROOVY=${HAS_GROOVY:-0}
HAS_SCALA=${HAS_SCALA:-0}

declare -a KITS=()

append_paths() {
  [ `echo $PATH | tr ':' '\n' | grep "^$1$" &>/dev/null; echo $?` ] && \
    echo -e "PATH=$PATH:$1" >> $HOME/.bash_paths && \
    . $HOME/.bashrc
}

append_vars() {
  . $HOME/.bash_vars
  [ `env | grep "^${1}$" &>/dev/null; echo $?` ] && \
    echo -e "export $1" >> $HOME/.bash_vars && \
    . $HOME/.bash_vars
}

install_ant() {
  local ant_home="${OPEN_DIR}/ant"
  local ant_url='https://github.com/apache/ant.git'

  cd "${OPEN_DIR}"
  [ -f "${ant_home}/bootstrap.sh" ] || git clone --depth=1 ${ant_url} 
  [ 0 -ne `type -p ant &>/dev/null; echo $?` ] && \
  cd "${ant_home}" && bootstrap.sh && \
  append_paths "$ant_home/bootstrap/bin"
}

install_maven() {
  local maven_home="${OPEN_DIR}/maven"
  local maven_url='https://github.com/apache/maven.git'
  local maven_ver='maven-3.2.6'
  local bin_dir="${PREFIX}/m2"
  
  [ -d "${bin_dir}" ] || mkdir -p "${bin_dir}"
  rm -r "${bin_dir}/*"

  append_vars "M2_HOME=${bin_dir}"

  cd "${OPEN_DIR}"
  [ -f "${maven_home}/build.xml" ] || \
    git clone -b ${maven_ver} --depth=1 ${maven_url} 
  [ 0 -ne `type -p mvn &>/dev/null; echo $?` ] && \
  [ 0 -eq `type -p ant &>/dev/null; echo $?` ] && \
  cd "${maven_home}" && ant clean-bootstrap && \
  ant -DskipText=true -Dmaven.test.skip=true && \
  append_paths "${bin_dir}/bin"
}

install_boot() {
  local boot_url=${boot_url:-'https://github.com/boot-clj/boot-bin/releases/download/latest/boot.sh '}

  cd "${PREFIX}" && \
  curl -fsSLo boot ${boot_url} && chmod 755 boot
}

[ 0 -lt "${HAS_ANT}" ]      && KITS+=('install_ant')
[ 0 -lt "${HAS_MAVEN}" ]    && KITS+=('install_maven')
[ 0 -lt "${HAS_BOOT}" ]     && KITS+=('install_boot')
[ 0 -lt "${HAS_GRADLE}" ]   && KITS+=('install_gradle')
[ 0 -lt "${HAS_GROOVY}" ]   && KITS+=('install_groovy')
[ 0 -lt "${HAS_SCALA}" ]    && KITS+=('install_scala')


for i in "${KITS[@]}"; do
  echo -e "# ${i} ..." 
  ${i}  
  echo -e "# ${i} completed."
done
