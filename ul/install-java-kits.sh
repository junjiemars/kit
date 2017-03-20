#!/bin/bash
#------------------------------------------------
# target: install java programming environment
# author: junjiemars@gmail.com
#------------------------------------------------

PLATFORM=`uname -s 2>/dev/null`
case "${PLATFORM}" in
  MSYS_NT*)
    if [ -d "/d/" ]; then
      PREFIX=${PREFIX:-"/d/opt"}
    else
      PREFIX=${PREFIX:-"/c/opt"}
    fi
    ;;
  *)
    PREFIX=${PREFIX:-"/opt"}
    ;;
esac

RUN_DIR=${RUN_DIR:-"${PREFIX}/run"}
OPEN_DIR=${OPEN_DIR:-"${PREFIX}/open"}
SOCKS=

HAS_ALL=${HAS_ALL:-"NO"}
HAS_JDK=${HAS_JDK:-0}
HAS_ANT=${HAS_ANT:-0}
HAS_MAVEN=${HAS_MAVEN:-0}
HAS_BOOT=${HAS_BOOT:-0}
HAS_LEIN=${HAS_LEIN:-0}
HAS_GRADLE=${HAS_GRADLE:-0}
HAS_SBT=${HAS_SBT:-0}
HAS_CLOJURE=${HAS_CLOJURE:-0}
HAS_CLOJURESCRIPT=${HAS_CLOJURESCRIPT:-0}
HAS_GROOVY=${HAS_GROOVY:-0}
HAS_SCALA=${HAS_SCALA:-0}
HAS_SCALA_VIM=${HAS_SCALA_VIM:-0}

JDK_VER=(${JDK_U:-"8u91"} ${JDK_B:-"b14"})
ANT_VER=${ANT_VER:-"1.10.1"}
MAVEN_VER=${MAVEN_VER:-"3.3.9"}
GRADLE_VER=${GRADLE_VER:-"2.13"}
SBT_VER=${SBT_VER:-"0.13.13"}
CLOJURE_VER=${CLOJURE_VER:-"1.8.0"}
CLOJURESCRIPT_VER=${CLOJURESCRIPT_VER:-"1.9.229"}
GROOVY_VER=${GROOVY_VER:-"2_4_X"}
SCALA_VER=${SCALA_VER:-"2.12.1"}

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

chmod_file() {
	local _f=$1
	local _o=$2

	if [ -n "$_f" ] && [ -n "$_o" ] && [ -f $_f ]; then
		chmod $_o $_f
	else
		return 1
	fi
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
      curl $SOCKS -skL -H"${ora_cookie}" -O -C - "${jdk_url}" && \
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
  local ant_tgz="apache-ant-${ANT_VER}-bin.tar.gz"
  local ant_home="${OPEN_DIR}/ant"
  local ant_url="http://archive.apache.org/dist/ant/binaries/${ant_tgz}"
  local bin_dir="${ant_home}/bin"

  `ant -version $>/dev/null` && return 0
  [ -d "${ant_home}" ] || mkdir -p "${ant_home}"

  if [ ! -f "${bin_dir}/ant" ] || \
       [ 0 -ne `${bin_dir}/ant -version &>/dev/null; echo $?` ]; then
    curl $SOCKS -L -o "${ant_home}/${ant_tgz}" -C - "${ant_url}" && \
      tar xf "${ant_home}/${ant_tgz}" -C "${ant_home}" --strip-components=1
  fi

  if [ 0 -eq `${bin_dir}/ant -version &>/dev/null; echo $?` ]; then
    append_vars "ANT_HOME" "${ant_home}"
    append_paths "${bin_dir}" 
    return 0
  fi
  return 1
}

install_maven() {
  local mvn_tgz="apache-maven-${MAVEN_VER}-bin.tar.gz"
  local mvn_home="${OPEN_DIR}/maven"
  local mvn_url="http://archive.apache.org/dist/maven/maven-3/${MAVEN_VER}/binaries/${mvn_tgz}"
  local bin_dir="${mvn_home}/bin"
  
  `mvn -version $>/dev/null` && return 0
  [ -d "${mvn_home}" ] || mkdir -p "${mvn_home}"

  if [ ! -f "${bin_dir}/mvn" ] || \
       [ 0 -ne `${bin_dir}/mvn -version &>/dev/null; echo $?` ]; then
    curl $SOCKS -L -o "${mvn_home}/${mvn_tgz}" -C - "${mvn_url}" && \
      tar xf "${mvn_home}/${mvn_tgz}" -C "${mvn_home}" --strip-components=1
  fi

  if [ 0 -eq `${bin_dir}/mvn -version &>/dev/null; echo $?` ]; then
    append_vars "MAVEN_HOME" "${mvn_home}"
    append_paths "${bin_dir}" 
    return 0
  fi
  return 1
}

install_boot() {
  local boot_url='https://github.com/boot-clj/boot-bin/releases/download/latest/boot.sh '
  local bin_dir="${RUN_DIR}/bin"

  [ 0 -eq `boot -v $>/dev/null; echo $?` ] && return 0

  curl $SOCKS -fsSLo "${bin_dir}/boot" -C - "${boot_url}" && \
    chmod 755 "${bin_dir}/boot"
  
  [ 0 -eq `${bin_dir}/boot -v &>/dev/null; echo $?` ] && return 0
  return 1
}

install_lein() {
  local lein_url="https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein"
  local bin_dir="${RUN_DIR}/bin"
  
  if [ ! -f "${bin_dir}/lein" ]; then
    curl $SOCKS -fsSLo "${bin_dir}/lein" -C - "${lein_url}" && \
      chmod u+x "${bin_dir}/lein"
  fi

  case "${PLATFORM}" in
    MSYS_NT*)
      if [ ! -f "${bin_dir}/lein.bat" ]; then
        curl $SOCKS -fsSLo "${bin_dir}/lein.bat" -C - "${lein_url}.bat" && \
          chmod u+x "${bin_dir}/lein.bat"
      fi
      ;;
  esac
}

install_clojure() {
  local clojure_zip="clojure-${CLOJURE_VER}.zip"
  local clojure_jar="clojure-${CLOJURE_VER}.jar"
  local clojure_url="http://repo1.maven.org/maven2/org/clojure/clojure/${CLOJURE_VER}/${clojure_zip}"
  local clojure_home="${OPEN_DIR}/clojure"
  local bin_dir="${clojure_home}/clojure-${CLOJURE_VER}"
  local clojure_bin="${RUN_DIR}/bin/clojure"
  local clojure_sh="https://raw.githubusercontent.com/junjiemars/kit/master/clojure/clojure.sh"

  [ -x "${clojure_bin}" ] && return 0

  [ -d "${clojure_home}" ] || mkdir -p "${clojure_home}"
  if [ ! -f "${bin_dir}/${clojure_jar}" ]; then
    curl $SOCKS -L -o "${clojure_home}/${clojure_zip}" -C - "${clojure_url}"
    if [ -f "${clojure_home}/${clojure_zip}" ]; then
      cd "${clojure_home}" && unzip "${clojure_home}/${clojure_zip}"
    fi
  fi

  if [ -f "${bin_dir}/${clojure_jar}" ]; then
    curl $SOCKS -L -o "${clojure_bin}" -C - "${clojure_sh}" && \
      sed -i.b0 -e "s#CLOJURE_JAR=#CLOJURE_JAR=\"${bin_dir}/${clojure_jar}\"#" \
        "${clojure_bin}"
		if `chmod_file "${clojure_bin}" "u+x"`; then
			return 0
		fi
  fi

  return 1
}

install_clojurescript() {
  local cljs_jar="https://github.com/clojure/clojurescript/releases/download/r${CLOJURESCRIPT_VER}/cljs.jar"
  local cljs_sh="https://raw.githubusercontent.com/junjiemars/kit/master/clojure/clojurescript.sh"
  local cljs_bin="${RUN_DIR}/bin/clojurescript"
  local cljs_home="${OPEN_DIR}/clojurescript"

  [ -x "${cljs_bin}" ] && return 0

  [ -d "${cljs_home}" ] || mkdir -p "${cljs_home}"
  if [ ! -f "${cljs_home}/cljs.jar" ]; then
    curl $SOCKS -fsSLo "${cljs_home}/cljs.jar" -C - "${cljs_jar}"
  fi

  if [ -f "${cljs_home}/cljs.jar" ]; then
    curl $SOCKS -fsSLo "${cljs_bin}" -C - "${cljs_sh}" && \
      sed -i.b0 \
				  -e "s#CLOJURESCRIPT_JAR=#CLOJURESCRIPT_JAR=\"${cljs_home}/cljs.jar\"#" \
          "${cljs_bin}"
    if `chmod_file "${cljs_bin}" "u+x"`; then
			return 0
		fi
  fi
  
  return 1
}

install_gradle() {
  local gradle_zip="gradle-${GRADLE_VER}-bin.zip"
  local gradle_url="https://services.gradle.org/distributions/${gradle_zip}"
  local gradle_home="${OPEN_DIR}/gradle"
  local bin_dir="${gradle_home}/gradle-${GRADLE_VER}"
	local bin_ln="${RUN_DIR}/bin/gradle"

  [ 0 -eq `gradle -v $>/dev/null;echo $?` ] && return 0

  [ -d "${gradle_home}" ] || mkdir -p "${gradle_home}"

	if [ ! -f "${bin_dir}/bin/gradle" ]; then
		curl $SOCKS -Lo "${gradle_home}/${gradle_zip}" -C - "${gradle_url}" && \
			cd ${gradle_home} && unzip ${gradle_zip}
	fi
  
  if `${bin_dir}/bin/gradle -v &>/dev/null`; then
		case "${PLATFORM}" in
			MSYS_NT*)
				append_paths "${bin_dir}/bin"
			;;
			*)
				[ -L "${bin_ln}" ] && rm "${bin_ln}"
				ln -s "${bin_dir}/bin/gradle" "${bin_ln}"
			;;
		esac
    return 0
  fi
 
  return 1
}

install_sbt() {
  local sbt_zip="sbt-${SBT_VER}.zip"
  local sbt_url="https://dl.bintray.com/sbt/native-packages/sbt/${SBT_VER}/${sbt_zip}"
  local sbt_home="${OPEN_DIR}/sbt"
  local bin_dir="${sbt_home}/sbt-launcher-packaging-${SBT_VER}"
	local bin_ln="${RUN_DIR}/bin/sbt"

  [ 0 -eq `sbt </dev/null &>/dev/null;echo $?` ] && return 0

  [ -d "${sbt_home}" ] || mkdir -p "${sbt_home}"

	if [ ! -f "${bin_dir}/bin/sbt" ]; then
		curl $SOCKS -Lo "${sbt_home}/${sbt_zip}" -C - "${sbt_url}" && \
			cd ${sbt_home} && unzip ${sbt_zip}
	fi
  
  if `${bin_dir}/bin/sbt </dev/null &>/dev/null`; then
		case "${PLATFORM}" in
			MSYS_NT*)
				append_paths "${bin_dir}/bin"
			;;
			*)
				[ -L "${bin_ln}" ] && rm "${bin_ln}"
				ln -s "${bin_dir}/bin/sbt" "${bin_ln}"
			;;
		esac
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

install_scala_vim() {
	local vim_url="https://raw.githubusercontent.com/derekwyatt/vim-scala/master"
	
	[ -f "$HOME/.vim/syntax/scala.vim" ] && return 0

	mkdir -p "$HOME"/.vim/{ftdetect,indent,syntax}
	for d in ftdetect indent syntax ; do 
		curl $SOCKS -L -o "$HOME/.vim/$d/scala.vim" "${vim_url}/$d/scala.vim"; 
	done

	[ -f "$HOME/.vim/syntax/scala.vim" ] && return 0 || return 1
}

install_scala() {
  local scala_tgz="scala-${SCALA_VER}.tgz"
  local scala_url="http://downloads.lightbend.com/scala/${SCALA_VER}/${scala_tgz}"
  local scala_home="${OPEN_DIR}/scala"
  local bin_dir="${scala_home}/bin"
	local vim_url="https://raw.githubusercontent.com/derekwyatt/vim-scala/master"

  `scala -version &>/dev/null` && return 0
  [ -d "${scala_home}" ] || mkdir -p "${scala_home}"

  if [ ! -f "${bin_dir}/scala" ] || \
       [ 0 -ne `${bin_dir}/scala -version &>/dev/null; echo $?` ]; then
    curl $SOCKS -L -o "${scala_home}/${scala_tgz}" -C - "${scala_url}" && \
      tar xf "${scala_home}/${scala_tgz}" -C "${scala_home}" --strip-components=1
  fi
  
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
  HAS_LEIN=1
  HAS_GRADLE=1
  HAS_SBT=1
  HAS_CLOJURE=1
  HAS_CLOJURESCRIPT=1
  HAS_GROOVY=1
  HAS_SCALA=1
fi

[ 0 -lt "${HAS_JDK}" ]            && KITS+=('install_jdk')
[ 0 -lt "${HAS_ANT}" ]            && KITS+=('install_ant')
[ 0 -lt "${HAS_MAVEN}" ]          && KITS+=('install_maven')
[ 0 -lt "${HAS_BOOT}" ]           && KITS+=('install_boot')
[ 0 -lt "${HAS_LEIN}" ]           && KITS+=('install_lein')
[ 0 -lt "${HAS_GRADLE}" ]         && KITS+=('install_gradle')
[ 0 -lt "${HAS_SBT}" ]            && KITS+=('install_sbt')
[ 0 -lt "${HAS_CLOJURE}" ]        && KITS+=('install_clojure')
[ 0 -lt "${HAS_CLOJURESCRIPT}" ]  && KITS+=('install_clojurescript')
[ 0 -lt "${HAS_GROOVY}" ]         && KITS+=('install_groovy')
[ 0 -lt "${HAS_SCALA}" ]          && KITS+=('install_scala')
[ 0 -lt "${HAS_SCALA_VIM}" ]      && KITS+=('install_scala_vim')

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
