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

#TC_SH_ENV=${TC_SH_ENV:-"PREFIX=$PREFIX VER=$VER START_PORT=$START_PORT STOP_PORT=$STOP_PORT JPDA_PORT=$JPDA_PORT JAVA_OPTS=$JAVA_OPTS"}



#TO_BUILD=("no" "yes")


#HAS_SSH=${HAS_SSH:-1}
#SSH_USER=${SSH_USER:-}
#SSH_HOST=${SSH_HOST:-}
#
## docker
#HAS_DOCKER=${HAS_DOCKER:-1}
#DOCKER_CONTAINER=${DOCKER_CONTAINER:-"java-dev"}
#DOCKER_USER=${DOCKER_USER:-"u"}
#DOCKER_TC_SH=${DOCKER_TC_SH:-"${OPT_RUN}/bin/$TC_SH"}
#
## war 
#BUILD=${BUILD:-0}
#BUILD_CMD=("gradlew")
#BUILD_DIR="${BUILD_DIR:-.}"
#BUILD_TASK="${BUILD_TASK:-build}"
#
#BUILD_LOG=${BUILD_LOG:-"td-build.log"}
#WAR_TARGET=${WAR_TARGET:-"-Dwar.target=local"}
#WAR_TASK="${WAR_TASK}"
#WAR_DIR="${PREFIX}/${VER}/webapps/"
#WAR_NAME=${WAR_NAME:-}
#R_WAR_FILE="${WAR_DIR}${WAR_NAME}.war"
#L_WAR_FILE="${BUILD_DIR%/}/${WAR_NAME}.war"
#
## platform
#TD_CTRL_BAT="td-ctrl.bat"
#TD_CTRL_SH="${TD_CTRL_BAT%.*}.sh"
#TD_SHA1SUM_BAT="td-sha1sum.bat"
#TD_SHA1SUM_SH="${TD_SHA1SUM_BAT%.*}.sh"
#TD_RM_BAT="td-rm.bat"
#R_TD_CTRL_SH="$OPT_RUN/bin/$TD_CTRL_SH"
#R_TD_SHA1SUM_SH="$OPT_RUN/bin/$TD_SHA1SUM_SH"


usage() {
  echo -e "Usage: $(basename $0) [OPTIONS] COMMAND [arg...]"
  echo -e "       $(basename $0) [ -h | --help | -v | --version ]\n"
  echo -e "Options:"
  echo -e "  --help\t\t\t\tPrint this message"
  echo -e "  --version\t\t\t\tPrint version information and quit"
  echo -e "  --prefix\t\t\t\tcatalina prefix dir"
  echo -e "  --tomcat-version\t\t\ttomcat version, default is $VER"
  echo -e "  --java-options\t\t\tjava options, JAVA_OPTS"
  echo -e "  --tc-path\t\t\t\t\ttc.sh path"
  echo -e "  --tc-options\t\t\t\ttc.sh options"
  echo -e "  --start-port\t\t\t\ttomcat start port, default is $START_PORT"
  echo -e "  --stop-port\t\t\t\ttomcat stop port, default is $STOP_PORT"
  echo -e "  --jpda-port\t\t\t\ttomcat debug port, default is $JPDA_PORT"
  echo -e "  --war-path\t\t\t\twhere war file exists"
  echo -e "  --where\t\t\t\twhere to deploy, ${TO_WHERE[@]}\n"
  echo -e "A tiny-handy console for tomcat.\n"
  echo -e "Commands:"
  echo -e "  build\t\t\t\t\tbuild war which will be deployed"
  echo -e "  start\t\t\t\t\tstart a tomcat instance"
  echo -e "  stop\t\t\t\t\tstop a tomcat instance"
  echo -e "  debug\t\t\t\t\tstart a tomcat instance in debug mode"
  echo -e "  check\t\t\t\t\tcheck the environment of the tomcat instance"
}


export_java_opts() {
  JAVA_OPTS="-Dstart.port=${START_PORT}      \
             -Dstop.port=${STOP_PORT}        \
             -Dlisten.address=${LISTEN_ON}   \
             ${JAVA_OPTS}"
  export JAVA_OPTS=`echo "${JAVA_OPTS}" | tr -s " "`
}


gen_platform_sh() {
	if [ ! -f $TD_SHA1SUM_SH ]; then
		cat << END > $TD_SHA1SUM_SH
#!/bin/bash
test -f $R_WAR_FILE && sha1sum $R_WAR_FILE | cut -d' ' -f1
END
		chmod u+x $TD_SHA1SUM_SH
	fi


	if [ ! -f $TD_CTRL_SH ]; then
		cat << END > $TD_CTRL_SH
#!/bin/bash
export PREFIX=$PREFIX 
export VER=$VER
export START_PORT="$START_PORT"
export STOP_PORT="$STOP_PORT"
export JPDA_PORT="$JPDA_PORT"
export JAVA_OPTS="$JAVA_OPTS"

$DOCKER_TC_SH \$@
END
		chmod u+x $TD_CTRL_SH
	fi

	case $PLATFORM in
		MSYS_NT*)
			if [ ! -f $TD_CTRL_BAT ]; then
				cat << END > $TD_CTRL_BAT
@echo off
docker exec $DOCKER_CONTAINER $R_TD_CTRL_SH %1 
END
				chmod u+x $TD_CTRL_BAT
			fi

			if [ ! -f $TD_SHA1SUM_BAT ]; then
				cat << END > $TD_SHA1SUM_BAT
@echo off
docker exec $DOCKER_CONTAINER $R_TD_SHA1SUM_SH 
END
				chmod u+x $TD_SHA1SUM_BAT
			fi

			if [ ! -f $TD_RM_BAT ]; then
				cat << END > $TD_RM_BAT
@echo off
docker exec $DOCKER_CONTAINER rm -rf ${WAR_DIR}${WAR_NAME} $R_WAR_FILE
END
				chmod u+x $TD_RM_BAT
			fi
			;;
		*)
			;;
	esac
}

function local_bin_path() {
  local bin="$1"
  if [ -f "$bin" ]; then
    echo "${PWD%/}/$bin"
  elif [ -f "`which $bin 2>/dev/null`" ]; then
    echo "`which $bin`"
  else
    curl -sqL -O$bin https://raw.githubusercontent.com/junjiemars/kit/master/ul/$bin
    echo "${PWD%/}/$bin"
  fi
}

function remote_war_path() {
  local p="${PREFIX%/}/$VER/webapps/`basename $L_WAR_PATH`"
  echo "$p"
}

function remote_bin_path() {
  local p="${PREFIX%/}/$VER/bin/$1"
  echo "$p"
}

function is_file_exist() {
  local p="$1"
  local w="$2"
  local lr="R"
  local t=

  echo -e "? check [$p] is exist ..."
  case "$w" in
    ssh)
      t=`ssh $SSH_USER@$SSH_HOST test -f $p &>/dev/null; echo $?`
      ;;
    docker)
      
      ;;
    *)
      t=`test -f $p &>/dev/null; echo $?`
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

function control_tomcat() {
  local cmd="$1"
  local w="$2"
  local tc=
  local t=

  echo -e "+ control Tomcat =>[$cmd] ..."
  case "$w" in
    ssh)
      tc="`remote_bin_path $TC_SH`"
      is_samed_file "`local_bin_path $TC_SH`" "$tc" "$w"
      if [ 0 -ne $? ]; then
        transport_file "`local_bin_path $TC_SH`" "$tc" "$w"
        t=$?
        [ 0 -eq $t ] || return $t
      fi
      
      ssh $SSH_USER@$SSH_HOST $tc $cmd               \
          --prefix=$PREFIX                           \
          --tomcat-version=$VER                      \
          --start-port=$START_PORT                   \
          --stop-port=$STOP_PORT                     \
          ${TC_OPTS}          
      t=$?
      ;;
    docker)
      echo "docker"
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

	#if [ 0 -eq $HAS_DOCKER ]; then
	#	docker cp $TD_CTRL_SH $DOCKER_CONTAINER:$R_TD_CTRL_SH
	#	docker exec $DOCKER_CONTAINER chown $DOCKER_USER:$DOCKER_USER $R_TD_CTRL_SH
	#	case $PLATFORM in
	#		MSYS_NT*)
	#			./$TD_CTRL_BAT "$1"
	#			;;
	#		*)
	#			docker exec -u $DOCKER_USER $DOCKER_CONTAINER $R_TD_CTRL_SH $1
	#			;;
	#	esac
	#elif [ 0 -eq $HAS_SSH ]; then
	#	ssh $SSH_USER@$SSH_HOST "$TC_SH_ENV bash $OPT_RUN/bin/$TC_SH $1"
	#else

                
	#fi
}

function is_samed_file() {
  local lwp="$1"
  local rwp="$2"
  local w="$3"

  echo -e "? L[$lwp] samed with R[$rwp] ..."
  if [ ! -f "$lwp" ]; then
    echo -e "! L[$1] does not exist."
    return 1
  fi

  local lwh="`sha1sum $lwp | cut -d' ' -f1`"
  local rwh="`test -f "$rwp" && sha1sum "$rwp" | cut -d' ' -f1`"

  case "$w" in
    ssh)
		  rwh=`ssh $SSH_USER@$SSH_HOST "test -f $rwp && sha1sum $rwp | cut -d' ' -f1"`
      ;;
    docker)
		  case "$PLATFORM" in
			  MSYS_NT*)
				  rwh=`./$TD_SHA1SUM_BAT`
				  ;;
			  *)
				  rwh=`docker exec -u $DOCKER_USER $DOCKER_CONTAINER $R_TD_SHA1SUM_SH`
				  ;;
		  esac       
      ;;
  esac

  if [ "$lwh" = "$rwh" ]; then
    echo -e "# L[$lwp] samed with R[$rwp]  =true"
    return 0
  else
    echo -e "! L[$lwp] samed with R[$rwp]  =false"
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
    echo -e "\t ! L[$BUILD_DIR] does not exists."
    return 1
  fi

  if [ ! -x "$cmd" ]; then
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
	  	scp $lp $SSH_USER@$SSH_HOST:$rp
      t=$?
      ;;
    docker)
      
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
    
	#if [ 0 -eq $HAS_DOCKER ]; then
	#	case $PLATFORM in
	#		MSYS_NT*)
	#			./$TD_RM_BAT
	#			;;
	#		*)
	#			docker exec -u $DOCKER_USER $DOCKER_CONTAINER \
	#				rm -rf ${WAR_DIR}${WAR_NAME} $R_WAR_FILE
	#			;;
	#	esac
  #
	#	docker cp $L_WAR_FILE $DOCKER_CONTAINER:$R_WAR_FILE 
	#	docker exec $DOCKER_CONTAINER chown $DOCKER_USER:$DOCK<ER_USER $R_WAR_FILE
	#	#docker_chown $R_WAR_FILE
  #
	#elif [ 0 -eq $HAS_SSH ]; then
	#	ssh $SSH_USER@$SSH_HOST \
	#		"$TC_SH_ENV rm -rf ${WAR_DIR}${WAR_NAME} $R_WAR_FILE"
	#	scp $L_WAR_FILE $SSH_USER@$SSH_HOST:$R_WAR_FILE
	#else
	#	rm -rf ${WAR_DIR}${WAR_NAME} $R_WAR_FILE	
	#	cp $L_WAR_FILE $R_WAR_FILE
	#fi
}

control_mark() {
  case "$TO_WHERE" in
    ssh)
		  echo -n "S[$SSH_USER@$SSH_HOST]"
      ;;
    docker)
		  echo -n "D[$DOCKER_USER@$DOCKER_CONTAINER]"
      ;;
    *)
		  echo -n "L[$PREFIX]"
      ;;
  esac
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
      echo -e "! missing --build-* options."
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

    R_WAR_PATH="`remote_war_path`"
    is_samed_file "$L_WAR_PATH" "$R_WAR_PATH" "${TO_WHERE[$TW_IDX]}"
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
    control_tomcat stop "${TO_WHERE[$TW_IDX]}"
    exit $?
    ;;
  check-env)
    control_tomcat check-env "${TO_WHERE[$TW_IDX]}"
    exit $?
    ;;
  check-pid)
    control_tomcat check-pid "${TO_WHERE[$TW_IDX]}"
    exit $?
    ;;
  *)
    echo "$0: error: invalid command \"$command\""
		usage
    exit 1    
    ;;
esac
