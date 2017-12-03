#!/bin/bash
#------------------------------------------------
# target: tomcat console
# author: junjiemars@gmail.com
#------------------------------------------------

VERSION="1.2.2"
PLATFORM="`uname -s 2>/dev/null`"

DEP="${DEP:-$(cd `dirname ${BASH_SOURCE[0]}`; pwd -P)}"
OPT_RUN="${OPT_RUN:-${DEP%/}/run}"
PREFIX="${PREFIX:-${OPT_RUN%/}/www/tomcat}"

VER="${VER:-8.5.16}"
CATALINA_BASE=
CATALINA_OPTS=

JAVA_OPTS=

STOP_TIMEOUT="${STOP_TIMEOUT:-10}"
STOP_FORCE="${STOP_FORCE:--force}"

IP_VER=("4" "6")
IP_IDX=
IP_OPTS=("-Djava.net.preferIPv4Stack=true" "-Djava.net.preferIPv6Addresses=true")

LISTEN_ON=("localhost" "127.0.0.1" "0.0.0.0")
START_PORT=${START_PORT:-8080}
STOP_PORT=${STOP_PORT:-8005}
JPDA_PORT=${JPDA_PORT:-8000}

DOWNLOAD_ONLY=("no" "yes")


function usage() {
  echo -e "Usage: $(basename $0) [OPTIONS] COMMAND [arg...]"
  echo -e "       $(basename $0) [ -h | --help | -v | --version ]\n"
  echo -e "Options:"
  echo -e "  --help\t\t\t\tPrint this message"
  echo -e "  --version\t\t\t\tPrint version information and quit"
  echo -e ""
  echo -e "  --prefix=\t\t\t\tcatalina prefix dir, PREFIX='${PREFIX}'"
  echo -e "  --java-options=\t\t\tjava options, JAVA_OPTS='${JAVA_OPTS}'"
  echo -e "  --tomcat-version=\t\t\ttomcat version, VER${VER:+='$VER'}"
  echo -e "  --catalina-options=\t\t\tcatalina options, CATALINA_OPTS='${CATALINA_OPTS}'"
  echo -e "  --download-only\t\t\tdownload tomcat tgz file only, DOWNLOAD_ONLY='$DOWNLOAD_ONLY'"
  echo -e ""
  echo -e "  --listen-on=\t\t\t\tlisten on what address, LISTEN_ON='${LISTEN_ON}'"
  echo -e "  --ip-version=\t\t\t\tprefered IP protocol version, IP_VER='${IP_VER}'"
  echo -e "  --stop-timeout=\t\t\tforce waiting STOP_TIMEOUT='$STOP_TIMEOUT' seconds before stop"
  echo -e "  --start-port=\t\t\t\ttomcat start port, START_PORT='${START_PORT}'"
  echo -e "  --stop-port=\t\t\t\ttomcat stop port, STOP_PORT='${STOP_PORT}'"
  echo -e "  --jpda-port=\t\t\t\ttomcat debug port, JPDA_PORT='${JPDA_PORT}'"
  echo -e ""
  echo -e "A tiny-handy console for tomcat."
  echo -e ""
  echo -e "Commands:"
  echo -e "  start\t\t\t\t\tstart a tomcat instance"
  echo -e "  stop\t\t\t\t\tstop a tomcat instance"
  echo -e "  debug\t\t\t\t\tstart a tomcat instance in debug mode"
  echo -e "  check-env\t\t\t\tcheck environment of specified tomcat instance"
  echo -e "  check-pid\t\t\t\tcheck pid of specified tomcat instance"
  echo -e "  check-exist\t\t\t\tcheck existing of tomcat installation"
  echo -e "  install\t\t\t\tinstall tomcat"
  echo -e "  verify\t\t\t\tverify tomcat tgz with sha1"
  echo -e "  parameterize\t\t\t\tparameterize tomcat's configurations"
  echo -e "  clean\t\t\t\t\tclean tomcat webapps or other useless things"
}


function export_alias() {
  case "$PLATFORM" in
		Darwin)
			export sha1sum="shasum -a1"
			;;
    *)
			export sha1sum=sha1sum
      ;;
  esac
}

function export_java_opts() {
  local opts="-Dstart.port=${START_PORT}      \
              -Dstop.port=${STOP_PORT}        \
              -Dlisten.address=${LISTEN_ON}   \
              ${IP_OPTS[$IP_IDX]}             \
							$@"
	opts="`echo $opts | tr -s ' '`"
  export JAVA_OPTS="${opts}"
}

function export_catalina_opts() {
	local opts="$@"
  export CATALINA_OPTS="`echo $opts | tr -s ' '`"
}

function export_catalina_base() {
	local prefix="$1"
	local ver="$2"

	export CATALINA_BASE="${prefix%/}/${ver}"
  export CATALINA_PID="${CATALINA_BASE%/}/logs/pid"
	CATALINA_BIN="${CATALINA_BASE}/bin/catalina.sh"
}

function do_parameterize() {
  local base_dir="$1"
  local server_xml="${base_dir%/}/conf/server.xml"
  echo -e "+ parameterize Tomcat[server.xml] ..."

  if [ ! -w "${server_xml}" ]; then
    echo -e "! parameterize Tomcat[server.xml]: file no found  =failed"
    return 1
  fi

  local stop_soft='<Server port="\${stop\.port}" shutdown="SHUTDOWN">'
  local start_soft='<Connector port="\${start\.port}" protocol="HTTP\/1\.[10]"'
  local addr_soft='<Connector port="\${start\.port}" protocol="HTTP\/1\.[10]" address="\${listen.address}"'
  local stop_old='<Server port="\([0-9]*\)" shutdown="SHUTDOWN">'
  local stop_new='<Server port="\${stop\.port}" shutdown="SHUTDOWN">'
  local start_old='<Connector port="\([0-9]*\)" protocol="HTTP'
  local start_new='<Connector port="\${start\.port}" protocol="HTTP'
  local addr_old='<Connector port="\(.*\)" protocol="\(HTTP\/1\.[10]\)"'
  local addr_new='<Connector port="\1" protocol="\2" address="\${listen.address}"'

  [ -f "${server_xml}.ori" ] || cp "${server_xml}" "${server_xml}.ori"
  
  if [ 0 -ne `grep "${stop_soft}" "${server_xml}" &>/dev/null; echo $?` ]; then
    sed -i -e "s/${stop_old}/${stop_new}/" "${server_xml}"
  fi

  if [ 0 -ne `grep "${start_soft}" "${server_xml}" &>/dev/null; echo $?` ]; then
    sed -i -e "s/${start_old}/${start_new}/" "${server_xml}"
  fi

  if [ 0 -ne `grep "${addr_soft}" "${server_xml}" &>/dev/null; echo $?` ]; then
    sed -i -e "s/${addr_old}/${addr_new}/" "${server_xml}"
  fi

  echo -e "# parameterize Tomcat[server.xml]  =succeed"
  return 0
}


function echo_opts() {
	local name="$1"
	local opts="${@:2}"
	echo "@|0[$name]:${opts[@]}"
}

function opt_check() {
	local a=( "$@" )
	if [ 0 -eq ${#a[@]} ]; then
		return 1
	fi

	for i in ${a[@]:1}; do
		local opt="`echo ${a[0]} | tr [:upper:] [:lower:]`"
		if [ ".$opt" = ".$i" ]; then
			echo "$opt"
			return 0
		fi
	done
	return 1
}

function on_win32() {
  case "$PLATFORM" in
    MSYS_NT*|MINGW*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}


function unix_path() {
	local p="$1"
	if `on_win32`; then
		echo "$p" | sed -e 's#^\([a-zA-Z]\):/#/\l\1/#'
	else
		echo "$p"
	fi
}


function do_check_env() {
  local pid="`get_pid`"
  local run="Stopped"
  local t=

  if [ 0 -eq `ps -p $pid &>/dev/null;echo $?` ]; then
    run="Running"
  fi

  echo -e "+ check Tomcat environment [$pid] ...$run"
  echo -e "+ check Tomcat version ..."

  check_catalina_bin
  t=$?
  if [ 0 -eq $t ]; then
    echo -e "# check Tomcat version  =succeed"
    ${CATALINA_BIN} version
    return $?
  else
    echo -e "! check Tomcat version  =failed"
    return 1
  fi
}


function do_check_pid() {
  local pid="`get_pid`"
  local t=

  echo "$pid"
  if [ 0 -eq `ps -p $pid &>/dev/null;echo $?` ]; then
    return 0
  else
    return 1
  fi
}


function do_check_exist() {
  ${CATALINA_BIN} version &>/dev/null
}


function do_clean() {
	local base="${1%/}/webapps"
	local apps=("docs" "examples" "host-manager" "manager" "ROOT")
	
  echo -e "+ clean Tomcat[$base] ..."

	for d in "${apps[@]}"; do
		local p="${base%/}/$d"		
		if [ -d "$p" ]; then
			rm -r "$p"
		fi
	done

  echo -e "# clean Tomcat[$base]  =succeed" 
}


function do_verify() {
  local lhs="$1"
  local rhs="$2"

  echo -e "+ verify Tomcat[$rhs] ..."

  if [ ! -f "$lhs" -o ! -f "$rhs" ]; then
    echo -e "! verify Tomcat[$rhs]  =failed"
    return 1
  fi

  local rsha1="`cat $rhs | cut -d' ' -f1`"
  if [ -z "$rsha1" ]; then
   echo -e "! verify Tomcat[$rhs]  =failed"
   return 1
  fi

  local lsha1="`$sha1sum $lhs 2>/dev/null | cut -d' ' -f1`"
  if [ "$lsha1" = "$rsha1" ]; then
    echo -e "# verify Tomcat[$rhs]  =succeed"
    return 0
  else
    echo -e "! verify Tomcat[$rhs]  =failed"
    return 1
  fi
}


function download_file() {
  local d="$1"
  local lf="$2"
  local rf="$3"
  local t=

  echo -e "+ download Tomcat[$rf] ..."
	if [ ! -d "$d" ]; then
    mkdir -p "$d"
    t=$?
    if [ 0 -ne $t ]; then
      echo -e "! download Tomcat[$rf]  =failed"
      return $t
    fi
  fi

  cd "$d" && curl -sL -o"${lf}" -C - "${rf}"
  t=$?
  if [ 33 -eq $t ]; then
    cd "$d" && curl -sL -o"${lf}" "${rf}"
		t=$?
  fi

  if [ 0 -ne $t ]; then
    echo -e "! download Tomcat[$rf]  =failed"
  else
    echo -e "# download Tomcat[$rf]  =succeed"    
  fi

  return $t
}


function download_tomcat() {
  local d="$1"
  local ltgz="$2"
  local ltgz_sha1="$3"
  local rtgz="$4"
  local rtgz_sha1="$5"
  local t=

  do_verify "$ltgz" "$ltgz_sha1" && return 0 

	download_file "$d" "$ltgz_sha1" "$rtgz_sha1" && return 0

	do_verify "$ltgz" "$ltgz_sha1" && return 0

	download_file "$d" "$ltgz" "$rtgz" || return $?
	
	do_verify "$ltgz" "$ltgz_sha1" 
}


function tomcat_tgz() {
  local ver="$1"
  local tgz="apache-tomcat-${ver}.tar.gz"
  echo "$tgz"
}


function tomcat_tgz_sha1() {
  local ver="$1"
  local sha1="`tomcat_tgz $ver`.sha1"
  echo "$sha1"
}


function tomcat_tgz_path() {
  local h="$1"
  local v="$2"
  local p="${h%/}/`tomcat_tgz $v`"
  echo "$p"
}


function tomcat_tgz_sha1_path() {
  local h="$1"
  local v="$2"
  local p="${h%/}/`tomcat_tgz_sha1 $v`"
  echo "$p"
}


function do_install() {
  local tgz="`tomcat_tgz ${VER}`"
  local tgz_sha1="`tomcat_tgz_sha1 ${VER}`"
  local major="${VER%%.*}"
  local head="https://archive.apache.org/dist/tomcat/tomcat-${major}/v${VER}/bin"
	local url_tgz="${head}/${tgz}"
  local url_sha1="${head}/${tgz_sha1}"
  local ltgz="`tomcat_tgz_path ${PREFIX} ${VER}`"
  local ltgz_sha1="`tomcat_tgz_sha1_path ${PREFIX} ${VER}`"
  local t=

  echo -e "+ install Tomcat[$VER] ..."

  if [ "yes" = "$DOWNLOAD_ONLY" ]; then
		download_tomcat "$PREFIX" "$ltgz" "$ltgz_sha1" "$url_tgz" "$url_sha1"
		t=$?
		return $t
  fi

  echo -e "+ check Tomcat[$VER] existing ..."
  if `do_check_exist`; then
    echo -e "# check Tomcat[$VER] existing  =succeed"
    echo -e "# install Tomcat[$VER]  =succeed"
    return 0
  fi
  echo -e "! check Tomcat[$VER] existing  =failed"
  
	download_tomcat "$PREFIX" "$ltgz" "$ltgz_sha1" "$url_tgz" "$url_sha1"
	t=$?
	if [ 0 -ne $t ]; then
		echo -e "! install Tomcat[$VER]  =failed"
		return $t
  fi

  [ -d "${CATALINA_BASE}" ] || mkdir -p "${CATALINA_BASE}"
  tar -xf "`unix_path ${ltgz}`" -C "${CATALINA_BASE}" --strip-components=1

  if `do_check_exist`; then
    echo -e "# install Tomcat[$VER]  =succeed"
    return 0
  else
    echo -e "! install Tomcat[$VER]  =failed"
    return 1
  fi
}


function check_env_java() {
	echo -e "+ check \$JAVA_HOME ..."
  if [ -d "${JAVA_HOME}" ]; then
    echo -e "# check \$JAVA_HOME=${JAVA_HOME}  =succeed"
    return 0
	fi

	local java_home=

  case "${PLATFORM}" in
    Darwin)
      java_home='/usr/libexec/java_home'
      [ -L "${java_home}" ] && export JAVA_HOME=`${java_home} 2>/dev/null`
      ;;

    Linux)
      local javac=`type -p javac 2>/dev/null`
      [ -n "${javac}" ] && \
				java_home=$(readlink -f "${javac}" | sed 's:/bin/javac::')
      [ -n "${java_home}" ] && export JAVA_HOME="${java_home}"
      ;; 

    MSYS_NT*|MINGW*)
      ;;

    *)
      ;;
  esac

	if [ -f "${JAVA_HOME%/}/bin/java" ]; then
		if `${JAVA_HOME%/}/bin/java -version &>/dev/null`; then
			echo -e "# check \$JAVA_HOME=${JAVA_HOME}  =succeed"
			return 0
		fi
	fi

	echo -e "! check \$JAVA_HOME  =failed"
	return 1
}


function check_catalina_bin() {
  echo -e "+ check \$CATALINA_BIN ..."
  if [ -x "${CATALINA_BIN}" ]; then
    echo -e "# check \$CATALINA_BIN=${CATALINA_BIN}  =succeed"
    return 0
  else
    echo -e "! check \$CATALINA_BIN  =failed"
    return 1
  fi
}


function get_pid() {
	if [ ! -f "${CATALINA_PID}" ]; then
		return 1
	fi
	cat "${CATALINA_PID}" 2>/dev/null
}


function do_stop() {
  local pid="`get_pid`"
  local t=
  echo -e "+ stop Tomcat[$pid] ..."
  "${CATALINA_BIN}" stop "${STOP_TIMEOUT}" "${STOP_FORCE}"
  t=$?
  if [ 0 -eq $t ]; then
    echo -e "# stop Tomcat[$pid]  =succeed"
  else
    echo -e "! stop Tomcat[$pid]  =failed"
  fi
  return $t
}


function do_start() {
  "${CATALINA_BIN}" start
}


function do_debug() {
  local t=
  echo -e "+ debug Tomcat ..."

  JPDA_ADDRESS="${JPDA_PORT}" "${CATALINA_BIN}" jpda start
  t=$?
  if [ 0 -eq $t ]; then
    echo -e "# debug Tomcat  =succeed"
    return $t
  else
    echo -e "! debug Tomcat  =failed"
    return 1
  fi
}


for option
do
  opt="$opt `echo $option | sed -e \"s/\(--[^=]*=\)\(.* .*\)/\1'\2'/\"`"
  
  case "$option" in
    -*=*) value=`echo "$option" | sed -e 's/[-_a-zA-Z0-9]*=//'` ;;
    *) value="" ;;
  esac
  
  case "$option" in
    --help)                  help=yes                   ;;
    --version)               version=yes      			    ;;

    --prefix=*)              prefix="$value"            ;;
    --java-options=*)        java_opts="$value"         ;;
    --tomcat-version=*)      tomcat_ver="$value"        ;;
    --catalina-options=*)    catalina_opts="$value"     ;;
    --download-only=*)       download_only="$value"     ;;

    --listen-on=*)           LISTEN_ON="$value"         ;;
    --ip-version=*)          ip_ver="$value"            ;;
    --stop-timeout=*)        STOP_TIMEOUT="$value"		  ;;
    --start-port=*)          START_PORT="$value"			  ;;
    --stop-port=*)           STOP_PORT="$value" 			  ;;
    --jpda-port=*)           JPDA_PORT="$value"  			  ;;

    *)
			case "$option" in
				-*)
					echo "$0: error: invalid option \"$option\""
					exit 1
				;;

				*) 
      		command="$option"
				;;
			esac
    ;;
  esac
done


if [ "yes" = "$help" -o 0 -eq $# ]; then
	usage
	exit 0
fi

if [ "yes" = "$version" ]; then
	echo -e "$VERSION"
	exit 0
fi

# setup env vars
retval=0

if [ -n "$prefix" ]; then
  PREFIX="$prefix"
fi

if [ -n "$tomcat_ver" ]; then
  VER="$tomcat_ver"
fi

if [ -n "$download_only" ]; then
	DOWNLOAD_ONLY=`opt_check $download_only ${DOWNLOAD_ONLY[@]}`
	retval=$?
	if [ 0 -ne $retval ]; then
		echo -e "! --download-only='$DOWNLOAD_ONLY'  =invalid"
		exit $retval
	fi	
fi

if [ -n "$ip_ver" ]; then
	IP_VER=`opt_check $ip_ver ${IP_VER[@]}`
	retval=$?
  if [ 0 -ne $retval ]; then
    echo -e "! --ip-version='$ip_ver'  =invalid"
    exit $retval
  fi
fi


export_alias
export_java_opts "$java_opts"
export_catalina_opts "$catalina_opts"
export_catalina_base "${PREFIX}" "${VER}"

echo_opts "VER" "${VER}"
echo_opts "PREFIX" "${PREFIX}"
echo_opts "JAVA_OPTS" "${JAVA_OPTS}"
echo_opts "CATALINA_BASE" "${CATALINA_BASE}"
echo_opts "CATALINA_OPTS" "${CATALINA_OPTS}"
echo_opts "CATALINA_BIN" "${CATALINA_BIN}"


command="`echo $command | tr '[:upper:]' '[:lower:]'`"
case "$command" in
  install)
		check_env_java || exit $?
    do_install
    ;;
  verify)
    do_verify "`tomcat_tgz_path $PREFIX $VER`" "`tomcat_tgz_sha1_path $PREFIX $VER`"
    ;;
  parameterize)
    do_parameterize "$CATALINA_BASE"
		;;
	clean)
		do_clean "$CATALINA_BASE"
    ;;
  check-env)
		check_env_java || exit $?
    do_check_env
    ;;
  check-pid)
    do_check_pid
    ;;
  check-exist)
		check_env_java || exit $?
    do_check_exist
    ;;
  start)
    do_parameterize "$CATALINA_BASE" || exit $?
		check_env_java || exit $?
    check_catalina_bin || exit $?
    do_start
    ;;
  stop)
		check_env_java || exit $?
    check_catalina_bin || exit $?
    do_stop
    ;;
  debug)
    do_parameterize "$CATALINA_BASE" || exit $?
		check_env_java || exit $?
    check_catalina_bin || exit $?

    catalina_opts="${catalina_opts:+$catalina_opts }-XX:+HeapDumpOnOutOfMemoryError"
    catalina_opts="${catalina_opts:+$catalina_opts }-XX:HeapDumpPath=${CATALINA_BASE}/logs"
    export_catalina_opts "$catalina_opts"
    do_debug
    ;;
  *)
    echo "$0: error: invalid command \"$command\""
    exit 1    
    ;;
esac
