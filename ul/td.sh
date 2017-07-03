#!/bin/bash
#------------------------------------------------
# require: bash env, tc.sh
# target : tomcat deploy/debug tool
# author : junjiemars@gmail.com
#------------------------------------------------


# env 
PLATFORM=${PLATFORM:-`uname -s 2>/dev/null`}

L_OPT_RUN="${OPT_RUN:-/opt/run}"
L_PREFIX="${L_PREFIX:-${L_OPT_RUN%/}/www/tomcat}"
R_OPT_RUN="${OPT_RUN:-/opt/run}"
R_PREFIX="${R_PREFIX:-${R_OPT_RUN%/}/www/tomcat}"

VERSION="1.2.1"

JAVA_OPTS=
DEBUG=(${DEBUG:+$DEBUG} "no" "yes")

VER=${VER:-"8.5.8"}
TC_OPTS=
TC_SH="tc.sh"


LISTEN_ON=("localhost" "127.0.0.1" "0.0.0.0")
IP_VER=("4" "6")
STOP_TIMEOUT="${STOP_TIMEOUT:-5}"
START_PORT="${START_PORT:-8080}"
STOP_PORT="${STOP_PORT:-8005}"
JPDA_PORT="${JPDA_PORT:-8000}"

TO_WHERE=("local" "ssh" "docker")
TW_IDX=


L_WAR_PATH="${L_WAR_PATH}"
R_WAR_PATH=
R_TC_PATH=

BUILD=(${BUILD:+$BUILD} "no" "yes")
BUILD_CMD=("gradlew" "gradle" "ant" "mvn")
BUILD_DIR="${BUILD_DIR:-.}"
BUILD_OPTS="${BUILD_OPTS:-build}"


SSH_USER="${SSH_USER:-USER}"
SSH_HOST="${SSH_HOST}"

DOCKER_USER="${DOCKER_USER:-$USER}"
DOCKER_HOST="${DOCKER_HOST}"

TD_SHA1SUM_SH="td_sha1sum.sh"
TD_SHELL_BAT="td_shell.bat"


usage() {
  echo -e "Usage: $(basename $0) [OPTIONS] COMMAND [arg...]"
  echo -e "       $(basename $0) [ -h | --help | -v | --version ]\n"
  echo -e "Options:"
  echo -e "  --help\t\t\t\tPrint this message"
  echo -e "  --version\t\t\t\tPrint version information and quit"
  echo -e ""
  echo -e "  --local-prefix=\t\t\tlocal catalina prefix dir, L_PREFIX='${L_PREFIX}'"
  echo -e "  --remote-prefix=\t\t\tremote catalina prefix dir, R_PREFIX='${R_PREFIX}'"
  echo -e "  --java-options\t\t\tjava options, JAVA_OPTS='${JAVA_OPTS}'"
  echo -e "  --debug\t\t\t\tstart tomcat in debug mode, default is '${DEBUG}'"  
  echo -e ""
  echo -e "  --where=\t\t\t\twhere to deploy: `echo ${TO_WHERE[@]}|tr ' ' ','`, default is '$TO_WHERE'"  
  echo -e "  --local-war-path=\t\t\tthe local path of the war"
  echo -e "  --ssh-user=\t\t\t\tssh login user, default SSH_USER='${SSH_USER}'"
  echo -e "  --ssh-host=\t\t\t\twhich ssh host to login"
  echo -e "  --docker-user=\t\t\tdocker container user, default DOCKER_USER='${DOCKER_USER}'"
  echo -e "  --docker-host=\t\t\tdocker container name"
  echo -e ""
  echo -e "  --build\t\t\t\tforce to build, default is '${BUILD}'"
  echo -e "  --build-dir=\t\t\t\tbuilding in where, default is '${BUILD_DIR}'"
  echo -e "  --build-cmd=\t\t\t\twhich building tool to use, default BUILD_CMD='${BUILD_CMD}'"
  echo -e "  --build-options=\t\t\tbuilding options, default BUILD_OPTS='${BUILD_OPTS}'"
  echo -e ""
  echo -e "  --tomcat-version=\t\t\ttomcat version, default is '$VER'"
  echo -e "  --tc-options=\t\t\t\ttc.sh options"
  echo -e ""
  echo -e "  --listen-on=\t\t\t\tlisten on what address: `echo ${LISTEN_ON[@]}|tr ' ' ','`, etc., default is '$LISTEN_ON'"
  echo -e "  --ip-version=\t\t\t\tprefered IP version: `echo ${IP_VER[@]}|tr ' ' ','`"
  echo -e "  --stop-timeout=\t\t\tforce stop waiting most ${STOP_TIMEOUT} seconds"
  echo -e "  --start-port=\t\t\t\ttomcat start port, default START_PORT='$START_PORT'"
  echo -e "  --stop-port=\t\t\t\ttomcat stop port, default STOP_PORT='$STOP_PORT'"
  echo -e "  --jpda-port=\t\t\t\ttomcat debug port, default JPDA_PORT='$JPDA_PORT'"
  echo -e ""
  echo -e "A deploy & debug console for tomcat.\n"
  echo -e "Commands:"
  echo -e "  start\t\t\t\t\tstart a tomcat instance"
  echo -e "  stop\t\t\t\t\tstop a tomcat instance"
  echo -e "  build\t\t\t\t\tbuild war which will be deployed"
  echo -e "  check-console\t\t\t\tcheck [$(basename $0)'s console] runtime"
  echo -e "  check-pid\t\t\t\tcheck the pid of the tomcat instance"
  echo -e "  check-exist\t\t\t\tcheck existing of tomcat installation"
  echo -e "  make\t\t\t\t\tmake [$(basename $0)'s shell]"
}



export_java_opts() {
	local opts="`echo $@ | tr -s ' '`"
  export JAVA_OPTS="$opts"
}


function echo_opts() {
	local name="$1"
	local opts="${@:2}"
	echo "@|1[$name]:$opts"
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


function local_root_path() {
  local p="${L_PREFIX%/}"
  echo "$p"
}


function local_bin_path() {
  local bin="$1"
  local t=

  if [ -f "$bin" ]; then
    echo "${PWD%/}/$bin"
  else
    curl -qL -O$bin https://raw.githubusercontent.com/junjiemars/kit/master/ul/$bin
    t=$?
    [ 0 -eq $t ] || return $t

    chmod u+x "$bin"
    echo "${PWD%/}/$bin"
  fi
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


function check_exist() {
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
      dir_mk "`remote_ver_path`/bin" "$w"
      t=$?
      if [ 0 -ne $t ]; then
        echo -e "! check Console $wa[$VER]  =failed"
        return $t
      fi
      
      tc="`remote_bin_path $TC_SH`"
      transport_file "`local_bin_path $TC_SH`" "$tc" "$w"
      t=$?
      ;;
    docker)
      dir_mk "`remote_ver_path`/bin" "$w"
      t=$?
      if [ 0 -ne $t ]; then
        echo -e "! check Console $wa[$VER]  =failed"
        return $t
      fi
      
      tc="`remote_bin_path $TC_SH`"
      transport_file "`local_bin_path $TC_SH`" "$tc" "$w"
      t=$?

      gen_docker_sha1sum_sh
      let t=$t+$?
      ;;
    *)
      tc="`local_bin_path $TC_SH`"
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

  local lh="`sha1sum $lp | cut -d' ' -f1`"
  local rh=

  case "$w" in
    ssh)
		  rh=`ssh $(ssh_login_id) "test -f $rp && sha1sum $rp 2>/dev/null | cut -d' ' -f1"`
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
      rh="`test -f "$rp" && sha1sum "$rp" | cut -d' ' -f1`"
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
      echo -e "# mkdir $wa[$d]: in local  =skipped"
      t=0
      ;;
  esac

  if [ 0 -eq $t ]; then
    echo -e "+ mkdir $wa[$d]  =succeed"
  else
    echo -e "- mkdir $wa[$d]  =failed"
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
    echo -e "! build L[$lwp]: build command no found  =failed"
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
      ssh `ssh_login_id` rm -r "$rdw"
			t=$?
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
  local tc="`local_bin_path $TC_SH`"
  local t=

  echo -e "+ install Tomcat $wa[$VER] ..."

  if [ "${TO_WHERE[$TW_LOCAL]}" = "$w" ]; then
    control_tomcat install "$w"
    t=$?
    if [ 0 -ne $t ]; then
      echo -e "! install Tomcat $wa[$VER]  =failed"
    else
      echo -e "! install Tomcat $wa[$VER]  =failed"
    fi
    return $t
  fi

  local tgz="apache-tomcat-$VER.tar.gz"
  local ltgz=("`local_root_path`/$tgz" "/tmp/$tgz" "./$tgz")
  local rtgz="`remote_root_path`/$tgz"

  for f in "${ltgz[@]}"; do
    if [ -f "$f" ]; then
      ltgz="$f"
      break;
    fi
  done

  control_tomcat verify "${TO_WHERE[$TW_LOCAL]}"
  t=$?
  if [ 0 -ne $t ]; then
    $tc install                              \
        --download-only                      \
        --tomcat-version="$VER"              \
        --prefix="`dirname ${ltgz[0]}`"
    t=$?
    if [ 0 -ne $t ]; then
      echo -e "! install Tomcat $wa[$VER]  =failed"
      return $t
    fi
  fi

  transport_file "${ltgz[0]}" "$rtgz" "$w"
  file_eq "${ltgz[0]}" "$rtgz" "$w"
  t=$?
  if [ 0 -ne $t ]; then
     echo -e "! install Tomcat $wa[$VER]  =failed"
     return $t
  fi

  local ltgz_sha1="${ltgz[0]}.sha1"
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
  local opts="$3"
  local wa="`where_abbrev $w`"
  local tc=
  local t=

  echo -e "+ control Tomcat => $wa[$cmd] ..."
	echo_opts "JAVA_OPTS" "${JAVA_OPTS}"

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
					--java-options=\'"${JAVA_OPTS}"\'           
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
               --stop-timeout=$STOP_TIMEOUAT           \
							 --java-options=\"${JAVA_OPTS}\""           
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
							 --java-options="${JAVA_OPTS}"           
        t=$?
      fi
      ;;
    *)
      tc="`local_bin_path $TC_SH`"
      $tc $cmd                                       \
          --prefix=$L_PREFIX                         \
          --tomcat-version=$VER                      \
          --listen-on=$LISTEN_ON                     \
          --ip-version=$IP_VER                       \
          --start-port=$START_PORT                   \
          --stop-port=$STOP_PORT                     \
          --stop-timeout=$STOP_TIMEOUT               \
					--java-options="${JAVA_OPTS}"           
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


function make_td_shell() {
  local tds="td_$(basename $PWD)_shell.sh"
  local tdp="$(dirname $0)"
  local td="${tdp%/}/$(basename $0)"

  cat /dev/null > "$tds"
  cat << END > "$tds"
#!/bin/bash

##
## generated by https://raw.githubusercontent.com/junjiemars/kit/master/ul/td.sh make
##


function download_td_sh() {
  local bin="\$1"
  local t=

  if [ ! -f "\$bin" ]; then
    curl -qL -O\$bin "https://raw.githubusercontent.com/junjiemars/kit/master/ul/\$bin"
    t=\$?
    [ 0 -eq \$t ] || return \$t

    chmod u+x "\$bin"
  fi
  return 0
}

td="td.sh"
download_td_sh "\$td"

./\$td ${L_PREFIX:+--local-prefix=${L_PREFIX}} \\
	${R_PREFIX:+--remote-prefix=${R_PREFIX}} \\
	${VER:+--tomcat-version=${VER}} \\
	${L_WAR_PATH:+--local-war-path=${L_WAR_PATH}}	\\
	${LISTEN_ON:+--listen-on=${LISTEN_ON}} \\
	${IP_VER:+--ip-version=${IP_VER}} \\
	${SSH_USER:+--ssh-user=${SSH_USER}} \\
	${SSH_HOST:+--ssh-host=${SSH_HOST}} \\
	${DOCKER_USER:+--docker-user=${DOCKER_USER}} \\
	${DOCKER_HOST:+--docker-host=${DOCKER_HOST}} \\
	${BUILD_DIR:+--build-dir=${BUILD_DIR}} \\
	${BUILD_CMD:+--build-cmd=${BUILD_CMD}} \\
	${STOP_TIMEOUT:+--stop-timeout=${STOP_TIMEOUT}} \\
	${START_PORT:+--start-port=${START_PORT}} \\
	${STOP_PORT:+--stop-port=${STOP_PORT}} \\
	${JPDA_PORT:+--jpda-port=${JPDA_PORT}} \\
	"\$@"
END

  chmod u+x "${PWD%/}/$tds"
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

    --tomcat-version=*)      VER="$value"      			    ;;
    --tc-options=*)          tc_opts="$value"		        ;;

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

if [ -n "$l_prefix" ]; then
  L_PREFIX="$l_prefix"
fi

if [ -n "$r_prefix" ]; then
  R_PREFIX="$r_prefix"
fi

if [ -n "$tc_opts" ]; then
  TC_OPTS="${TC_OPTS:+$TC_OPTS }${tc_opts}"
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

echo_opts "java_opts" "${java_opts}"
export_java_opts "${java_opts}"
echo_opts "JAVA_OPTS" "${JAVA_OPTS}"

retval=0
command="`echo $command | tr '[:upper:]' '[:lower:]'`"
case "$command" in

  build)
    build_war "$L_WAR_PATH"
    ;;
  start)
    if [ -z "$L_WAR_PATH" ]; then
      echo -e "! missing --local-war-path=* options."
      usage
      exit 1
    fi
    
    if [ ! -f "$L_WAR_PATH" -o "yes" = "$BUILD" ]; then
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

    transport_war "$L_WAR_PATH" "${TO_WHERE[$TW_IDX]}"
    if [ "$DEBUG" = "yes" ]; then
      export JPDA_PORT="$JPDA_PORT"
      control_tomcat debug "${TO_WHERE[$TW_IDX]}"
    else
      control_tomcat start "${TO_WHERE[$TW_IDX]}"
    fi
    ;;
  stop)
    check_exist "${TO_WHERE[$TW_IDX]}"
    retval=$?
    [ 0 -eq $retval ] || exit $t
    control_tomcat stop "${TO_WHERE[$TW_IDX]}"
    ;;
  check-console)
    check_console "${TO_WHERE[$TW_IDX]}"
    ;;
  check-env)
    check_exist "${TO_WHERE[$TW_IDX]}"
    retval=$?
    [ 0 -eq $retval ] || exit $t
    control_tomcat check-env "${TO_WHERE[$TW_IDX]}"
    ;;
  check-pid)
    check_exist "${TO_WHERE[$TW_IDX]}"
    retval=$?
    [ 0 -eq $retval ] || exit $t
    control_tomcat check-pid "${TO_WHERE[$TW_IDX]}"
    ;;
  check-exist)
    check_exist "${TO_WHERE[$TW_IDX]}"
    ;;
  make)
    make_td_shell
    ;;
  *)
    echo "$0: error: invalid command \"$command\""
		usage
    ;;
esac
