#!/bin/bash
#------------------------------------------------
# target: install java programming environment
# author: junjiemars@gmail.com
#------------------------------------------------

PLATFORM=`uname -s 2>/dev/null`

function on_windows_nt() {
 case "$PLATFORM" in
   MSYS_NT*|MINGW*)
     return 0
     ;;
   *)
     return 1
     ;;
 esac
}

if `on_windows_nt`; then
 if [ -d "/d/" ]; then
   PREFIX="${PREFIX:-/d/opt}"
 else
   PREFIX="${PREFIX:-/c/opt}"
 fi
else
 PREFIX="${PREFIX:-/opt}"
fi

SED_OPT_I="-i''"
[ "Darwin" = "$os" ] && SED_OPT_I="-i ''"


RUN_DIR="${RUN_DIR:-${PREFIX}/run}"
OPEN_DIR="${OPEN_DIR:-${PREFIX}/open}"
CURL_OPTS="${CURL_OPTS:---connect-timeout 60}"
GITHUB_SH="https://raw.githubusercontent.com/junjiemars/kit/master/ul/install-java-kits.sh"
APACHE_DIST="https://archive.apache.org/dist"

HAS_ALL="${HAS_ALL:-NO}"
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
HAS_STORM=${HAS_STORM:-0}
HAS_ZOOKEEPER=${HAS_ZOOKEEPER:-0}

JDK_VER=("${JDK_U:-8u152} ${JDK_B:-b16}")
ABCL_VER="${ABCL_VER:-1.5.0}"
ANT_VER="${ANT_VER:-1.10.1}"
MAVEN_VER="${MAVEN_VER:-3.5.2}"
GRADLE_VER="${GRADLE_VER:-4.2.1}"
SBT_VER="${SBT_VER:-1.0.2}"
CLOJURE_VER="${CLOJURE_VER:-1.8.0}"
CLOJURESCRIPT_VER="${CLOJURESCRIPT_VER:-1.9.946}"
GROOVY_VER="${GROOVY_VER:-2.4.12}"
SCALA_VER="${SCALA_VER:-2.12.4}"
STORM_VER="${STORM_VER:-1.1.1}"
ZOOKEEPER_VER="${ZOOKEEPER:-3.4.10}"

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
    echo -e "#! ccc"
		chmod "$o" "$f"
	else
    echo -e "#! ddd"
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
      curl $CURL_OPTS -skL -H"${ora_cookie}" -O -C - "${jdk_url}" && \
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

  curl $CURL_OPTS -L -o "${fn}" -C - "${url}"
  t=$?
  if [ 33 -eq $t ]; then
    curl $CURL_OPTS -L -o "${fn}" "${url}"
  elif [ 60 -eq $t ]; then
    [ -f "${fn}" ] && rm "${fn}"
    curl $CURL_OPTS -k -L -o "${fn}" "${url}"
  else
    return $t
  fi
}

extract_kit() {
  local src="$1"
  local dst="$2"
  local x="${src##*.}"
  local t=0

  [ -d "${dst}" ] && rm -r "${dst}"
  mkdir -p "${dst}"
  
  case "$x" in
    gz|tgz)
      tar xf "${src}" -C "${dst}" --strip-components=1
      ;;
    zip)
      cd `dirname ${src}` && unzip -q -o "${src}" -d"${dst}"
      t=$?
      [ 0 -eq $t ] || return 1
      local d="`ls -d ${dst}/*`"
      [ -d "$d" ] || return 1
      cd "${d}" && cp -r * "${dst}" && rm -r "$d"
      ;;
    jar)
      return 0
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

  if `test -f "${bin}"`; then
		$cmd &>/dev/null
		[ 0 -eq $? ] && return 0
	fi

  if `test -f "${src}"` && `extract_kit "${src}" "${dst}"`; then
    $cmd &>/dev/null
		[ 0 -eq $? ] && return 0
	fi

  if `download_kit "$url" "$src"`; then
    extract_kit "${src}" "${dst}"
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
  local abcl_sh="${RUN_DIR}/bin/abcl"

  `check_kit "abcl --batch" "${abcl_home}"` && return 0

  $(install_kit "${bin_dir}/abcl.jar" \
                "${cmd}" \
                "${abcl_url}" \
                "${abcl_home}/${abcl_tgz}" \
                "${bin_dir}") || return 1

  if `$cmd &>/dev/null`; then
    cat << END > "${abcl_sh}"
#!`type -P bash`
#----------
# generated by $GITHUB_SH
#----------
if \`type -P rlwrap &>/dev/null\`; then
   RLWRAP=rlwrap
fi
ABCL_HOME=${bin_dir}
\$RLWRAP java -jar \${ABCL_HOME}/abcl.jar \$@
END
    chmod_file "${abcl_sh}" "u+x"
    return $?
  fi

  return 1
}

install_ant() {
  local ant_tgz="apache-ant-${ANT_VER}-bin.tar.gz"
  local ant_home="${OPEN_DIR}/ant"
  local ant_url="http://archive.apache.org/dist/ant/binaries/${ant_tgz}"
  local bin_dir="${ant_home}/${ANT_VER}"
  local cmd="${bin_dir}/bin/ant -version"

  `check_kit "ant -version" "${ant_home}"` && return 0

  install_kit "${bin_dir}/bin/ant" \
              "${cmd}" \
              "${ant_url}" \
              "${ant_home}/${ant_tgz}" \
              "${bin_dir}"
  [ 0 -eq $? ] || return 1

  if `${cmd} &>/dev/null`; then
    append_vars "ANT_HOME" "${bin_dir}"
    append_paths "\${ANT_HOME}/bin" "ANT_HOME"
    return 0
  fi
  return 1
}

install_maven() {
  local mvn_tgz="apache-maven-${MAVEN_VER}-bin.tar.gz"
  local mvn_home="${OPEN_DIR}/maven"
  local mvn_url="http://archive.apache.org/dist/maven/maven-3/${MAVEN_VER}/binaries/${mvn_tgz}"
  local bin_dir="${mvn_home}/${MAVEN_VER}"
  local cmd="${bin_dir}/bin/mvn -version"
  
  `check_kit "mvn -version" "${mvn_home}"` && return 0

  install_kit "${bin_dir}/bin/mvn" \
              "${cmd}" \
              "${mvn_url}" \
              "${mvn_home}/${mvn_tgz}" \
              "${bin_dir}"
  [ 0 -eq $? ] || return 1

  if `${cmd} &>/dev/null`; then
    append_vars "MAVEN_HOME" "${bin_dir}"
    append_paths "\${MAVEN_HOME}/bin" "MAVEN_HOME"
    return 0
  fi
  return 1
}

install_boot() {
  local boot_url='https://github.com/boot-clj/boot-bin/releases/download/latest/boot.sh'
  local bin_dir="${RUN_DIR}/bin"
  local boot_sh="${bin_dir}/boot"
  local cmd="boot -v"

  `${cmd} &>/dev/null` && return 0

  if `download_kit "${boot_url}" "${boot_sh}"`; then
    echo -e "!# xxx"
    # chmod_file "${boot_sh}" "u+x"
    chmod u+x "${boot_sh}"
    echo -e "!# xxx"
    return $?
  fi
  echo -e "!# yyy"
  return 1
}

install_lein() {
  local lein_url="https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein"
  local bin_dir="${RUN_DIR}/bin"
  local lein_sh="${bin_dir}/lein"
  local cmd="lein -v"

  `${cmd} &>/dev/null` && return 0

  if `download_kit "${lein_url}" "${lein_sh}"`; then
    chmod_file "${lein_sh}" "u+x"
    return $?
  fi
  return 1
}

install_clojure() {
  local clojure_zip="clojure-${CLOJURE_VER}.zip"
  local clojure_url="https://repo1.maven.org/maven2/org/clojure/clojure/${CLOJURE_VER}/${clojure_zip}"
  local clojure_home="${OPEN_DIR}/clojure"
  local clojure_jar="clojure-${CLOJURE_VER}.jar"
  local bin_dir="${clojure_home}/${CLOJURE_VER}"
  local cmd="java -jar ${bin_dir}/${clojure_jar} --help"
  local clojure_sh="${RUN_DIR}/bin/clojure"
  
  `check_kit "clojure --help" "${clojure_home}"` && return 0

  install_kit "${bin_dir}/${clojure_jar}" \
                "${cmd}" \
                "${clojure_url}" \
                "${clojure_home}/${clojure_zip}" \
                "${bin_dir}"
  [ 0 -eq $? ] || return 1

  if `$cmd &>/dev/null`; then
    cat << END > "${clojure_sh}"
#!`type -P bash`
#----------
# generated by $GITHUB_SH
#----------
if \`type -P rlwrap &>/dev/null\`; then
   RLWRAP=rlwrap
fi
CLOJURE_HOME=${bin_dir}
\$RLWRAP java -jar "\${CLOJURE_HOME}/${clojure_jar}" \$@
END
    chmod_file "${clojure_sh}" "u+x"
    return $?
  fi
  return 1
}

install_clojurescript() {
  local cljs_jar="cljs.jar"
  local cljs_url="https://github.com/clojure/clojurescript/releases/download/r${CLOJURESCRIPT_VER}/${cljs_jar}"
  local cljs_home="${OPEN_DIR}/clojurescript"
  local bin_dir="${cljs_home}"
  local cmd="java -jar ${bin_dir}/${cljs_jar} --help"
  local cljs_sh="${RUN_DIR}/bin/clojurescript"

  `check_kit "clojurescript --help" "${cljs_home}"` && return 0

  install_kit "${bin_dir}" \
              "${cmd}" \
              "${cljs_url}" \
              "${cljs_home}/${cljs_jar}" \
              "${bin_dir}"
  [ 0 -eq $? ] || return 1
  
  if `$cmd &>/dev/null`; then
    cat << END > "${cljs_sh}"
#!`type -P bash`
#----------
# generated by $GITHUB_SH
#----------
if \`type -P rlwrap &>/dev/null\`; then
   RLWRAP=rlwrap
fi
CLOJURESCRIPT_HOME=${bin_dir}
\$RLWRAP java -jar "\${CLOJURESCRIPT_HOME}/${cljs_jar}" \$@
END
    chmod_file "${cljs_sh}" "u+x"
    return $?
  fi  
  return 1
}

install_gradle() {
  local gradle_zip="gradle-${GRADLE_VER}-bin.zip"
  local gradle_url="https://services.gradle.org/distributions/${gradle_zip}"
  local gradle_home="${OPEN_DIR}/gradle"
  local bin_dir="${gradle_home}/${GRADLE_VER}"
	local cmd="${bin_dir}/bin/gradle -v"
	local gradle_sh="${RUN_DIR}/bin/gradle"

	`check_kit "gradle -v" "${gradle_home}"` && return 0

	install_kit "${bin_dir}/bin/gradle" \
							"${cmd}" \
							"${gradle_url}" \
							"${gradle_home}/${gradle_zip}" \
							"${bin_dir}"
	[ 0 -eq $? ] || return 1

  if `$cmd &>/dev/null`; then
		cat << END > "${gradle_sh}"
#!`type -P bash`
#----------
# generated by $GITHUB_SH
#----------
GRADLE_HOME=${bin_dir}
\${GRADLE_HOME}/bin/gradle \$@
END
		chmod_file "${gradle_sh}" "u+x"
		return $?
  fi
  return 1
}

install_sbt() {
  local sbt_zip="sbt-${SBT_VER}.zip"
  local sbt_url="https://github.com/sbt/sbt/releases/download/v${SBT_VER}/${sbt_zip}"
  local sbt_home="${OPEN_DIR}/sbt"
  local bin_dir="${sbt_home}/${SBT_VER}"
  local cmd="${bin_dir}/bin/sbt about"
	local sbt_sh="${RUN_DIR}/bin/sbt"

  `check_kit "sbt about" "${sbt_home}"` && return 0

  install_kit "${bin_dir}/bin/sbt" \
              "${cmd}" \
              "${sbt_url}" \
              "${sbt_home}/${sbt_zip}" \
              "${bin_dir}"

  [ 0 -eq $? ] || return 1

  if `${cmd} &>/dev/null`; then
    cat << END > "${sbt_sh}"
#!`type -P bash`
#----------
# generated by $GITHUB_SH
#----------
SBT_HOME=${bin_dir}
\${SBT_HOME}/bin/sbt \$@
END
    chmod_file "${sbt_sh}" "u+x"
    return $?
  fi
  return 1
}

install_groovy() {
  local groovy_zip="apache-groovy-binary-${GROOVY_VER}.zip"
  local groovy_url="https://dl.bintray.com/groovy/maven/${groovy_zip}"
	local groovy_home="${OPEN_DIR}/groovy"
  local bin_dir="${groovy_home}/${GROOVY_VER}"
  local cmd="GROOVY_HOME=${bin_dir} ${bin_dir}/bin/groovysh --version"

  `check_kit "groovysh --version" "${groovy_home}"` && return 0

  install_kit "${bin_dir}/bin/groovysh" \
              "${cmd}" \
              "${groovy_url}" \
              "${groovy_home}/${groovy_zip}" \
              "${bin_dir}"
  [ 0 -eq $? ] || return 1

  if `${cmd} &>/dev/null`; then
    append_vars "GROOVY_HOME" "${bin_dir}" 
    append_paths "\${GROOVY_HOME}/bin" "GROOVY_HOME"
    return 0
  fi
  return 1 
}

install_scala_vim() {
	local vim_url="https://raw.githubusercontent.com/derekwyatt/vim-scala/master"
	
	[ -f "$HOME/.vim/syntax/scala.vim" ] && return 0

	mkdir -p "$HOME"/.vim/{ftdetect,indent,syntax}
  local ds=( ftdetect indent syntax )
	for d in ${ds[@]}; do
    download_kit "${vim_url}/$d/scala.vim" "$HOME/.vim/$d/scala.vim"
	done

	[ -f "$HOME/.vim/syntax/scala.vim" ] && return 0
  return 1
}

install_scala() {
  local scala_tgz="scala-${SCALA_VER}.tgz"
  local scala_url="http://downloads.lightbend.com/scala/${SCALA_VER}/${scala_tgz}"
  local scala_home="${OPEN_DIR}/scala"
  local bin_dir="${scala_home}/${SCALA_VER}"
  local cmd="${bin_dir}/bin/scala -version"
  local scala_sh="${RUN_DIR}/bin/scala"
	local vim_url="https://raw.githubusercontent.com/derekwyatt/vim-scala/master"

  `check_kit "scala -version" "${scala_home}"` && return 0

  install_kit "${bin_dir}/bin/scala" \
              "${cmd}" \
              "${scala_url}" \
              "${scala_home}/${scala_tgz}" \
              "${bin_dir}"
  [ 0 -eq $? ] || return 1
  
  if `${cmd} &>/dev/null`; then
    [ -d "${RUN_DIR}/share/man/man1" ] || mkdir -p "${RUN_DIR}/share/man/man1" 
    cp -R "${scala_home}/man/man1/." "${RUN_DIR}/share/man/man1/"
    append_vars "SCALA_HOME" "${bin_dir}"
    append_paths "\${SCALA_HOME}/bin" "SCALA_HOME"
    return 0
  fi
  return 1
}

install_storm() {
  local storm_tgz="apache-storm-${STORM_VER}.tar.gz"
  local storm_url="https://archive.apache.org/dist/storm/apache-storm-${STORM_VER}/${storm_tgz}"
  local storm_home="${OPEN_DIR}/storm"
  local bin_dir="${storm_home}/${STORM_VER}"
  local cmd="${bin_dir}/bin/storm version"
  local storm_sh="${RUN_DIR}/bin/storm"

  `check_kit "storm version" "${storm_home}"` && return 0

  install_kit "${bin_dir}/bin/storm" \
              "${cmd}" \
              "${storm_url}" \
              "${storm_home}/${storm_tgz}" \
              "${bin_dir}"
  [ 0 -eq $? ] || return 1
  
  if `${cmd} &>/dev/null`; then
    append_vars "STORM_HOME" "${bin_dir}"
    append_paths "\${STORM_HOME}/bin" "STORM_HOME"
    return 0
  fi
  return 1
}

install_zookeeper() {
  local zookeeper_tgz="zookeeper-${ZOOKEEPER_VER}.tar.gz"
  local zookeeper_url="${APACHE_DIST}/zookeeper/stable/${zookeeper_tgz}"
  local zookeeper_home="${OPEN_DIR}/zookeeper"
  local bin_dir="${zookeeper_home}/${ZOOKEEPER_VER}"
  local cmd="${bin_dir}/bin/zkCli.sh"
  local zookeeper_sh="${RUN_DIR}/bin/storm"

  if [ -x "${cmd}" -a `type -P zkCli.sh &>/dev/null` ]; then
    return 0
  fi

  install_kit "${bin_dir}/bin/zookeeper" \
              "${cmd}" \
              "${zookeeper_url}" \
              "${zookeeper_home}/${zookeeper_tgz}" \
              "${bin_dir}" || return 1
  
  if [ -x "${cmd}" ]; then
    append_vars "ZOOKEEPER_HOME" "${bin_dir}"
    append_paths "\${ZOOKEEPER_HOME}/bin" "ZOOKEEPER_HOME"
    return 0
  fi
  return 1
}


if [ "YES" = "${HAS_ALL}" ]; then
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
  HAS_STORM=1
  HAS_ZOOKEEPER=1
fi

[ 0 -lt ${HAS_JDK} ]            && KITS+=('install_jdk')
[ 0 -lt ${HAS_ANT} ]            && KITS+=('install_ant')
[ 0 -lt ${HAS_ABCL} ]           && KITS+=('install_abcl')
[ 0 -lt ${HAS_MAVEN} ]          && KITS+=('install_maven')
[ 0 -lt ${HAS_BOOT} ]           && KITS+=('install_boot')
[ 0 -lt ${HAS_LEIN} ]           && KITS+=('install_lein')
[ 0 -lt ${HAS_GRADLE} ]         && KITS+=('install_gradle')
[ 0 -lt ${HAS_SBT} ]            && KITS+=('install_sbt')
[ 0 -lt ${HAS_CLOJURE} ]        && KITS+=('install_clojure')
[ 0 -lt ${HAS_CLOJURESCRIPT} ]  && KITS+=('install_clojurescript')
[ 0 -lt ${HAS_GROOVY} ]         && KITS+=('install_groovy')
[ 0 -lt ${HAS_SCALA} ]          && KITS+=('install_scala')
[ 0 -lt ${HAS_SCALA_VIM} ]      && KITS+=('install_scala_vim')
[ 0 -lt ${HAS_STORM} ]          && KITS+=('install_storm')
[ 0 -lt ${HAS_ZOOKEEPER} ]      && KITS+=('install_zookeeper')



  for i in "${KITS[@]}"; do
  echo -e "# ${i} ..." 
  [ -d "${OPEN_DIR}" ] || mkdir "${OPEN_DIR}" && ${i}  
  if [ 0 -eq `${i} &>/dev/null; echo $?` ]; then
    echo -e "# ${i} good."
  else
    echo -e "# ${i} panic!"
  fi
done

[ 0 -lt ${#KITS[@]} ] && . "$HOME/.bashrc"
