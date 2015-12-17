#!/bin/bash
#------------------------------------------------
# wbd.sh:	web-deployment script
# author: 	junjiemars@gmail.com
# configure > stop > deploy > run web container
#------------------------------------------------
#echo "OPTIND starts at $OPTIND"
VERBOSE=0
CONTAINER=${CONTAINER:-"tomcat"}
WEB_ROOT=${WEB_ROOT:-"./"}
WAR_PATH=${WAR_PATH:-"./"}
UP_PORT=${UP_PORT:-8080}
DOWN_PORT=${DOWN_PORT:-8005}
AJP_PORT=${CONNECTOR_PORT:-8009}
UP_INCR=${UP_INCR:-101}
DOWN_INCR=${DOWN_INCR:-100}
NODE_SN=${NODE_SN:-0}
TIMEOUT=${TIMEOUT:-5}
GO=${GO:-0}

_usage_() {
  echo "usage: $(basename $0) [OPTION]..."
  echo -e "\t-h help"
  echo -e "\t-c type of container, default:tomcat"
  echo -e "\t-t target root dir of container"
  echo -e "\t-w the path of deploying war"
  echo -e "\t-p default http port:8080"
  echo -e "\t-s default shutdown port:8005"
  echo -e "\t-n node number base on zero of cluster?"
  echo -e "\t-i increment of cluster http port"
  echo -e "\t-k increment of cluster shutdown port"
  echo -e "\t-g go, 0:shutdown >0:startup"
  echo -e "\t-v verbose"
}

_out_() {
  if [[ $VERBOSE -gt 0 ]]; then
    echo -e "$@"
  fi
}

_out_options_() {
  _out_ "OPTIONS:"
  _out_ "\t[-c]: $CONTAINER"
  _out_ "\t[-t]: $WEB_ROOT"
  _out_ "\t[-w]: $WAR_PATH"
  _out_ "\t[-p]: $UP_PORT"
  _out_ "\t[-s]: $DOWN_PORT"
  _out_ "\t[-n]: $NODE_SN"
  _out_ "\t[-i]: $UP_INCR"
  _out_ "\t[-i]: $DOWN_INCR"
  _out_ "\t[-g]: $GO"
}

_sha1_() {
  echo `sha1sum $1|cut -d" " -f1`
}

_is_listening_() {
  local p_=$1
  netstat -tln | grep ${p_} 2>&1 1>/dev/null
  echo $?
}

_get_pid_() {
  local f_=$1
  if [[ -f ${f_} ]]; then
    echo $(cat ${f_})
  else
    echo 0
  fi
}

_remove_dir_() {
  local d_=$1
  if [[ -d ${d_} ]]; then
    rm -rf ${d_} 2>&1 1>/dev/null
    echo $?
  else
    echo 1
  fi
}

_copy_file_() {
  local s_=$1
  local d_=$2
  cp ${s_} ${d_} 2>&1 1>/dev/null
  echo $?
}

_go_tomcat_() {
  local t_=$1
  local p_=$2
  local s_=$3
  local a_=$4
  local w_=$5
  local g_=$6

  if [[ ! -f "${t_}/bin/startup.sh" ]]; then
    _out_ "# skip go, web-root:[${t_}] is incorrect"
    return
  fi
  
  export CATALINA_BASE=${t_}
  export JAVA_OPTS=$(echo -e "$JAVA_OPTS \
    -Dhttp.port=${p_} \
    -Dshutdown.port=${s_} \
    -Dajp.port=${a_}" \
    |tr -s ' ')
  export CATALINA_PID=${CATALINA_BASE}/pid

  if [[ 0 -eq $(_is_listening_ ${p_}) ]]; then
    _out_ "# shutdown ${p_}|${s_} [${CATALINA_BASE}]..."
    _out_ $(${CATALINA_BASE}/bin/shutdown.sh) \
      | sed -r 's/Using /\n% using /g'
    sleep ${TIMEOUT}

    local pid_=$(_get_pid_ ${CATALINA_PID})
    if [[ ${pid_} -gt 0 ]]; then
      _out_ "# try to kill pid:[${pid_}] ..."
      kill -15 ${pid_}
      sleep ${TIMEOUT}
    fi

    if [ ! -z $w_ ] && [[ -f $w_ ]]; then
      local b_=$(basename $w_)
      local d_="${CATALINA_BASE}/webapps/"${b_%.*}
      
      if [[ -d ${d_} ]]; then
	_out_ "# remove web-app:[${d_}] ..."
	if [[ 0 -ne $(_remove_dir_ ${d_}) ]]; then
	  _out_ "! remove web-app:[${d_}] failed"
	fi
	sleep ${TIMEOUT}
      fi
    fi
  fi

  if [ ! -z ${w_} ] && [[ -f ${w_} ]]; then
    local f_="${CATALINA_BASE}/webapps/$(basename ${w_})"
    if [[ -f ${f_} ]] && \
      [ $(_sha1_ ${w_}) = $(_sha1_ ${f_}) ]; then
      _out_ "# skip copy war:[${w_}] sha1:[$(_sha1_ ${f_})]"
    else
      if [[ 0 -ne $(_copy_file_ ${w_} ${f_}) ]]; then
	_out_ "! copy war-file from [$w_]-> [$f_] failed"
	return
      fi
    fi
  fi	

  if [[ ${g_} -gt 0 ]]; then
    _out_ "# startup tomcat:${p_}|${s_} [${CATALINA_BASE}]..."
    _out_ $(${CATALINA_BASE}/bin/startup.sh) \
      | sed -r 's/Using /\n% using /g'
  fi
}

_go_jetty_() {
  _out_ "! unimplemented now"
}

_go_weblogic_() {
  _out_ "! unimplemented now"
}

_go_() {
  local c_=$1
  local t_=$2
  local n_=$3
  local p_=$4
  local s_=$5
  local a_=$6
  local w_=$7
  local g_=$8

  case ${c_} in
    tomcat) 
      if [[ 1 -gt ${n_} ]]; then
	_go_tomcat_ ${t_} ${p_} ${s_} ${a_} ${w_} ${g_}
      else
	local f_=$((${p_} + ${UP_INCR}))
	local l_=$((${p_} + ${UP_INCR} * $((${n_} + 1))))
	local i_=0
	
	for p in `seq ${f_} ${UP_INCR} ${l_}`; do
	  local b_="${t_}/n${i_}/"
	  local s1_=$((${s_} + $DOWN_INCR * ${i_}))
          local a1_=$((${a_} + $DOWN_INCR * ${i_}))
	  (_go_tomcat_ ${b_} ${p} ${s1_} ${a1_} ${w_} ${g_})
	  let i_++
	done
      fi;;
    jetty) _go_jetty_;;
    weblogic) _go_weblogic_;;
    *)  _out_ "! unsupported ${c_} now";;
  esac
}

if [[ $# -lt 1 ]]; then
  _usage_
fi
	
while getopts "hc:t:w:s:p:n:i:k:g:v" optname; do
  case ".$optname" in
    ".c") eval CONTAINER="$OPTARG";;
    ".t") eval WEB_ROOT="${OPTARG%/}";;
    ".w") eval WAR_PATH="$OPTARG";;
    ".s") eval DOWN_PORT="$OPTARG";;
    ".p") eval UP_PORT="$OPTARG";;
    ".n") eval NODE_SN="$OPTARG";;
    ".i") eval UP_INCR="$OPTARG";;
    ".k") eval DOWN_INCR="$OPTARG";;
    ".g") eval GO="$OPTARG";;
    ".v") let VERBOSE++;;
    ".h") _usage_;;
    ".?") _usage_;;
    ".:") _usage_;;
  esac
done

 _out_options_

if [[ ! -d $WEB_ROOT ]]; then
  _out_ "#[-t:$WEB_ROOT] is invalid directory, exiting..."
  exit $?
fi

_go_ \
  $CONTAINER \
  $WEB_ROOT \
  $NODE_SN \
  $UP_PORT \
  $DOWN_PORT \
  $AJP_PORT \
  $WAR_PATH \
  $GO

