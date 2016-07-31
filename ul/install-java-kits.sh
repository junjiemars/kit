#!/bin/bash

PREFIX=${PREFIX:-'/opt'}
RUN_DIR=${RUN_DIR:-"${PREFIX}/run"}
OPEN_DIR=${OPEN_DIR:-"${PREFIX}/open"}

HAS_ANT=${HAS_ANT:-0}
HAS_MAVEN=${HAS_MAVEN:-0}
HAS_BOOT=${HAS_BOOT:-0}
HAS_GRADLE=${HAS_GRADLE:-0}
HAS_GROOVY=${HAS_GROOVY:-0}
HAS_SCALA=${HAS_SCALA:-0}       # 2.11.8

declare -a KITS=()

append_paths() {
  local f_paths="$HOME/.bash_paths"
  if [ 0 -ne `echo "$PATH" | tr ':' '\n' | grep "^$1$" &>/dev/null; echo $?` ]; then 
    if [ 0 -eq `grep "^PATH='.*'" ${f_paths} &>/dev/null; echo $?` ]; then
      sed -i 's#^PATH='.*'#PATH=$PATH:$1#g' "${f_paths}"
    else
      echo -e "PATH='$PATH:$1'" >> "${f_paths}"
    fi
    . "${f_paths}"
  fi
}

append_vars() {
  local f_vars="$HOME/.bash_vars"
  local var="export $1"
  [ 0 -eq `grep "${var}" "${f_vars}" &>/dev/null; echo $?` ] || \
    echo -e "${var}" >> "${f_vars}"
}

git_repo_exists() {
  git branch &>/dev/null; echo $?
}

install_ant() {
  local ant_home="${OPEN_DIR}/ant"
  local ant_url='https://github.com/apache/ant.git'

  [ -f "${ant_home}/bootstrap.sh" ] || \
    git clone --depth=1 ${ant_url} ${ant_home}

  [ 0 -ne `type -p ant &>/dev/null; echo $?` ] && \
    cd ${ant_home} && bootstrap.sh && \
    append_paths "$ant_home/bootstrap/bin"
}

install_maven() {
  local maven_home="${OPEN_DIR}/maven"
  local maven_url='https://github.com/apache/maven.git'
  local maven_ver='maven-3.2.6'
  local bin_dir="${RUN_DIR}/bin/m2"
  
  [ -d "${bin_dir}" ] || mkdir -p "${bin_dir}"
  rm -r "${bin_dir}/*"

  append_vars "M2_HOME=${bin_dir}"

  [ -f "${maven_home}/build.xml" ] || \
    git clone -b ${maven_ver} --depth=1 ${maven_url} ${maven_home}

  [ 0 -ne `type -p mvn &>/dev/null; echo $?` ] && \
  [ 0 -eq `type -p ant &>/dev/null; echo $?` ] && \
    cd ${maven_home} && \
    ant clean-bootstrap && \
    ant -DskipTest=true -Dmaven.test.skip=true && \
    append_paths "${bin_dir}/bin"
}

install_boot() {
  local boot_url='https://github.com/boot-clj/boot-bin/releases/download/latest/boot.sh '
  local bin_dir="${RUN_DIR}/bin"

  [ -f "${bin_dir}/boot" ] || \
    curl -fsSLo ${bin_dir}/boot ${boot_url} && \
    chmod 755 ${bin_dir}/boot
}

install_gradle() {
  local gradle_url='https://github.com/gradle/gradle.git'
  local gradle_home="${OPEN_DIR}/gradle"
  local bin_ln="${RUN_DIR}/bin/gradlew"

  [ -f "${gradle_home}/gradlew" ] || \
    git clone --depth=1 ${gradle_url} ${gradle_home}

  [ -L "${bin_ln}" ] && rm "${bin_ln}"
  [ 0 -ne `type -p gradlew &>/dev/null; echo $?` ] && \
    ln -s ${gradle_home}/gradlew ${bin_ln}
}

install_groovy() {
  local groovy_url='https://github.com/apache/groovy.git'
  local groovy_home="${OPEN_DIR}/groovy"

  [ -f "${groovy_home}/gradlew" ] || \
    git clone --depth=1 ${groovy_url} ${groovy_home}

  . $HOME/.bashrc
  [ 0 -ne `type -p groovy &>/dev/null; echo $?` ] && \
    cd ${groovy_home} && \
    gradlew clean dist
}

install_scala() {
  local scala_tgz="scala-${HAS_SCALA}.tgz"
  local scala_url="http://downloads.lightbend.com/scala/${HAS_SCALA}/${scala_tgz}"
  local scala_home="${OPEN_DIR}/scala"

  [ -d "${scala_home}" ] || mkdir -p "${scala_home}"
  [ -f "${scala_home}/${scala_tgz}" ] || \
    curl ${scala_url} -o "${scala_home}/${scala_tgz}" && \
    tar xf "${scala_home}/${scala_tgz}" -C "${scala_home}" --strip-components=1

  [ -d "${RUN_DIR}/share/man/man1" ] || mkdir -p "${RUN_DIR}/share/man/man1" 
  cp -R "${scala_home}/man/man1/." "${RUN_DIR}/share/man/man1/"
 
  append_vars "SCALA_HOME=${scala_home}"
  append_paths "${scala_home}/bin"
}

[ 0 -lt "${HAS_ANT}" ]      && KITS+=('install_ant')
[ 0 -lt "${HAS_MAVEN}" ]    && KITS+=('install_maven')
[ 0 -lt "${HAS_BOOT}" ]     && KITS+=('install_boot')
[ 0 -lt "${HAS_GRADLE}" ]   && KITS+=('install_gradle')
[ 0 -lt "${HAS_GROOVY}" ]   && KITS+=('install_groovy')
[ "0" != "${HAS_SCALA}" ]       && KITS+=('install_scala')

for i in "${KITS[@]}"; do
  echo -e "# ${i} ..." 
  [ -d "${OPEN_DIR}" ] || mkdir "${OPEN_DIR}" && ${i}  
  echo -e "# ${i} completed."
done
