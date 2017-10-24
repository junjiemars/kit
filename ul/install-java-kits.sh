#!/bin/bash
#------------------------------------------------
# target: install java programming environment
# author: junjiemars@gmail.com
#------------------------------------------------

#PLATFORM=`uname -s 2>/dev/null`
#
#function on_windows_nt() {
#  case "$PLATFORM" in
#    MSYS_NT*|MINGW*)
#      return 0
#      ;;
#    *)
#      return 1
#      ;;
#  esac
#}
#
#if `on_windows_nt`; then
#  if [ -d "/d/" ]; then
#    PREFIX="${PREFIX:-/d/opt}"
#  else
#    PREFIX="${PREFIX:-/c/opt}"
#  fi
#else
#  PREFIX="${PREFIX:-/opt}"
#fi
#
#="-i''"
#[ "Darwin" = "$os" ] && ="-i ''"
#
#
#RUN_DIR="${RUN_DIR:-${PREFIX}/run}"
#OPEN_DIR="${OPEN_DIR:-${PREFIX}/open}"
#SOCKS="${SOCKS}"

GITHUB_ROOT="https://raw.githubusercontent.com/junjiemars/kit"
GITHUB_BRANCH="${GITHUB_BRANCH:-master}"
GITHUB_H="${GITHUB_H:-${GITHUB_ROOT}/${GITHUB_BRANCH}}"
SOCKS=${SOCKS}

curl $SOCKS -L -o /tmp/p.sh "${GITHUB_H}/ul/p.sh"
if [ ! -f /tmp/p.sh ]; then
	echo "! download p.sh from ${GITHUB_H}/ul/p.sh failed"
	exit 1
fi
. /tmp/p.sh

curl $SOCKS -L -o /tmp/i.sh "${GITHUB_H}/ul/i.sh"
if [ ! -f /tmp/i.sh ]; then
	echo "! download i.sh from ${GITHUB_H}/ul/i.sh failed"
	exit 1
fi
. /tmp/i.sh


HAS_ALL=${HAS_ALL:-NO}
HAS_JDK=${HAS_JDK:-0}
HAS_ABCL=${HAS_ABCL:-0}
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
HAS_ZOOKEEPER=${HAS_ZOOKEEPER:-0}

JDK_VER=("${JDK_U:-8u121} ${JDK_B:-b13}")
ABCL_VER="${ABCL_VER:-1.5.0}"
ANT_VER="${ANT_VER:-1.10.1}"
MAVEN_VER="${MAVEN_VER:-3.3.9}"
GRADLE_VER="${GRADLE_VER:-2.13}"
SBT_VER="${SBT_VER:-0.13.13}"
CLOJURE_VER="${CLOJURE_VER:-1.8.0}"
CLOJURESCRIPT_VER="${CLOJURESCRIPT_VER:-1.9.229}"
GROOVY_VER="${GROOVY_VER:-2.4.12}"
SCALA_VER="${SCALA_VER:-2.12.1}"
ZOOKEEPER_VER="${ZOOKEEPER_VER:-3.4.10}"

declare -a KITS=()

append_paths() {
  local f_paths="$HOME/.bash_paths"
	local name="PATH"
	local val="\${PATH:+\$PATH:}$1"
	local flag="$2"
	local var="${name}=\"${val}\""
  if `grep "^${name}=\".*${flag}.*\"" "${f_paths}" &>/dev/null`; then
    sed $ "s#^${name}=\".*${flag}\"#${var}#g" "${f_paths}"
	else
    echo -e "${var}" >> "${f_paths}"
  fi
  . "${f_paths}"
}

append_vars() {
  local f_vars="$HOME/.bash_vars"
  local name="$1"
  local val="$2"
  local var="export ${name}='${val}'"
  if `grep "^export ${name}='.*'" "${f_vars}" &>/dev/null`; then
    sed $ "s#^export ${name}='.*'#${var}#g" "${f_vars}"
  else
    echo -e "${var}" >> "${f_vars}"
  fi
  . "${f_vars}"
}

chmod_file() {
	local f="$1"
	local o="$2"

	if [ -n "$f" ] && [ -n "$o" ] && [ -f "$f" ]; then
		chmod "$o" "$f"
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
        append_paths "\${JAVA_HOME}/bin" "JAVA_HOME"
        return 0
      fi
      ;;
    *)
      echo -e "not implemented on ${platform} yet!"
      ;;
  esac
  
  return 1
}

download_kit() {
  local url="$1"
  local fn="$2"
  local t=0

  curl $SOCKS -L -o "${fn}" -C - "${url}"
  t=$?
  if [ 33 -eq $t ]; then
    curl $SOCKS -L -o "${fn}" "${url}"
  else
    return $t
  fi
}

extract_kit() {
  local src="$1"
  local dst="$2"
  local x="${src##*.}"

  [ -d "${dst}" ] || mkdir -p "${dst}"
  
  case "$x" in
    gz|tgz)
      tar xf "${src}" -C "${dst}" --strip-components=1
      ;;
    unzip)
      return 1
      ;;
    *)
      return 1
      ;;
  esac
}

install_kit() {
  local bin="$1"
  local cmd="$2"
  local url="$3"
  local src="$4"
  local dst="$5"

  `test -f "$bin"` && `$cmd &>/dev/null` && return 0

  `test -f "$src"` \
    && `extract_kit "$src" "$dst"` \
    && `$cmd &>/dev/null` && return 0

  if `download_kit "$url" "$src"`; then
    extract_kit "$src" "$dst"
  else
    return 1
  fi
}

check_kit() {
  local cmd="$1"
  local home="$2"

  if `${cmd} &>/dev/null`; then
    return 0
  else
    [ -d "${home}" ] || mkdir -p "${home}"
    return 1
  fi
}

install_abcl() {
  local abcl_tgz="abcl-bin-${ABCL_VER}.tar.gz"
  local abcl_url="http://abcl.org/releases/${ABCL_VER}/${abcl_tgz}"
  local abcl_home="${OPEN_DIR}/abcl"
  local bin_dir="${abcl_home}/${ABCL_VER}"
  local cmd="java -jar ${bin_dir}/abcl.jar --batch"
  local abcl_sh="${RUN_DIR}/bin/abcl.sh"

  `check_kit "abcl.sh --batch" "${abcl_home}"` && return 0

  $(install_kit "${bin_dir}/abcl.jar" \
                "${cmd}" \
                "${abcl_url}" \
                "${abcl_home}/${abcl_tgz}" \
                "${bin_dir}") || return 1

  if `$cmd &>/dev/null`; then
    cat << END > "${abcl_sh}"
#!`type -P bash`
#----------
# generated by https://raw.githubusercontent.com/junjiemars/kit/master/ul/install-java-kits.sh
#----------
ABCL_HOME=${bin_dir}
java -jar \${ABCL_HOME}/abcl.jar \$@

END
    chmod_file "${abcl_sh}" "u+x"
    return 0
  fi

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
    append_paths "\${ANT_HOME}/bin" "ANT_HOME"
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
    append_paths "\${MAVEN_HOME}/bin" "MAVEN_HOME"
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

  if `on_windows_nt`; then
    if [ ! -f "${bin_dir}/lein.bat" ]; then
      curl $SOCKS -fsSLo "${bin_dir}/lein.bat" \
           -C - "${lein_url}.bat" \
        && chmod u+x "${bin_dir}/lein.bat"
    fi
  fi
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
    if `on_windows_nt`; then
      append_paths "${bin_dir}/bin" "gradle"
    else
			[ -L "${bin_ln}" ] && rm "${bin_ln}"
			ln -s "${bin_dir}/bin/gradle" "${bin_ln}"
    fi
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
    if `on_windows_nt`; then
			append_paths "${bin_dir}/bin" "sbt"
    else
			[ -L "${bin_ln}" ] && rm "${bin_ln}"
			ln -s "${bin_dir}/bin/sbt" "${bin_ln}"
    fi
    return 0
  fi
 
  return 1
}

install_groovy() {
  local groovy_zip="apache-groovy-binary-${GROOVY_VER}.zip"
  local groovy_url="https://dl.bintray.com/groovy/maven/${groovy_zip}"
	local groovy_root="${OPEN_DIR}/groovy"
  local groovy_home="${groovy_root}/groovy-${GROOVY_VER}"
  local bin_dir="${groovy_home}/bin"

  `groovysh --version &>/dev/null` && return 0
  [ -d "${groovy_root}" ] || mkdir -p "${groovy_root}"

  if [ ! -f "${bin_dir}/groovysh" ] || \
       [ 0 -ne `${bin_dir}/groovysh --version &>/dev/null; echo $?` ]; then
    curl $SOCKS -L -o "${groovy_root}/${groovy_zip}" -C - "${groovy_url}" && \
			cd ${groovy_root} && unzip ${groovy_zip}
  fi
 
  if `GROOVY_HOME=${groovy_home} ${bin_dir}/groovysh --version &>/dev/null`; then
    append_vars "GROOVY_HOME" "${groovy_home}" 
    append_paths "\${GROOVY_HOME}/bin" "GROOVY_HOME"
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
  
  if `SCALA_HOME=${scala_home} ${bin_dir}/scala -version &>/dev/null`; then
    [ -d "${RUN_DIR}/share/man/man1" ] || mkdir -p "${RUN_DIR}/share/man/man1" 
    cp -R "${scala_home}/man/man1/." "${RUN_DIR}/share/man/man1/"
    append_vars "SCALA_HOME" "${scala_home}"
    append_paths "\${SCALA_HOME}/bin" "SCALA_HOME"
    return 0
  fi
  return 1
}

install_zookeeper() {
  local zk_ver="zookeeper-${ZOOKEEPER_VER}"
  local zk_tgz="${zk_ver}.tar.gz"
  local zk_home="${OPEN_DIR}/zookeeper"
  local zk_url="http://archive.apache.org/dist/zookeeper/${zk_ver}/${zk_tgz}"
  local bin_dir="${zk_home}/bin"

  `${bin_dir}/zkServer.sh print-cmd &> /dev/null` && return 0
  [ -d "${zk_home}" ] || mkdir -p "${zk_home}"

  if [ ! -f "${bin_dir}/zkServer.sh" ] || \
       [ 0 -ne `${bin_dir}/zkServer print-cmd &>/dev/null; echo $?` ]; then
    curl $SOCKS -L -o "${zk_home}/${zk_tgz}" -C - "${zk_url}" && \
      tar xf "${zk_home}/${zk_tgz}" -C "${zk_home}" --strip-components=1
  fi

  `${bin_dir}/zkServer.sh print-cmd &> /dev/null` && return 0

  return 1
}

if [ "YES" == "${HAS_ALL}" ]; then
  #HAS_JDK=1  # exclude JDK
  HAS_ANT=1
  HAS_ABCL=1
  HAS_MAVEN=1
  HAS_BOOT=1
  HAS_LEIN=1
  HAS_GRADLE=1
  HAS_SBT=1
  HAS_CLOJURE=1
  HAS_CLOJURESCRIPT=1
  HAS_GROOVY=1
  HAS_SCALA=1
  #HAS_ZOOKEEPER=1
fi

[ 0 -lt "${HAS_JDK}" ]            && KITS+=('install_jdk')
[ 0 -lt "${HAS_ANT}" ]            && KITS+=('install_ant')
[ 0 -lt "${HAS_ABCL}" ]           && KITS+=('install_abcl')
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
[ 0 -lt "${HAS_ZOOKEEPER}" ]      && KITS+=('install_zookeeper')

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
