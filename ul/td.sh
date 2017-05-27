#!/bin/bash
#------------------------------------------------
# require: bash env, tc.sh
# target : tomcat debugger 
# author : junjiemars@gmail.com
#------------------------------------------------


# env 
PLATFORM=${PLATFORM:-`uname -s`}
OPT_RUN=${OPT_RUN:-"/opt/run"}
PREFIX=${PREFIX:-"${OPT_RUN%/}/www/tomcat"}
VERSION="1.2.1"

JAVA_OPTS="${JAVA_OPTS}"
DEBUG=("no" "yes")

VER=${VER:-"8.5.8"}
TC_OPTS=
TC_SH="tc.sh"


STOP_TIMEOUT="${STOP_TIMEOUT:3}"
START_PORT="${START_PORT:-8080}"
STOP_PORT="${STOP_PORT:-8005}"
JPDA_PORT="${JPDA_PORT:-8000}"

TO_WHERE=("local" "ssh" "docker")
TW_IDX=
TW_IDX_LOCAL=0
TW_IDX_SSH=1
TW_IDX_DOCKER=2

L_WAR_PATH="${L_WAR_PATH}"
R_WAR_PATH=
R_TC_PATH=

BUILD=("no" "yes")
BUILD_CMD=("gradlew" "gradle" "ant" "mvn")
BUILD_DIR="${BUILD_DIR:-.}"
BUILD_OPTS="${BUILD_OPTS:-build}"


SSH_USER="$USER"
SSH_HOST=

DOCKER_USER="$USER"
DOCKER_HOST=

TD_SHA1SUM_SH="td_sha1sum.sh"


usage() {
  echo -e "Usage: $(basename $0) [OPTIONS] COMMAND [arg...]"
  echo -e "       $(basename $0) [ -h | --help | -v | --version ]\n"
  echo -e "Options:"
  echo -e "  --help\t\t\t\tPrint this message"
  echo -e "  --version\t\t\t\tPrint version information and quit"
  echo -e "  --prefix\t\t\t\tcatalina prefix dir"
  echo -e "  --tomcat-version\t\t\ttomcat version, default is $VER"
  echo -e "  --tc-options\t\t\t\ttc.sh options"
  echo -e "  --java-options\t\t\tjava options, JAVA_OPTS"
  echo -e "  --debug\t\t\t\tstart tomcat in debug mode"
  echo -e "  --local-war-path\t\t\tthe local path of the war"
  echo -e "  --where\t\t\t\twhere to deploy, ${TO_WHERE[@]}"
  echo -e "  --build\t\t\t\tforce to build, default is $BUILD"
  echo -e "  --build-dir\t\t\t\tbuilding in where"
  echo -e "  --build-cmd\t\t\t\twhich building tool to use, default is ${BUILD_CMD}"
  echo -e "  --build-options\t\t\tbuilding options, default is ${BUILD_OPTS}"
  echo -e "  --ssh-user\t\t\t\tssh login user, default is ${SSH_USER}"
  echo -e "  --ssh-host\t\t\t\twhich ssh host to login"
  echo -e "  --docker-user\t\t\t\tdocker container user, default is ${DOCKER_USER}"
  echo -e "  --docker-host\t\t\t\tdocker container name"
  echo -e "  --start-port\t\t\t\ttomcat start port, default is $START_PORT"
  echo -e "  --stop-port\t\t\t\ttomcat stop port, default is $STOP_PORT"
  echo -e "  --jpda-port\t\t\t\ttomcat debug port, default is $JPDA_PORT\n"
  echo -e "A tiny-handy console for tomcat.\n"
  echo -e "Commands:"
  echo -e "  build\t\t\t\t\tbuild war which will be deployed"
  echo -e "  start\t\t\t\t\tstart a tomcat instance"
  echo -e "  stop\t\t\t\t\tstop a tomcat instance"
  echo -e "  check-env\t\t\t\tcheck the environment of the tomcat instance"
  echo -e "  check-pid\t\t\t\tcheck the pid of the tomcat instance"
  echo -e "  check-exist\t\t\t\tcheck the pid of the tomcat instance"
}


export_java_opts() {
  JAVA_OPTS="-Dstart.port=${START_PORT}      \
             -Dstop.port=${STOP_PORT}        \
             -Dlisten.address=${LISTEN_ON}   \
             ${JAVA_OPTS}"
  export JAVA_OPTS=`echo "${JAVA_OPTS}" | tr -s " "`
}

function gen_docker_sha1sum_sh() {
  if [ ! -f "$TD_SHA1SUM_SH" ]; then
    cat << END > "$TD_SHA1SUM_SH"
#!/bin/bash
test -f \$1 && sha1sum \$1 | cut -d' ' -f1
END
    chmod u+x "$TD_SHA1SUM_SH"
  fi
}

function local_bin_path() {
  local bin="$1"
  if [ -f "$bin" ]; then
    echo "${PWD%/}/$bin"
  elif [ -f "`which $bin 2>/dev/null`" ]; then
    echo "`which $bin`"
  else
    curl -L -O$bin https://raw.githubusercontent.com/junjiemars/kit/master/ul/$bin
    echo "${PWD%/}/$bin"
  fi
}

function remote_root_path() {
  local p="${PREFIX%/}"
  echo "$p"
}

function remote_ver_path() {
  local p="`remote_root_path`/${VER%/}"
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
  local id="$SSH_USER${SSH_HOST:+@$SSH_HOST}"
  echo "$id"
}

function is_file_exist() {
  local p="$1"
  local w="$2"
  local lr="R"
  local t=

  echo -e "? check [$p] is exist ..."
  case "$w" in
    ssh)
      ssh `ssh_login_id` test -f $p
      t=$?
      ;;
    docker)
      docker exec -u $DOCKER_USER $DOCKER_HOST test -f $p
      t=$?
      ;;
    *)
      test -f $p
      t=$?
      lr="L"
      ;;
  esac
  if [ 0 -eq $t ]; then
    echo -e "# $lr[$p] exist   =true"
  else
    echo -e "! $lr[$p] exist   =false"
  fi
  return $t
}

function check_exist() {
  local w="$1"
  local t=

  echo -e "+ check Tomcat[$VER] existing ..."

  if [ "${TO_WHERE[$TW_IDX_LOCAL]}" = "$w" ]; then
    control_tomcat check-exist "$w"
    return $?
  fi

  local rp="`remote_bin_path catalina.sh`"
  is_file_exist "$rp" "$w"
  t=$?
  if [ 0 -ne $t ]; then
    echo -e "! check Tomcat[$VER] existing: catalina.sh no found  =failed"
    return $t
  fi

  case "$w" in
    ssh)
      ssh `ssh_login_id` $rp version
      t=$?
      ;;
    docker)
      docker exec -u $DOCKER_USER $DOCKER_HOST $rp version
      t=$?
      ;;
  esac

  if [ 0 -eq $t ]; then
    echo -e "# check Tomcat[$VER] existing  =succeed"
  else
    echo -e "! check Tomcat[$VER] existing  =failed"
  fi
  return $t
}

function control_tomcat() {
  local cmd="$1"
  local w="$2"
  local tc=
  local t=

  echo -e "+ control Tomcat =>[$cmd] ..."
  case "$w" in
    ssh)
      tc="`remote_bin_path $TC_SH`"
      is_file_eq "`local_bin_path $TC_SH`" "$tc" "$w"
      if [ 0 -ne $? ]; then
        transport_file "`local_bin_path $TC_SH`" "$tc" "$w"
        t=$?
        [ 0 -eq $t ] || return $t
      fi
      
      ssh `ssh_login_id` $tc $cmd                    \
          --prefix=$PREFIX                           \
          --tomcat-version=$VER                      \
          --start-port=$START_PORT                   \
          --stop-port=$STOP_PORT                     \
          ${TC_OPTS}          
      t=$?
      ;;
    docker)
      tc="`remote_bin_path $TC_SH`"
      is_file_eq "`local_bin_path $TC_SH`" "$tc" "$w"
      if [ 0 -ne $? ]; then
        transport_file "`local_bin_path $TC_SH`" "$tc" "$w"
        t=$?
        [ 0 -eq $t ] || return $t
      fi

      docker exec -u $DOCKER_USER $DOCKER_HOST       \
             "`remote_bin_path $TC_SH`" $cmd         \
             --prefix=$PREFIX                        \
             --tomcat-version=$VER                   \
             --start-port=$START_PORT                \
             --stop-port=$STOP_PORT                  \
             ${TC_OPTS}          
      t=$?
      ;;
    *)
      tc="`local_bin_path $TC_SH`"
      $tc $cmd                                       \
          --prefix=$PREFIX                           \
          --tomcat-version=$VER                      \
          --start-port=$START_PORT                   \
          --stop-port=$STOP_PORT                     \
          ${TC_OPTS}
      t=$?
      ;;
  esac
  
  if [ 0 -eq $t ]; then
    echo -e "# control Tomcat =>[$cmd]  =succeed"
  else
    echo -e "! control Tomcat =>[$cmd]  =failed"
  fi
  return $t
}

function mkdir_remote() {
  local d="$1"
  local w="$2"
  local t=

  echo -e "+ mkdir R[$d] ..."

  case "$w" in
    ssh)
      ssh `ssh_login_id` mkdir -p "$d"
      t=$?
      ;;
    docker)
      docker exec -u $DOCKER_USER $DOCKER_HOST mkdir -p "$d"
      t=$?
      ;;
    *)
      echo -e "# mkdir R[$d]: in local  =skipped"
      t=0
      ;;
  esac

  if [ 0 -eq $t ]; then
    echo -e "+ mkdir R[$d]  =succeed"
  else
    echo -e "- mkdir R[$d]  =failed"
  fi
  return $t
}

function install_tomcat() {
  local w="$1"
  local tc=
  local t=

  echo -e "+ install Tomcat[$VER] ..."
  if [ "${TO_WHERE[$TW_LOCAL]}" = "$w" ]; then
    control_tomcat install "$w"
    return $?
  fi

  tc="`local_bin_path $TC_SH`"
  t=$?
  if [ 0 -ne $t ]; then
    echo -e "! install Tomcat[$VER]: $TC_SH no found  =failed"
    return $t
  fi

  local tgz="apache-tomcat-$VER.tar.gz"
  local ltgz=("`remote_root_path`/$tgz" "/tmp/$tgz" "./$tgz")
  local rtgz="`remote_ver_path`/$tgz"

  for f in "${ltgz[@]}"; do
    if [ -f "$f" ]; then
      ltgz="$f"
      break;
    fi
  done

  if [ ! -f "${ltgz[0]}" ]; then
    $tc install --download-only --tomcat-version="$VER" --prefix="`dirname ${ltgz[0]}`"
    t=$?
    [ 0 -eq $t ] || return $t
  fi

  mkdir_remote "`remote_ver_path`/bin" "$w"
  t=$?
  [ 0 -eq $t ] || return $t

  is_file_eq "${ltgz[0]}" "$rtgz"
  t=$?
  if [ 0 -ne $t ]; then
    transport_file "${ltgz[0]}" "$rtgz" "$w"
    t=$?
    [ 0 -eq $t ] || return $t
  fi

  control_tomcat install "$w"
}

function is_file_eq() {
  local lp="$1"
  local rp="$2"
  local w="$3"

  echo -e "? L[$lp] eq with R[$rp] ..."
  if [ ! -f "$lp" ]; then
    echo -e "! L[$1] does not exist."
    return 1
  fi

  local lh="`sha1sum $lp | cut -d' ' -f1`"
  local rh="`test -f "$rp" && sha1sum "$rp" | cut -d' ' -f1`"

  case "$w" in
    ssh)
		  rh=`ssh $(ssh_login_id) "test -f $rp && sha1sum $rp | cut -d' ' -f1"`
      ;;
    docker)
		  case "$PLATFORM" in
			  MSYS_NT*)
				  rh=`./$TD_SHA1SUM_BAT`
				  ;;
			  *)
          echo -e "+ generate D[$TD_SHA1SUM_SH] ..."
          gen_docker_sha1sum_sh
          t=$?
          if [ 0 -ne $t ]; then
            echo -e "! generate D[$TD_SHA1SUM_SH]  =failed"
            return $t
          else
            echo -e "# generate D[$TD_SHA1SUM_SH]  =succeed"
          fi
          
          local rbp="`remote_bin_path $TD_SHA1SUM_SH`"
          transport_file "$TD_SHA1SUM_SH" "$rbp" "$w"
          t=$?
          [ 0 -eq $t ] || return $t

				  rh=`docker exec -u $DOCKER_USER $DOCKER_HOST $rbp $rp`
				  ;;
		  esac       
      ;;
  esac

  if [ "$lh" = "$rh" ]; then
    echo -e "# L[$lp] eq with R[$rp]  =true"
    return 0
  else
    echo -e "! L[$lp] eq with R[$rp]  =false"
    return 1
  fi
}

function build_war() {
  local lwp="$1"
  local cmd=

  echo -e "+ build L[$lwp}] ..."
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
    echo -e "! build L[$lwp]: build command no found  =failed"
    return 1
  fi

  cd "$BUILD_DIR" && "$cmd" ${BUILD_OPTS}
  local t=$?
  if [ 0 -eq $t ]; then
    echo -e "# build L[$lwp}]  =succeed"
  else
    echo -e "! build L[$lwp}]  =failed"
  fi
  return $t
}

function transport_file() {
  local lp="$1"
  local rp="$2"
  local w="$3"
  local t=

  echo -e "+ transport L[$lp] to R[$rp] ..."
  if [ ! -f "$lp" ]; then
    echo -e "! L[$lp] does not exist."
  fi

  case "$w" in
    ssh)
	  	scp $lp `ssh_login_id`:$rp
      t=$?
      ;;
    docker)
      docker cp $lp $DOCKER_HOST:$rp
      t=$?
      ;;
    *)
	    cp $lp $rp
      t=$?
      ;;
  esac
  if [ 0 -eq $t ]; then
    echo -e "# transport L[$lp] to R[$rp]  =succeed"
  else
    echo -e "! transport L[$lp] to R[$rp]  =failed"
  fi
  return $t
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

    --prefix=*)              prefix="$value"   			    ;;
    --tomcat-version=*)      VER="$value"      			    ;;
    --tc-options=*)          tc_opts="$value"		        ;;

    --java-options=*)        java_opts="$value"		      ;;
    --debug)                 DEBUG=yes    		          ;;

    --where=*)               where="$value"		          ;;
    --local-war-path=*)      L_WAR_PATH="$value"	      ;;
    --ssh-user=*)            SSH_USER="$value"	        ;;
    --ssh-host=*)            SSH_HOST="$value"	        ;;
    --docker-user=*)         DOCKER_USER="$value"       ;;
    --docker-host=*)         DOCKER_HOST="$value"	      ;;

    --build)                 BUILD=yes    		          ;;
    --build-dir=*)           build_dir="$value"	        ;;
    --build-cmd=*)           build_cmd="$value"	        ;;
    --build-options=*)       BUILD_OPTS="$value"	      ;;

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

if [ -n "$prefix" ]; then
  PREFIX="$prefix"
fi

if [ -n "$tc_opts" ]; then
  TC_OPTS="${TC_OPTS:+$TC_OPTS }${tc_opts}"
fi

if [ -n "$java_opts" ]; then
  JAVA_OPTS="${JAVA_OPTS:+$JAVA_OPTS }${java_opts}"
fi

if [ -n "$build_dir" ]; then
  BUILD_DIR="`eval echo $build_dir`"
fi

if [ -n "$build_cmd" ]; then
  BUILD_CMD="$build_cmd"
fi

if [ -n "$L_WAR_PATH" ]; then
  L_WAR_PATH="`eval echo $L_WAR_PATH`"
fi

if [ -n "$where" ]; then
  for i in "${!TO_WHERE[@]}"; do
    if [ "${TO_WHERE[$i]}" = "$where" ]; then
      TW_IDX=$i
      break;
    fi
  done
  if [ -z "$TW_IDX" ]; then
    echo -e "! --where=$where  =invalid"
    exit 1
  fi
fi

export_java_opts

retval=0
command="`echo $command | tr '[:upper:]' '[:lower:]'`"
case "$command" in
  build)
    build_war "$L_WAR_PATH"
    exit $?
    ;;
  start)
    if [ -z "$L_WAR_PATH" ]; then
      echo -e "! missing --local-war-path=* options."
      usage
      exit 1
    fi
    is_file_exist "$L_WAR_PATH" "${TO_WHERE[$TW_IDX_LOCAL]}"
    retval=$?
    if [ "yes" = "$BUILD" -o 0 -ne $retval ]; then
      build_war "$L_WAR_PATH"
      retval=$?
      [ 0 -eq $retval ] || exit $retval
    fi

    check_exist "${TO_WHERE[$TW_IDX]}"
    retval=$?
    if [ 0 -ne $retval ]; then
      install_tomcat "${TO_WHERE[$TW_IDX]}"
      retval=$?
      [ 0 -eq $retval ] || exit $retval
    fi

    R_WAR_PATH="`remote_war_path`"
    is_file_eq "$L_WAR_PATH" "$R_WAR_PATH" "${TO_WHERE[$TW_IDX]}"
    retval=$?
    if [ 0 -ne $retval ]; then
      transport_file "$L_WAR_PATH" "`dirname $R_WAR_PATH`" "${TO_WHERE[$TW_IDX]}"
      retval=$?
      [ 0 -eq $retval ] || exit $retval
    fi
    
    if [ "$DEBUG" = "yes" ]; then
      export JPDA_PORT="$JPDA_PORT"
      control_tomcat debug "${TO_WHERE[$TW_IDX]}"
    else
      control_tomcat start "${TO_WHERE[$TW_IDX]}"
    fi
    exit $?
    ;;
  stop)
    check_exist "${TO_WHERE[$TW_IDX]}"
    retval=$?
    [ 0 -eq $retval ] || exit $t
    control_tomcat stop "${TO_WHERE[$TW_IDX]}"
    exit $?
    ;;
  check-env)
    check_exist "${TO_WHERE[$TW_IDX]}"
    retval=$?
    [ 0 -eq $retval ] || exit $t
    control_tomcat check-env "${TO_WHERE[$TW_IDX]}"
    exit $?
    ;;
  check-pid)
    check_exist "${TO_WHERE[$TW_IDX]}"
    retval=$?
    [ 0 -eq $retval ] || exit $t
    control_tomcat check-pid "${TO_WHERE[$TW_IDX]}"
    exit $?
    ;;
  check-exist)
    check_exist "${TO_WHERE[$TW_IDX]}"
    exit $?
    ;;
  *)
    echo "$0: error: invalid command \"$command\""
		usage
    exit 1    
    ;;
esac
