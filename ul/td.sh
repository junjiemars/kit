#!/bin/bash
#------------------------------------------------
# require: bash env, tc.sh
# target : tomcat deploy/debug tool
# author : junjiemars@gmail.com
#------------------------------------------------

VERSION="1.2.2"
PLATFORM=${PLATFORM:-`uname -s 2>/dev/null`}

DEP=${DEP:-$(cd `dirname ${BASH_SOURCE[@]}`; pwd -P)}

L_PREFIX="${L_PREFIX:-$DEP}"
R_PREFIX="${R_PREFIX:-${DEP%/}/run/www/tomcat}"
L_WAR_PATH="${L_WAR_PATH}"

JAVA_OPTS=

VER=${VER:-"8.5.16"}
CLEAN=("no" "yes")
DEBUG=("no" "yes")
LISTEN_ON=("0.0.0.0" "localhost" "127.0.0.1")
IP_VER=("4" "6")
STOP_TIMEOUT="${STOP_TIMEOUT:-5}"
START_PORT="${START_PORT:-8080}"
STOP_PORT="${STOP_PORT:-8005}"
JPDA_PORT="${JPDA_PORT:-8000}"

TO_WHERE=("local" "ssh" "docker")
TW_IDX_LOCAL=0
TW_IDX_SSH=1
TW_IDX_DOCKER=2
TW_IDX=${TO_WHERE[TW_IDX_LOCAL]}

BUILD=("no" "yes")
BUILD_CMD=("gradlew" "gradle" "ant" "mvn")
BUILD_DIR="${BUILD_DIR:-$DEP}"
BUILD_OPTS="${BUILD_OPTS:-build}"

SSH_USER="${SSH_USER:-`whoami`}"
SSH_HOST="${SSH_HOST}"

DOCKER_USER="${DOCKER_USER:-`whoami`}"
DOCKER_HOST="${DOCKER_HOST}"

TC_SH="tc.sh"
TD_SHA1SUM_SH="td_sha1sum.sh"
TD_SHELL_BAT="td_shell.bat"


function usage() {
  echo -e "Usage: $(basename $0) [OPTIONS] COMMAND [arg...]"
  echo -e "       $(basename $0) [ -h | --help | -v | --version ]\n"
  echo -e "Options:"
  echo -e "  --help\t\t\t\tPrint this message"
  echo -e "  --version\t\t\t\tPrint version information and quit"
  echo -e ""
  echo -e "  --local-prefix=\t\t\tlocal catalina prefix dir, \n\t\t\t\t\tL_PREFIX='${L_PREFIX}'"
	echo -e ""
  echo -e "  --remote-prefix=\t\t\tremote catalina prefix dir, \n\t\t\t\t\tR_PREFIX='${R_PREFIX}'"
	echo -e ""
  echo -e "  --java-options=\t\t\tjava options, \n\t\t\t\t\tJAVA_OPTS='${JAVA_OPTS}'"
	echo -e ""
  echo -e "  --where=\t\t\t\twhere to deploy, TO_WHERE='$TO_WHERE'"  
  echo -e "  --local-war-path=\t\t\tthe local path of the war, L_WAR_PATH='${L_WAR_PATH}'"
  echo -e "  --ssh-user=\t\t\t\tssh login user, SSH_USER='${SSH_USER}'"
  echo -e "  --ssh-host=\t\t\t\twhich ssh host to login, SSH_HOST='${SSH_HOST}'"
  echo -e "  --docker-user=\t\t\tdocker container user, DOCKER_USER='${DOCKER_USER}'"
  echo -e "  --docker-host=\t\t\tdocker container name, DOCKER_HOST='${DOCKER_HOST}'"
  echo -e ""
  echo -e "  --build=\t\t\t\tforce to build, BUILD='${BUILD}'"
  echo -e "  --build-dir=\t\t\t\tbuilding in where, BUILD_DIR='${BUILD_DIR}'"
  echo -e "  --build-cmd=\t\t\t\twhich building tool to use, BUILD_CMD='${BUILD_CMD}'"
  echo -e "  --build-options=\t\t\tbuilding options, BUILD_OPTS='${BUILD_OPTS}'"
  echo -e ""
  echo -e "  --tomcat-version=\t\t\ttomcat version, VER='$VER'"
  echo -e "  --tomcat-clean=\t\t\tclean tomcat, CLEAN='$CLEAN'"
  echo -e "  --debug=\t\t\t\tstart tomcat in debug mode, DEBUG='${DEBUG}'"  
  echo -e ""
  echo -e "  --listen-on=\t\t\t\tlisten on what address, LISTEN_ON='$LISTEN_ON'"
  echo -e "  --ip-version=\t\t\t\tprefered IP version, IP_VER='${IP_VER}'"
  echo -e "  --stop-timeout=\t\t\tforce stop waiting most ${STOP_TIMEOUT} seconds"
  echo -e "  --start-port=\t\t\t\ttomcat start port, START_PORT='$START_PORT'"
  echo -e "  --stop-port=\t\t\t\ttomcat stop port, STOP_PORT='$STOP_PORT'"
  echo -e "  --jpda-port=\t\t\t\ttomcat debug port, JPDA_PORT='$JPDA_PORT'"
  echo -e ""
  echo -e "A deploy & debug console for tomcat.\n"
  echo -e "Commands:"
  echo -e "  start\t\t\t\t\tstart a tomcat instance"
  echo -e "  stop\t\t\t\t\tstop a tomcat instance"
  echo -e "  build\t\t\t\t\tbuild war which will be deployed"
  echo -e "  check-console\t\t\t\tcheck [$(basename $0)'s console] runtime"
  echo -e "  check-pid\t\t\t\tcheck the pid of the tomcat instance"
  echo -e "  check-exist\t\t\t\tcheck existing of tomcat installation"
  echo -e "  make\t\t\t\t\tmake [$(basename $0)' (s)hell]"
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

function on_darwin() {
	case "$PLATFORM" in
		Darwin) 
			return 0
			;;
		*)
			return 1
			;;
	esac
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

function echo_opts() {
	local name="$1"
	local opts="${@:2}"
	echo "@|1[$name]:$opts"
}

function check_where() {
	local w="$1"

	case "$w" in
		ssh)
			if [ -z "$SSH_USER" ]; then
				echo -e "! --ssh-user=''  =invalid"
				exit 1
			fi
			;;
		docker)
			if [ -z "$DOCKER_USER" ]; then
				echo -e "! --docker-user=''  =invalid"
				exit 1
			fi
			if [ -z "$DOCKER_HOST" ]; then
				echo -e "! --docker-host=''  =invalid"
				exit 1
			fi
			;;
	esac	
}

function export_java_opts() {
	local opts="`echo $@ | tr -s ' '`"
  export JAVA_OPTS="$opts"
}

function gen_docker_sha1sum_sh() {

  echo -e "+ generate Shell L[$TD_SHA1SUM_SH] ..."

  cat << END > "$TD_SHA1SUM_SH"
#!/bin/bash
test -f \$1 && sha1sum \$1 | cut -d' ' -f1
END
  chmod u+x "$TD_SHA1SUM_SH"

  if [ -f "$TD_SHA1SUM_SH" ]; then
    echo -e "# generate Shell L[$TD_SHA1SUM_SH]  =succeed"
    return 0
  else
    echo -e "! generate Shell L[$TD_SHA1SUM_SH]  =failed"
    return 1
  fi
}

function gen_docker_shell_bat() {
  local cmd="$1"
  local args="$2"

  echo -e "+ generate Shell L[$TD_SHELL_BAT>[$cmd]] ..."

  cat << END > "$TD_SHELL_BAT"
@echo off
docker `docker_login_id` $cmd $args
END
  chmod u+x "$TD_SHELL_BAT"

  if [ -f "$TD_SHELL_BAT" ]; then
    echo -e "# generate Shell L[$TD_SHELL_BAT>[$cmd]]  =succeed"
    return 0
  else
    echo -e "! generate Shell L[$TD_SHELL_BAT>[$cmd]]  =failed"
    return 1
  fi
}

function local_src_path() {
  local p="${L_PREFIX%/}"
  echo "$p"
}

function local_dst_path() {
	local lp="${1%}"
	local rp="${2%/}"

	if [ -n "$rp" -a "$rp" != "$lp" ]; then
		echo "$rp"
	else
		echo "$lp"
	fi
}

function local_check_version() {
	local lhs="$1"
	local rhs="$2"
	[ "$lhs" == "$($rhs --version 2>/dev/null)" ]
}

function local_bin_path() {
  local bin="$1"
	local ver="$2"
	local dir="${PWD%/}"
	local sbin=
	local sdir=
  local t=

	sbin="${dir}/$bin"
  if [ -f "$sbin" ] && $(local_check_version $ver "$sbin"); then
    echo "$sbin"
		return 0
	fi

	sdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	sbin="${sdir%/}/$bin"
	if [ -f "$sbin" ] && $(local_check_version $ver "$sbin"); then
		echo "$sbin"
		return 0
	fi

	if [ -f "`type -P $bin 2>/dev/null`" ]; then
		sbin="`type -P $bin 2>/dev/null`"	
		if $(local_check_version $ver "$sbin"); then
			echo "$sbin"
			return 0
		fi
	fi

	curl -qL -O$bin https://raw.githubusercontent.com/junjiemars/kit/master/ul/$bin
	t=$?
	[ 0 -eq $t ] || return $t
	chmod u+x "$bin"

	echo "${dir}/$bin"
  return 0
}

function remote_root_path() {
  local p="${R_PREFIX%/}"
  echo "$p"
}


function remote_ver_path() {
  local p="`remote_root_path $1`/${VER%/}"
  echo "$p"
}


function remote_war_path() {
  local p="`remote_ver_path`/webapps/`basename $L_WAR_PATH`"
  echo "$p"
}

function remote_bin_path() {
  local p="`remote_ver_path`/bin/$1"
  echo "$p"
}

function ssh_login_id() {
  local id="${SSH_USER}${SSH_HOST:+@$SSH_HOST}"
  echo "$id"
}

function docker_login_id() {
  local id="exec -u $DOCKER_USER $DOCKER_HOST"
  echo "$id"
}

function ssh_cp() {
	local lp="$1"
	local rp="$2"
	local w="$3"

	dir_mk "`dirname $rp`" "$w" || return $?
	scp $lp `ssh_login_id`:$rp
}

function docker_cp() {
	local lp="$1"
	local rp="$2"
	local w="$3"
	local t=0
	
	dir_mk "`dirname $rp`" "$w" || return $?

	if `on_darwin`; then
		docker cp -a $lp $DOCKER_HOST:$rp || return $?
		docker exec -it $DOCKER_HOST chown $DOCKER_USER:$DOCKER_USER $rp		
	else
		docker cp $lp $DOCKER_HOST:$rp
	fi
}

function local_cp() {
	local lp1="$1"
	local lp2="$2"
	local w="$3"
	
	[ "$lp1" = "$lp2" ] && return 0

	dir_mk "`dirname $lp2`" "$w" || return $?
	cp "$lp1" "$lp2"
}

function where_abbrev() {
  local w="$1"
  case "$w" in
    ssh)
      echo "S"
      ;;
    docker)
      echo "D"
      ;;
    *)
      echo "L"
      ;;
  esac
}

function do_check_exist() {
  local w="$1"
  local wa="`where_abbrev $w`"
  local t=

  echo -e "+ check Tomcat $wa[$VER] existing ..."

  check_console $w
  t=$?
  if [ 0 -ne $t ]; then
    echo -e "+ check Tomcat $wa[$VER] existing  =failed"
    return $t
  fi

  control_tomcat check-exist "$w"
  t=$?
  if [ 0 -eq $t ]; then
    echo -e "+ check Tomcat $wa[$VER] existing  =succeed"
  else
    echo -e "! check Tomcat $wa[$VER] existing  =failed"
  fi

  return $t
}

function check_console() {
  local w="$1"
  local wa="`where_abbrev $w`"
  local tc=
  local t=

  echo -e "+ check Console $wa[$TC_SH] ..."

  case "$w" in
    ssh)
      tc="`remote_bin_path $TC_SH`"
      transport_file "`local_bin_path $TC_SH $VERSION`" "$tc" "$w"
      t=$?
      ;;
    docker)
      #dir_mk "`remote_ver_path`/bin" "$w"
      #t=$?
      #if [ 0 -ne $t ]; then
      #  echo -e "! check Console $wa[$VER]  =failed"
      #  return $t
      #fi
      #
      tc="`remote_bin_path $TC_SH`"
      transport_file "`local_bin_path $TC_SH $VERSION`" "$tc" "$w"
      t=$?

      gen_docker_sha1sum_sh
      let t=$t+$?
      ;;
    *)
      tc="`local_bin_path $TC_SH $VERSION`"
      t=$?
      ;;
  esac
  
  if [ 0 -eq $t ]; then
    echo -e "# check Console $wa[$TC_SH]  =succeed"
  else
    echo -e "! check Console $wa[$TC_SH]  =failed"
  fi
  return $t
}

function file_eq() {
  local lp="$1"
  local rp="$2"
  local w="$3"
  local wa="`where_abbrev $w`"

  echo -e "? L[$lp] eq $wa[$rp] ..."

  echo -e "+ check L[$lp] existing ..."
  if [ ! -f "$lp" ]; then
    echo -e "! check L[$lp] existing  =failed"
    return 1
  fi
  echo -e "# check L[$lp] existing  =succeed"

  local lh="`$sha1sum $lp | cut -d' ' -f1`"
  local rh=

  case "$w" in
    ssh)
		  rh=`ssh $(ssh_login_id) "test -f $rp && $sha1sum $rp 2>/dev/null | cut -d' ' -f1"`
      ;;
    docker)
      local rbp="`remote_bin_path $TD_SHA1SUM_SH`"
      transport_file "$TD_SHA1SUM_SH" "$rbp" "$w"
      t=$?
      if [ 0 -eq $t ]; then
        if `on_win32`; then
          gen_docker_shell_bat "$rbp" "$rp"
          t=$?
          if [ 0 -eq $t ]; then
            rh=`./$TD_SHELL_BAT`
          fi
        else
			    rh=`docker $(docker_login_id) $rbp $rp`
        fi
      fi
      ;;
    *)
      rh="`test -f "$rp" && $sha1sum "$rp" | cut -d' ' -f1`"
      ;;
  esac

  if [ -n "$lh" -a "$lh" = "$rh" ]; then
    echo -e "# L[$lp] eq $wa[$rp]  =true"
    return 0
  else
    echo -e "! L[$lp] eq $wa[$rp]  =false"
    return 1
  fi
}

function dir_mk() {
  local d="$1"
  local w="$2"
  local wa="`where_abbrev $w`"
  local t=

  echo -e "+ mkdir $wa[$d] ..."

  case "$w" in
    ssh)
      ssh `ssh_login_id` mkdir -p "$d"
      t=$?
      ;;
    docker)
      if `on_win32`; then
        gen_docker_shell_bat "mkdir -p $d"
        t=$?
        if [ 0 -eq $t ]; then
          ./$TD_SHELL_BAT
          t=$?
        fi
      else
        docker `docker_login_id` mkdir -p "$d"
      fi
      t=$?
      ;;
    *)
			[ -d "$d" ] || mkdir -p "$d"
      t=$?
      ;;
  esac

  if [ 0 -eq $t ]; then
    echo -e "# mkdir $wa[$d]  =succeed"
  else
    echo -e "! mkdir $wa[$d]  =failed"
  fi
  return $t
}

function build_war() {
  local lwp="$1"
  local cmd=

  echo -e "+ build L[$lwp] ..."
  case "$BUILD_CMD" in
    gradlew*)
      cmd="${BUILD_DIR%/}/$BUILD_CMD"
      ;;
    *)
      cmd="$BUILD_CMD"
      ;;
  esac
  if [ ! -d "$BUILD_DIR" ]; then
    echo -e "! build L[$lwp]: L[$BUILD_DIR] non-exists  =failed"
    return 1
  fi

  if [ ! -x "$cmd" ]; then
    echo -e "! build L[$lwp]: --build-cmd=$cmd no found  =failed"
    return 1
  fi

  cd "$BUILD_DIR" && "$cmd" ${BUILD_OPTS}
  local t=$?

  if [ 0 -eq $t -a -f "$lwp" ]; then
    echo -e "# build L[$lwp] via [$cmd:${BUILD_OPTS}]  =succeed"
    return 0
  fi
  echo -e "! build L[$lwp] via [$cmd:${BUILD_OPTS}]  =failed"
  return 1
}

function transport_file() {
  local lp="$1"
  local rp="$2"
  local w="$3"
  local wa="`where_abbrev $w`"
  local t=

  echo -e "+ transport L[$lp] to $wa[$rp] ..."
  if [ ! -f "$lp" ]; then
    echo -e "! L[$lp]: does not exist  =failed"
  fi

  case "$w" in
    ssh)
	  	ssh_cp "$lp" "$rp" "$w"
      t=$?
      ;;
    docker)
			docker_cp "$lp" "$rp" "$w"
      t=$?
      ;;
    *)
			local_cp "$lp" "$rp" "$w"
			t=$?
      ;;
  esac
  if [ 0 -eq $t ]; then
    echo -e "# transport L[$lp] to $wa[$rp]  =succeed"
  else
    echo -e "! transport L[$lp] to $wa[$rp]  =failed"
  fi
  return $t
}

function delete_war_dir() {
  local lf="$1"
  local w="$2"
  local wa="`where_abbrev $w`"
  local rf="`remote_war_path`"
	local lfn="`basename $lf`"
	local rd="`dirname $rf`"
	local rdw="${rd%/}/${lfn%.*}"
  local t=

	echo -e "+ delete $wa[$rdw] ..."

  case "$w" in
    ssh)
      ssh `ssh_login_id` test -d "$rdw"
			t=$?
			if [ 0 -eq $t ]; then
				ssh `ssh_login_id` rm -r "$rdw"
				t=$?
			fi

			if [ 0 -eq $t ]; then	
				file_eq "$lf" "$rf" "$w"
				t=$?
				if [ 0 -ne $t ]; then
					transport_file "$lf" "`dirname $rf`" "$w"
					t=$?
				fi
			fi
      ;;
		docker)
			if `on_win32`; then
        gen_docker_shell_bat "test" "-d ${rdw}"
        t=$?
        if [ 0 -eq $t ]; then
          ./$TD_SHELL_BAT
          t=$?
          if [ 0 -eq $t ]; then
            gen_docker_shell_bat "rm" "-r ${rdw}"
            t=$?
            if [ 0 -eq $t ]; then
              ./$TD_SHELL_BAT
              t=$t
            fi
          fi
        fi
			else
				docker `docker_login_id` test -d "$rdw"
				t=$?
				if [ 0 -eq $t ]; then
					docker `docker_login_id` rm -r "$rdw"
					t=$?
				fi
			fi
			;;
    *)
			if [ -d "$rdw" ]; then
				rm -r "$rdw"
      	t=$?
			else
				t=0
			fi
     ;; 
  esac

	if [ 0 -eq $t ]; then
		echo -e "# delete $wa[$rdw]  =succeed"
	else
		echo -e "! delete $wa[$rdw]  =failed"
	fi
  return $t
}

function transport_war() {
  local lf="$1"
  local w="$2"
  local wa="`where_abbrev $w`"
  local rf="`remote_war_path`"
  local t=

	delete_war_dir "$lf" "$w"

  case "$w" in
    ssh|docker)
      file_eq "$lf" "$rf" "$w"
      t=$?
      if [ 0 -ne $t ]; then
        transport_file "$lf" "`dirname $rf`" "$w"
        t=$?
      fi
      ;;
    *)
      transport_file "$lf" "`dirname $rf`" "$w"
      t=$?
     ;; 
  esac
  return $t
}

function install_tomcat() {
  local w="$1"
  local wa="`where_abbrev $w`"
  local tc="`local_bin_path $TC_SH $VERSION`"
  local t=

  echo -e "+ install Tomcat $wa[$VER] ..."

  local tgz="apache-tomcat-$VER.tar.gz"
  local ltgz=(
		"`local_src_path`/$tgz" 
		"/tmp/$tgz" 
		"${HOME%/}/Downloads/$tgz"
	)
	local ltgz_x=
  local rtgz="`remote_root_path`/$tgz"

  for f in "${ltgz[@]}"; do
    if [ -f "$f" ]; then
      $tc install "${TO_WHERE[$TW_IDX_LOCAL]}" "--prefix=`dirname $f`"
      t=$?
      if [ 0 -eq $t ]; then
        ltgz_x="$f"
        break;
      fi
    fi
  done

  if [ -z "$ltgz_x" ]; then
    $tc install                              \
        --download-only=yes                  \
        --tomcat-version="$VER"              \
        --prefix=.
    t=$?
    if [ 0 -ne $t ]; then
      echo -e "! install Tomcat $wa[$VER]  =failed"
      return $t
    fi
  fi

  transport_file "$ltgz_x" "$rtgz" "$w"
  file_eq "$ltgz_x" "$rtgz" "$w"
  t=$?
  if [ 0 -ne $t ]; then
     echo -e "! install Tomcat $wa[$VER]  =failed"
     return $t
  fi

  local ltgz_sha1="${ltgz_x}.sha1"
  local rtgz_sha1="${rtgz}.sha1"

  transport_file "$ltgz_sha1" "$rtgz_sha1" "$w"
  file_eq "$ltgz_sha1" "$rtgz_sha1" "$w"
  t=$?
  if [ 0 -ne $t ]; then
    echo -e "! install Tomcat $wa[$VER]  =failed"
    return $t
  fi

  control_tomcat install "$w"
}

function control_tomcat() {
  local cmd="$1"
  local w="$2"
  local opts=("${@:3}")
  local wa="`where_abbrev $w`"
  local tc=
  local t=

  echo -e "+ control Tomcat => $wa[$cmd] ..."
	echo_opts "JAVA_OPTS" "${JAVA_OPTS}"
	echo_opts "aux*opts" "${opts[@]}"

  case "$w" in
    ssh)
      tc="`remote_bin_path $TC_SH`"
      ssh `ssh_login_id` $tc $cmd                    \
          --prefix=$R_PREFIX                         \
          --tomcat-version=$VER                      \
          --listen-on=$LISTEN_ON                     \
          --ip-version=$IP_VER                       \
          --start-port=$START_PORT                   \
          --stop-port=$STOP_PORT                     \
          --stop-timeout=$STOP_TIMEOUT               \
					--java-options=\'"${JAVA_OPTS}"\'          \
          ${opts[@]}
      t=$?
      ;;
    docker)
      if `on_win32`; then
        local cmd_args="$cmd                           \
               --prefix=$R_PREFIX                      \
               --tomcat-version=$VER                   \
               --listen-on=$LISTEN_ON                  \
               --ip-version=$IP_VER                    \
               --start-port=$START_PORT                \
               --stop-port=$STOP_PORT                  \
               --stop-timeout=$STOP_TIMEOUT            \
							 --java-options=\"${JAVA_OPTS}\""        \
               ${opts[@]}
        cmd_args="`echo $cmd_args | tr -s ' '`"
        gen_docker_shell_bat "`remote_bin_path $TC_SH`" "$cmd_args"
        t=$?
        if [ 0 -eq $t ]; then
          ./$TD_SHELL_BAT
          let t=$t+$?
        fi
      else
        tc="`remote_bin_path $TC_SH`"
        docker `docker_login_id`                       \
               $tc $cmd                                \
               --prefix=$R_PREFIX                      \
               --tomcat-version=$VER                   \
               --listen-on=$LISTEN_ON                  \
               --ip-version=$IP_VER                    \
               --start-port=$START_PORT                \
               --stop-port=$STOP_PORT                  \
               --stop-timeout=$STOP_TIMEOUT            \
							 --java-options="${JAVA_OPTS}"           \
               ${opts[@]}
        t=$?
      fi
      ;;
    *)
      tc="`local_bin_path $TC_SH $VERSION`"
      $tc $cmd																			 						\
          --prefix=$(local_dst_path $L_PREFIX $R_PREFIX) 	 			\
          --tomcat-version=$VER                									\
          --listen-on=$LISTEN_ON               									\
          --ip-version=$IP_VER                 									\
          --start-port=$START_PORT             									\
          --stop-port=$STOP_PORT               									\
          --stop-timeout=$STOP_TIMEOUT         									\
					--java-options="${JAVA_OPTS}"                         \
          ${opts[@]}	
      t=$?
      ;;
  esac
  
  if [ 0 -eq $t ]; then
    echo -e "# control Tomcat => $wa[$cmd]  =succeed"
  else
    echo -e "! control Tomcat => $wa[$cmd]  =failed"
  fi
  return $t
}

function backup_file() {
	local f="$1"
	local b="${f}.pre"

	if [ -f "$f" ]; then
		mv "${f}" "${f}.pre"
	fi
  echo "$f"
}

function gen_td_debug_sh() {
	local tds="$1"
	local td="$2"

	cat << END >> "$tds"
# debug env

\${td} \\
	--local-prefix=\${DEP} \\
	--remote-prefix=\${R_PREFIX:-$R_PREFIX} \\
	--tomcat-version=\${VER:-$VER} \\
	--tomcat-clean=\${CLEAN:-${CLEAN[0]}} \\
	--java-options="\${JAVA_OPTS:-${JAVA_OPTS[@]}}" \\
	--local-war-path=\${L_WAR_PATH:-$L_WAR_PATH} \\
	--listen-on=\${LISTEN_ON:-${LISTEN_ON[0]}} \\
	--ip-version=\${IP_VER:-${IP_VER[0]}} \\
	--ssh-user=\${SSH_USER:-${SSH_USER[@]}} \\
	--ssh-host=\${SSH_HOST:-${SSH_HOST[@]}} \\
	--docker-user=\${DOCKER_USER:-$DOCKER_USER} \\
	--docker-host=\${DOCKER_HOST:-$DOCKER_HOST} \\
	--build=\${BUILD:-${BUILD[0]}} \\
	--build-dir=\${BUILD_DIR:-\${DEP}} \\
	--build-cmd=\${BUILD_CMD:-$BUILD_CMD} \\
	--build-options=\${BUILD_OPTS:-$BUILD_OPTS} \\
	--stop-timeout=\${STOP_TIMEOUT:-$STOP_TIMEOUT} \\
	--start-port=\${START_PORT:-$START_PORT} \\
	--stop-port=\${STOP_PORT:-$STOP_PORT} \\
	--debug=\${DEBUG:-${DEBUG[1]}} \\
	--jpda-port=\${JPDA_PORT:-$JPDA_PORT} \\
  --where=\${TO_WHERE:-${TW_IDX}} \\
	"\$@"
END
}

function gen_td_cluster_sh() {
	local tds="$1"
	local td="$2"

	cat << END >> "$tds"
# cluster env

## NODE=\`seq 9601 2 9604\` "$tds" [OPTIONS] COMMAND args ...
## will auto generate:
## NODE=( n9601 n9603 )
## UPORT=( 9601 9603 )
## DPORT=( 9600 9602 )


NODE=( \${NODE} )
UPORT=( \${UPORT:-\${NODE[@]}} )
DPORT=( \${DPORT:-\`for n in \${NODE[@]}; do echo \$(( n-1 )); done\`} )
W3="\${W3:-\${DEP%/}/run/www}"

echo "NODE=(\${NODE[@]})"
echo "UPORT=(\${UPORT[@]})"
echo "DPORT=(\${DPORT[@]})"
echo "W3=\${W3}"

if [ 0 -eq \${#UPORT} ]; then
  echo -e "! size of UPORT is zero  =invalid"
  exit 1
fi

if [ \${#UPORT[@]} -ne \${#DPORT[@]} ]; then
	echo -e "! size of UPORT and DPORT mismatch  =invalid"
	exit 1
fi

if [ 0 -eq \${#NODE[@]} ]; then
  echo -e "! size of NODE is zero  =invalid"
  exit 1
fi

for n in "\${!NODE[@]}"; do
	NODE[n]="n\${NODE[n]}"
done


for n in \${!NODE[@]}; do
	echo -e "---------------------------------"
	echo -e "\${NODE[\$n]}:\${UPORT[\$n]}:\${DPORT[\$n]}"
	echo -e "---------------------------------"

	[ -d "\${W3}/\${NODE[\$n]}" ] || mkdir -p "\${W3}/\${NODE[\$n]}"

	\${td} \\
		--local-prefix=\${DEP} \\
		--remote-prefix=\${W3%/}/\${NODE[\$n]} \\
		--tomcat-version=\${VER:-$VER} \\
		--tomcat-clean=\${CLEAN:-${CLEAN[1]}} \\
		--java-options="\${JAVA_OPTS:-${JAVA_OPTS[@]}}" \\
		--local-war-path=\${L_WAR_PATH:-$L_WAR_PATH} \\
		--listen-on=\${LISTEN_ON:-${LISTEN_ON[2]}} \\
		--ip-version=\${IP_VER:-${IP_VER[0]}} \\
		--stop-timeout=\${STOP_TIMEOUT:-$STOP_TIMEOUT} \\
		--start-port=\${UPORT[\$n]} \\
		--stop-port=\${DPORT[\$n]} \\
		"\$@"

done
END
}

function do_make() {
  local tds="`backup_file ${L_PREFIX%/}/tds.sh`"
  local tdp="$(dirname $0)"
  local td="${tdp%/}/$(basename $0)"

  cat << END > "$tds"
#!/bin/bash
## --------------------
## generated by td.sh
## @ https://raw.githubusercontent.com/junjiemars/kit
##--------------------

function check_version() {
	local lhs="\$1"
	local rhs="\$2"
	[ "\$lhs" == "\$(\$rhs --version 2>/dev/null)" ]
}

function download_td_sh() {
  local bin="\$1"
	local ver="\$2"
	local dir="\$3"
	local sbin=
	local sdir=
  local t=

	sbin="\${dir}/\$bin"
  if [ -f "\$sbin" ] && \$(check_version \$ver "\$sbin"); then
		chmod u+x "\$sbin"
    echo "\$sbin"
		return 0
	fi

	sbin="\$(type -P \$bin 2>/dev/null)"	
	if \$(check_version \$ver "\$sbin"); then
		echo "\$sbin"
		return 0
	fi

	curl -qL -O\$bin https://raw.githubusercontent.com/junjiemars/kit/master/ul/\$bin
	t=\$?
	[ 0 -eq \$t ] || return \$t
	chmod u+x "\$bin"

	echo "\${dir}/\$bin"
  return 0
}


DEP="\${DEP:-\$(cd \`dirname \${BASH_SOURCE[0]}\`; pwd -P)}"

td=\$(download_td_sh "td.sh" "$VERSION" "\$DEP")
[ 0 -eq \$? ] || echo "! missing td.sh" 

END

	if [ "yes" = "$DEBUG" ]; then
		gen_td_debug_sh "$tds" "$td"
	else
		gen_td_cluster_sh "$tds" "$td"
	fi

  chmod u+x "$tds"
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

    --local-prefix=*)        l_prefix="$value"   		    ;;
    --remote-prefix=*)       r_prefix="$value"   		    ;;
    --java-options=*)        java_opts="${java_opts:+$java_opts }$value"		      ;;
    
    --where=*)               to_where="$value"          ;;
    --local-war-path=*)      L_WAR_PATH="$value"	      ;;
    --ssh-user=*)            SSH_USER="$value"	        ;;
    --ssh-host=*)            SSH_HOST="$value"	        ;;
    --docker-user=*)         DOCKER_USER="$value"       ;;
    --docker-host=*)         DOCKER_HOST="$value"	      ;;

    --build=*)               opt_build="$value"         ;;
    --build-dir=*)           build_dir="$value"	        ;;
    --build-cmd=*)           build_cmd="$value"	        ;;
    --build-options=*)       BUILD_OPTS="$value"	      ;;

    --tomcat-version=*)      VER="$value"      			    ;;
    --tomcat-clean=*)        opt_clean="$value"     	  ;;
    --debug=*)               opt_debug="$value"         ;;

    --listen-on=*)           LISTEN_ON="$value"		      ;;
    --ip-version=*)          IP_VER="$value"	   	      ;;
    --stop-timeout=*)        STOP_TIMEOUT="$value"		  ;;
    --start-port=*)          START_PORT="$value"			  ;;
    --stop-port=*)           STOP_PORT="$value" 			  ;;
    --jpda-port=*)           JPDA_PORT="$value"  			  ;;

    *)
      command="$option"
    ;;
  esac
done


if [ "$help" = "yes" -o 0 -eq $# ]; then
	usage
	exit 0
fi

if [ "$version" = "yes" ]; then
	echo -e "$VERSION"
	exit 0
fi

# setup env vars
retval=0

if [ -n "$l_prefix" ]; then
  L_PREFIX="$l_prefix"
fi

if [ -n "$r_prefix" ]; then
  R_PREFIX="$r_prefix"
fi

if [ -n "$opt_build" ]; then
	BUILD=`opt_check $opt_build ${BUILD[@]}`
	retval=$?
	if [ 0 -ne $retval ]; then
		echo -e "! --build=\"$opt_build\"  =invalid"
		exit $retval
	fi	
fi

if [ -n "$build_dir" ]; then
  BUILD_DIR="`eval echo $build_dir`"
fi

if [ -n "$build_cmd" ]; then
  BUILD_CMD="$build_cmd"
fi

if [ -n "$opt_debug" ]; then
	DEBUG=`opt_check $opt_debug ${DEBUG[@]}`
	retval=$?
	if [ 0 -ne $retval ]; then
		echo -e "! --debug=\"$opt_debug\"  =invalid"
		exit $retval
	fi	
fi

if [ -n "$opt_clean" ]; then
	CLEAN=`opt_check $opt_clean ${CLEAN[@]}`
	retval=$?
	if [ 0 -ne $retval ]; then
		echo -e "! --tomcat-clean='$opt_clean'  =invalid"
		exit $retval
	fi	
fi

if [ -n "$L_WAR_PATH" ]; then
  L_WAR_PATH="`eval echo $L_WAR_PATH`"
fi

if [ -n "$to_where" ]; then
	TW_IDX="`opt_check $to_where ${TO_WHERE[@]}`"
	retval=$?
	if [ 0 -ne $retval ]; then
		echo -e "! --where='$to_where'  =invalid"
		exit $retval
	fi
fi

check_where "$TW_IDX" || exit $?

export_alias
export_java_opts "${java_opts}"
echo_opts "JAVA_OPTS" "${JAVA_OPTS}"

function do_build() {
	if [ -z "$L_WAR_PATH" ]; then
		echo -e "! --local-war-path='${L_WAR_PATH}'  =invalid"
		exit
	fi			

  if [ "yes" = "$BUILD" ]; then
    build_war "$L_WAR_PATH" || exit $?
	fi

	if [ ! -f "$L_WAR_PATH" ]; then
		echo -e "! --local-war-path='${L_WAR_PATH}'  =invalid"
		exit 1
	fi
}

command="`echo $command | tr '[:upper:]' '[:lower:]'`"
case "$command" in

  build)
    do_build
    ;;
  start)
    do_build

    do_check_exist "$TW_IDX"
    retval=$?
    if [ 0 -ne $retval ]; then
      install_tomcat "$TW_IDX"
      retval=$?
      [ 0 -eq $retval ] || exit $retval
    fi

		if [ "yes" = "$CLEAN" ]; then
			control_tomcat clean "$TW_IDX"
		fi

    transport_war "$L_WAR_PATH" "$TW_IDX"
    if [ "yes" = "$DEBUG" ]; then
			export JPDA_PORT="$JPDA_PORT"
      control_tomcat debug "$TW_IDX"
    else
      control_tomcat start "$TW_IDX"
    fi
    ;;
  stop)
    do_check_exist "$TW_IDX" || exit $?
    control_tomcat stop "$TW_IDX"
    ;;
  check-console)
    check_console "$TW_IDX"
    ;;
  check-env)
    do_check_exist "$TW_IDX" || exit $?
    control_tomcat check-env "$TW_IDX"
    ;;
  check-pid)
    do_check_exist "$TW_IDX" || exit $?
    control_tomcat check-pid "$TW_IDX"
    ;;
  check-exist)
    do_check_exist "$TW_IDX"
    ;;
  make)
    do_make
    ;;
  *)
    echo "$0: error: invalid command \"$command\""
		usage
    ;;
esac
