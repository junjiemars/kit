#!/bin/bash
#------------------------------------------------
# target: install java programming environment
# author: junjiemars@gmail.com
#------------------------------------------------

PREFIX=${PREFIX:-'/opt'}
RUN_DIR=${RUN_DIR:-"${PREFIX}/run"}
OPEN_DIR=${OPEN_DIR:-"${PREFIX}/open"}

HAS_ALL=${HAS_ALL:-"NO"}
HAS_JDK=${HAS_JDK:-0}
HAS_ANT=${HAS_ANT:-0}
HAS_MAVEN=${HAS_MAVEN:-0}
HAS_BOOT=${HAS_BOOT:-0}
HAS_CLOJURE=${HAS_CLOJURE:-0}
HAS_GRADLE=${HAS_GRADLE:-0}
HAS_GROOVY=${HAS_GROOVY:-0}
HAS_SCALA=${HAS_SCALA:-0}

JDK_VER=(${JDK_U:-"8u91"} ${JDK_B:-"b14"})
ANT_VER=${ANT_VER:-"1.9.x"}
MAVEN_VER=${MAVEN_VER:-"3.2.6"}
CLOJURE_VER=${CLOJURE_VER:-"1.8.0"}
GRADLE_VER=${GRADLE_VER:-"2.14.x"}
GROOVY_VER=${GROOVY_VER:-"2_4_X"}
SCALA_VER=${SCALA_VER:-"2.11.8"}

declare -a KITS=()

append_paths() {
  local f_paths="$HOME/.bash_paths"
  if [ 0 -ne `echo "$PATH" | tr ':' '\n' | grep "^$1$" &>/dev/null; echo $?` ]; then 
    if [ 0 -eq `grep "^PATH='.*'" ${f_paths} &>/dev/null; echo $?` ]; then
      sed -i "s#^PATH='.*'#PATH=$PATH:$1#g" "${f_paths}"
    else
      echo -e "PATH='$PATH:$1'" >> "${f_paths}"
    fi
    . "${f_paths}"
  fi
}

append_vars() {
  local f_vars="$HOME/.bash_vars"
  local name="$1"
  local val="$2"
  local var="export ${name}='${val}'"
  if [ 0 -eq `grep "^export ${name}='.*'" "${f_vars}" &>/dev/null; echo $?` ]; then
    sed -i "s#^export ${name}='.*'#${var}#g" "${f_vars}"
  else
    echo -e "${var}" >> "${f_vars}"
  fi
  . "${f_vars}"
}

install_jdk() {
  [ 0 -eq `javac -version &>/dev/null; echo $?` ] && return 0

  local platform=`uname -s 2>/dev/null`
  local machine=`uname -m 2>/dev/null`
  local ora_cookie='Cookie: oraclelicense=accept-securebackup-cookie'
  local ora_url='http://download.oracle.com/otn-pub/java/jdk'

  case "${platform}" in 
    Linux)
      if [ "x86_64" == "${machine}" ]; then
        local jdk_file="jdk-${JDK_VER}-linux-x64.tar.gz"
      else
        local jdk_file="jdk-${JDK_VER[0]}-linux-i586.tar.gz"
      fi
      local jdk_url="${ora_url}/${JDK_VER[0]}-${JDK_VER[1]}/${jdk_file}"
      local jdk_home="${RUN_DIR}/jdk/${JDK_VER[0]}"
      [ -d "${jdk_home}" ] || mkdir -p "${jdk_home}"
      curl -skL -H"${ora_cookie}" -O -C - "${jdk_url}" && \
        tar xf "${jdk_file}" -C "${jdk_home}" --strip-components=1
      if [ 0 -eq `${jdk_home}/bin/javac -version &>/dev/null; echo $?` ]; then
        append_vars "JAVA_HOME" "${jdk_home}"
        append_paths "${jdk_home}/bin"
        return 0
      fi
      ;;
    *)
      echo -e "not implemented on ${platform} yet!"
      ;;
  esac
  
  return 1
}

install_ant() {
  local ant_home="${OPEN_DIR}/ant"
  local ant_url='https://github.com/apache/ant.git'
  local bin_dir="${ant_home}/bootstrap"

  [ -f `ant -version $>/dev/null; echo $?` ] && return 0

  [ -f "${ant_home}/bootstrap.sh" ] || \
    git clone --depth=1 --branch="${ANT_VER}" "${ant_url}" "${ant_home}"

  [ -f "${bin_dir}/bin/ant" ] || cd ${ant_home} && ./bootstrap.sh 
    
  if [ 0 -eq `${bin_dir}/bin/ant -version &>/dev/null; echo $?` ]; then
    append_paths "${bin_dir}/bin"
    return 0
  fi
  return 1
}

install_maven() {
  local maven_home="${OPEN_DIR}/maven"
  local maven_url='https://github.com/apache/maven.git'
  local maven_ver="maven-${MAVEN_VER}"
  local bin_dir="${maven_home}/m2"
  
  [ 0 -eq `mvn -version $>/dev/null; echo $?` ] && return 0

  [ -f "${maven_home}/build.xml" ] || \
    git clone --depth=1 --branch="${maven_ver}" \
      "${maven_url}" "${maven_home}"

  if [ 0 -ne `${bin_dir}/bin/mvn -version &>/dev/null; echo $?` ]; then
    if [ 0 -eq `ant -version &>/dev/null; echo $?` ]; then
      [ -d "${bin_dir}" ] && rm -r "${bin_dir}"
      cd "${maven_home}" && ant clean-bootstrap && \
        M2_HOME="${bin_dir}"            \
        ant -D"maven.home=${bin_dir}"   \
            -D"skipTest=true"           \
            -D"maven.test.skip=true"    \
            -D"timeout=1800000"
    else
      echo -e "# need ant to build maven, panic!"
      return 1
    fi
  fi
  
  if [ 0 -eq `${bin_dir}/bin/mvn -version &>/dev/null; echo $?` ]; then 
    append_vars "M2_HOME" "${bin_dir}" 
    append_paths "${bin_dir}/bin"
    return 0
  fi
  return 1
}

install_boot() {
  local boot_url='https://github.com/boot-clj/boot-bin/releases/download/latest/boot.sh '
  local bin_dir="${RUN_DIR}/bin"

  [ 0 -eq `boot -v $>/dev/null; echo $?` ] && return 0

  curl -fsSLo "${bin_dir}/boot" -C - "${boot_url}" && \
    chmod 755 "${bin_dir}/boot"
  
  [ 0 -eq `${bin_dir}/boot -v &>/dev/null; echo $?` ] && return 0
  return 1
}

install_clojure() {
  local clojure_zip="clojure-${CLOJURE_VER}.zip"
  local clojure_jar="clojure-${CLOJURE_VER}.jar"
  local clojure_url="http://repo1.maven.org/maven2/org/clojure/clojure/${CLOJURE_VER}/${clojure_zip}"
  local clojure_home="${OPEN_DIR}/clojure"
  local bin_dir="${clojure_home}/clojure-${CLOJURE_VER}"
  local clojure_bin="${RUN_DIR}/bin/clojure"

  [ -x "${clojure_bin}" ] && return 0

  [ -d "${clojure_home}" ] || mkdir -p "${clojure_home}"
  if [ ! -f "${bin_dir}/${clojure_jar}" ]; then
    curl -L -o "${clojure_home}/${clojure_zip}" -C - "${clojure_url}" && \
      unzip "${clojure_home}/${clojure_zip}"
  fi

  if [ -f "${bin_dir}/${clojure_jar}" ]; then
    echo -e "#!/bin/bash\njava -cp ${bin_dir}/${clojure_jar} clojure.main" > "${clojure_bin}" && \
      chmod u+x "${clojure_bin}"
    return 0
  fi

  return 1
}

install_gradle() {
  local gradle_url='https://github.com/gradle/gradle.git'
  local gradle_home="${OPEN_DIR}/gradle"
  local bin_ln="${RUN_DIR}/bin/gradlew"

  [ 0 -eq `gradlew -version $>/dev/null; echo $?` ] && return 0

  [ -f "${gradle_home}/gradlew" ] || \
    git clone --depth=1 --branch="${GRADLE_VER}" \
      "${gradle_url}" "${gradle_home}"

  if [ 0 -eq `${gradle_home}/gradlew -version $>/dev/null; echo $?` ]; then
    [ -L "${bin_ln}" ] && rm "${bin_ln}"
      ln -s "${gradle_home}/gradlew" "${bin_ln}"
    return 0
  fi
  return 1
}

install_groovy() {
  local groovy_tag="GROOVY_${GROOVY_VER}"
  local groovy_url="https://github.com/apache/groovy.git"
  local groovy_home="${OPEN_DIR}/groovy"
  local bin_dir="${groovy_home}/target/install"

  [ 0 -eq `groovysh -version $>/dev/null; echo $?` ] && return 0

  [ -f "${groovy_home}/gradlew" ] || \
    git clone --depth=1 --branch="${groovy_tag}" \
      "${groovy_url}" "${groovy_home}"

  if [ ! -f "${bin_dir}/bin/groovysh" ]; then
    cd "${groovy_home}" && \
      ./gradlew -D"skipTest=true" installGroovy 
  fi

  if [ 0 -eq `${bin_dir}/bin/groovysh -version $>/dev/null; echo $?` ]; then
    append_vars "GROOVY_HOME" "${bin_dir}" 
    append_paths "${bin_dir}/bin"
    return 0
  fi
  return 1 
}

install_scala() {
  local scala_tgz="scala-${SCALA_VER}.tgz"
  local scala_url="http://downloads.lightbend.com/scala/${SCALA_VER}/${scala_tgz}"
  local scala_home="${OPEN_DIR}/scala"
  local bin_dir="${scala_home}/bin"

  [ 0 -eq `scala -version &>/dev/null; echo $?` ] && return 0

  [ -d "${scala_home}" ] || mkdir -p "${scala_home}"
  curl -L -o "${scala_home}/${scala_tgz}" -C - "${scala_url}" && \
    tar xf "${scala_home}/${scala_tgz}" -C "${scala_home}" --strip-components=1
  
  if [ 0 -eq `${bin_dir}/scala -version &>/dev/null; echo $?` ]; then
    [ -d "${RUN_DIR}/share/man/man1" ] || mkdir -p "${RUN_DIR}/share/man/man1" 
    cp -R "${scala_home}/man/man1/." "${RUN_DIR}/share/man/man1/"
    append_vars "SCALA_HOME" "${scala_home}"
    append_paths "${bin_dir}" 
    return 0
  fi
  return 1
}

if [ "YES" == "${HAS_ALL}" ]; then
  #HAS_JDK=1  # exclude JDK
  HAS_ANT=1
  HAS_MAVEN=1
  HAS_BOOT=1
  HAS_CLOJURE=1
  HAS_GRADLE=1
  HAS_GROOVY=1
  HAS_SCALA=1
fi

[ 0 -lt "${HAS_JDK}" ]      && KITS+=('install_jdk')
[ 0 -lt "${HAS_ANT}" ]      && KITS+=('install_ant')
[ 0 -lt "${HAS_MAVEN}" ]    && KITS+=('install_maven')
[ 0 -lt "${HAS_BOOT}" ]     && KITS+=('install_boot')
[ 0 -lt "${HAS_CLOJURE}" ]  && KITS+=('install_clojure')
[ 0 -lt "${HAS_GRADLE}" ]   && KITS+=('install_gradle')
[ 0 -lt "${HAS_GROOVY}" ]   && KITS+=('install_groovy')
[ 0 -lt "${HAS_SCALA}" ]    && KITS+=('install_scala')

for i in "${KITS[@]}"; do
  echo -e "# ${i} ..." 
  [ -d "${OPEN_DIR}" ] || mkdir "${OPEN_DIR}" && ${i}  
  if [ 0 -eq `${i} &>/dev/null; echo $?` ]; then
    echo -e "# ${i} good."
  else
    echo -e "# ${i} panic!"
  fi
done

[ 0 -lt "${#KITS[@]}" ] && . "$HOME/.bashrc"
