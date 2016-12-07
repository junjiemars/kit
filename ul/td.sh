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
VER=${VER:-"8.5.4"}
START_PORT=${START_PORT:-8080}
STOP_PORT=${STOP_PORT:-8005}
JPDA_PORT=${JPDA_PORT:-8000}
JAVA_OPTS="${JAVA_OPTS}"
TC_SH=${TC_SH:-"tc.sh"}
TC_SH_ENV=${TC_SH_ENV:-"PREFIX=$PREFIX VER=$VER START_PORT=$START_PORT STOP_PORT=$STOP_PORT JPDA_PORT=$JPDA_PORT JAVA_OPTS=$JAVA_OPTS"}

# ssh 
HAS_SSH=${HAS_SSH:-1}
SSH_USER=${SSH_USER:-}
SSH_HOST=${SSH_HOST:-}

# docker
HAS_DOCKER=${HAS_DOCKER:-1}
DOCKER_CONTAINER=${DOCKER_CONTAINER:-"java-dev"}
DOCKER_USER=${DOCKER_USER:-"u"}
DOCKER_TC_SH=${DOCKER_TC_SH:-"${OPT_RUN}/bin/$TC_SH"}

# war 
BUILD=${BUILD:-1}
BUILD_OPTS=${BUILD_OPTS:-}
BUILD_DIR=${BUILD_DIR:-}
BUILD_LOG=${BUILD_LOG:-"td-build.log"}
WAR_TARGET=${WAR_TARGET:-"-Dwar.target=local"}
WAR_TASK=${WAR_TASK:-}
WAR_DIR="${PREFIX}/${VER}/webapps/"
WAR_NAME=${WAR_NAME:-}
R_WAR_FILE="${WAR_DIR}${WAR_NAME}.war"
L_WAR_FILE="${BUILD_DIR%/}/${WAR_NAME}.war"

# platform
TD_CTRL_BAT="td-ctrl.bat"
TD_CTRL_SH="${TD_CTRL_BAT%.*}.sh"
TD_SHA1SUM_BAT="td-sha1sum.bat"
TD_SHA1SUM_SH="${TD_SHA1SUM_BAT%.*}.sh"
TD_RM_BAT="td-rm.bat"
R_TD_CTRL_SH="$OPT_RUN/bin/$TD_CTRL_SH"
R_TD_SHA1SUM_SH="$OPT_RUN/bin/$TD_SHA1SUM_SH"


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
	if [ 0 -eq $HAS_DOCKER ]; then
		docker cp $TD_CTRL_SH $DOCKER_CONTAINER:$R_TD_CTRL_SH
		docker exec $DOCKER_CONTAINER chown $DOCKER_USER:$DOCKER_USER $R_TD_CTRL_SH
		case $PLATFORM in
			MSYS_NT*)
				./$TD_CTRL_BAT "$1"
				;;
			*)
				docker exec -u $DOCKER_USER $DOCKER_CONTAINER $R_TD_CTRL_SH $1
				;;
		esac
	elif [ 0 -eq $HAS_SSH ]; then
		ssh $SSH_USER@$SSH_HOST "$TC_SH_ENV bash $OPT_RUN/bin/$TC_SH $1"
	else
		 PREFIX="$PREFIX" \
		 VER="$VER" \
		 START_PORT=$START_PORT \
		 STOP_PORT=$STOP_PORT \
		 JPDA_PORT=$JPDA_PORT \
		 JAVA_OPTS="$JAVA_OPTS" \
		 ./$TC_SH $1
	fi
}

is_same_war() {
	local _r=
	local _l=`test -f $L_WAR_FILE && \
		sha1sum $L_WAR_FILE | cut -d' ' -f1`
	if [ 0 -eq $HAS_DOCKER ]; then
		docker cp $TD_SHA1SUM_SH $DOCKER_CONTAINER:$R_TD_SHA1SUM_SH
		case $PLATFORM in
			MSYS_NT*)
				_r=`./$TD_SHA1SUM_BAT`
				;;
			*)
				_r=`docker exec -u $DOCKER_USER $DOCKER_CONTAINER $R_TD_SHA1SUM_SH`
				;;
		esac 
	elif [ 0 -eq $HAS_SSH ]; then
		_r=`ssh $SSH_USER@$SSH_HOST \
			"test -f $R_WAR_FILE && sha1sum $R_WAR_FILE | cut -d' ' -f1"`
	else
		_r=`test -f $R_WAR_FILE && sha1sum $R_WAR_FILE | cut -d' ' -f1`
	fi

	[ -n "$_l" ] && [ "$_l" = "$_r" ]
}

build_war() {
	if [ 0 -eq $BUILD ]; then
		JAVA_OPTS="${WAR_TARGET}" \
							 ./gradlew ${BUILD_OPTS} ${WAR_TASK} &> $BUILD_LOG
	fi
}

transport_war() {
	if [ 0 -eq $HAS_DOCKER ]; then
		case $PLATFORM in
			MSYS_NT*)
				./$TD_RM_BAT
				;;
			*)
				docker exec -u $DOCKER_USER $DOCKER_CONTAINER \
					rm -rf ${WAR_DIR}${WAR_NAME} $R_WAR_FILE
				;;
		esac

		docker cp $L_WAR_FILE $DOCKER_CONTAINER:$R_WAR_FILE 
		docker exec $DOCKER_CONTAINER chown $DOCKER_USER:$DOCKER_USER $R_WAR_FILE
		#docker_chown $R_WAR_FILE

	elif [ 0 -eq $HAS_SSH ]; then
		ssh $SSH_USER@$SSH_HOST \
			"$TC_SH_ENV rm -rf ${WAR_DIR}${WAR_NAME} $R_WAR_FILE"
		scp $L_WAR_FILE $SSH_USER@$SSH_HOST:$R_WAR_FILE
	else
		rm -rf ${WAR_DIR}${WAR_NAME} $R_WAR_FILE	
		cp $L_WAR_FILE $R_WAR_FILE
	fi
}

control_mark() {
	if [ 0 -eq $HAS_SSH ]; then
		echo -n "S[$SSH_USER@$SSH_HOST]"
	elif [ 0 -eq $HAS_DOCKER ]; then
		echo -n "D[$DOCKER_USER@$DOCKER_CONTAINER]"
	else
		echo -n "L[$PREFIX]"
	fi
}


case "$@" in
	stop)
		echo -n "# stop `control_mark` ..."	
		control_tomcat stop
		exit 0
		;;
	*)
		;;
esac


echo -n "# building the L[$L_WAR_FILE] ..."
if `build_war`; then
	echo "ok"
else
	echo "failed, panic!"
	exit 1
fi

echo -n "# checking platform scripts ..."
if `gen_platform_sh`; then
	echo "ok"
else
	echo "failed, panic!"
	exit 1
fi

echo -n "# checking the L/R wars ..."
if `is_same_war`; then
	echo "ok, skip process."
else
	echo "diffed"

		
	echo -n "# stop `control_mark` ..."	
	control_tomcat stop
	

	echo "---------------------------------"
	echo -n "# transport L[$L_WAR_FILE] to `control_mark`|R[$R_WAR_FILE] ..."
	if `transport_war`; then
		echo "ok"
	else
		echo "failed, panic!"
	fi
fi


echo -n "# start `control_mark` ..."	
control_tomcat debug 
