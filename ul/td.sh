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

VER=${VER:-"8.5.8"}

TC_PATH=("./tc.sh" "${OPT_RUN%/}/bin/tc.sh")
TC_OPTS=

STOP_TIMEOUT="${STOP_TIMEOUT:3}"
START_PORT="${START_PORT:-8080}"
STOP_PORT="${STOP_PORT:-8005}"

TC_SH="${TC_SH:-tc.sh}"
TO_WHERE=("local" "ssh" "docker")

L_WAR_PATH="${L_WAR_PATH}"
R_WAR_PATH="${R_WAR_PATH}"

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
  echo -e "  --tomcat-version\t\ttomcat version, default is $VER"
  echo -e "  --java-options\t\tjava options, JAVA_OPTS"
  echo -e "  --tc-path\t\ttc.sh path"
  echo -e "  --tc-options\t\ttc.sh options"
  echo -e "  --start-port\t\t\ttomcat start port, default is $START_PORT"
  echo -e "  --stop-port\t\t\ttomcat stop port, default is $STOP_PORT"
  echo -e "  --jpda-port\t\t\ttomcat debug port, default is $JPDA_PORT"
  echo -e "  --war-path\t\t\t\where war file exists"
  echo -e "  --where\t\twhere to deploy, ${TO_WHERE[@]}\n"
  echo -e "A tiny-handy console for tomcat.\n"
  echo -e "Commands:"
  echo -e "  build\t\t\t\t\tbuild war which will be deployed"
  echo -e "  start\t\t\t\t\tstart a tomcat instance"
  echo -e "  stop\t\t\t\t\tstop a tomcat instance"
  echo -e "  debug\t\t\t\t\tstart a tomcat instance in debug mode"
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


control_tomcat() {
  local cmd="$1"
  local tc=
  
  for s in "${TC_PATH[@]}"; do
    if [ -f "$s" ]; then
      tc="$s"
      break
    fi
  done
  if [ -z "$tc" ]; then
    return 1
  fi

  case "$TO_WHERE" in
    ssh)
      echo "ssh"
      ;;
    docker)
      echo "docker"
      ;;
    *)
     $tc $cmd                                       \
         --prefix=$PREFIX                           \
         --tomcat-version=$VER                      \
         --start-port=$START_PORT                   \
         --stop-port=$STOP_PORT                     \
         ${TC_OPTS}
      ;;
  esac

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

function is_same_war() {
  local lwp="$1"
  local rwp="$2"

  echo -e "? L[$lwp] samed with R[$rwp] ..."
  if [ ! -f "$lwp" ]; then
    echo -e "! L[$1] does not exist."
    return 1
  fi

  local lwh="`sha1sum $lwp | cut -d' ' -f1`"
  local rwh="`test -f "$rwp" && sha1sum "$rwp" | cut -d' ' -f1`"

  case "$TO_WHERE" in
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

  if [ "$lwh" != "$rwh" ]; then
    echo -e "! L[$lwp] samed with R[$rwp] =false"
    return 1
  fi
  return 0
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
    echo -e "! dir[$BUILD_DIR] does not exists."
    return 1
  fi

  if [ ! -x "$cmd" ]; then
    return 1
  fi

  cd "$BUILD_DIR" && "$cmd" ${BUILD_OPTS}
  if [ 0 -ne $? ]; then
    echo -e "! build L[$lwp}] =failed"
    return $?
  fi
  return 0
}

function transport_war() {
  case "$TO_WHERE" in
    ssh)
	    ssh $SSH_USER@$SSH_HOST \
	  		  "$TC_SH_ENV rm -rf ${WAR_DIR}${WAR_NAME} $R_WAR_FILE"
	  	scp $L_WAR_FILE $SSH_USER@$SSH_HOST:$R_WAR_FILE
      ;;
    docker)
      
      ;;
    *)
	    rm -rf ${WAR_DIR}${WAR_NAME} $R_WAR_FILE	
	    cp $L_WAR_FILE $R_WAR_FILE
      ;;
  esac
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
    --tc-path=*)             tc_path="$value"           ;;
    --tc-options=*)          tc_opts="$value"		        ;;

    --java-options=*)        java_opts="$value"		      ;;
    --where=*)               where="$value"		          ;;

    --local-war-path=*)      L_WAR_PATH="$value"	      ;;
    --remote-war-path=*)     R_WAR_PATH="$value"	      ;;

    --build-dir=*)           BUILD_DIR="$value"	        ;;
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

if [ -n "$tc_path" ]; then
  if [ -x "$tc_path" ]; then
    TC_PATH+="$tc_path "
    exit 0
  fi
  exit 1
fi

if [ -n "$tc_opts" ]; then
  TC_OPTS="${TC_OPTS:+$TC_OPTS }${tc_opts}"
fi

if [ -n "$java_opts" ]; then
  JAVA_OPTS="${JAVA_OPTS:+$JAVA_OPTS }${java_opts}"
fi

if [ -n "$build_cmd" ]; then
  BUILD_CMD="$build_cmd"
fi



#export_pid_var
export_java_opts

command="`echo $command | tr '[:upper:]' '[:lower:]'`"
case "$command" in
  build)
    build_war "$L_WAR_PATH"
    exit $?
    ;;
  start)
    #echo -e "+ transport L[$L_WAR_PATH] to `control_mark`|R[$R_WAR_PATH] ..."
    is_same_war "$L_WAR_PATH" "$R_WAR_PATH"
    if [ 0 -eq $? ]; then
      build_war "$L_WAR_PATH"
      [ 0 -eq $? ] || exit $?
    fi
    #transport_war
    #[ 0 -eq $? ] || exit 1
    #control_tomcat start
    exit $?
    ;;
  stop)
    echo -e "+ stop control_mark ..."	
    control_tomcat stop
    exit $?
    ;;
  debug)
    export JPDA_PORT="${JPDA_PORT:8000}"
    control_tomcat debug
    exit $?
    ;;
  *)
    echo "$0: error: invalid command \"$command\""
		usage
    exit 1    
    ;;
esac

#case "$@" in
#	stop)
#		echo -n "# stop `control_mark` ..."	
#		control_tomcat stop
#		exit 0
#		;;
#	*)
#		;;
#esac
#
#
#echo -n "# building the L[$L_WAR_FILE] ..."
#if `build_war`; then
#	echo "ok"
#else
#	echo "failed, panic!"
#	exit 1
#fi
#
#echo -n "# checking platform scripts ..."
#if `gen_platform_sh`; then
#	echo "ok"
#else
#	echo "failed, panic!"
#	exit 1
#fi
#
#echo -n "# checking the L/R wars ..."
#if `is_same_war`; then
#	echo "ok, skip process."
#else
#	echo "diffed"
#
#		
#	echo -n "# stop `control_mark` ..."	
#	control_tomcat stop
#	
#
#	echo "---------------------------------"
#	echo -n "# transport L[$L_WAR_FILE] to `control_mark`|R[$R_WAR_FILE] ..."
#	if `transport_war`; then
#		echo "ok"
#	else
#		echo "failed, panic!"
#	fi
#fi
#
#
#echo -n "# start `control_mark` ..."	
#control_tomcat debug 
