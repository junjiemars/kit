#!/bin/bash
#------------------------------------------------
# target: tiny web server
# author: junjiemars@gmail.com
#------------------------------------------------

VERSION="0.1.1"

PLATFORM="`uname -s 2>/dev/null`"

HTTP_PORT=${HTTP_PORT:-8080}
HTTP_VER=${HTTP_VER:-1.1}


function check_nc() {
	hash nc &>/dev/null
}

function nc_cmd() {
	case "${PLATFORM}" in
		Darwin)
			echo "nc -l"
			;;
		*)
			echo "nc -l -p"
		;;
	esac
}

function check_port() {
	[[ $1 =~ ^\+?[0-9]+$ ]]
}


function usage() {
  echo -e "Usage: $(basename $0) [OPTIONS]"
  echo -e "       $(basename $0) [ --help | --version ]\n"
  echo -e "Options:"
  echo -e "  --help\t\t\tPrint usage"
  echo -e "  --version\t\t\tPrint version information and quit\n"
  echo -e "  --http-port\t\t\thttp listen port"
  echo -e "  --http-version\t\thttp version\n"
  echo -e "A tiny-handy web server.\n"
}

for option
do
  opt="$opt `echo $option | sed -e \"s/\(--[^=]*=\)\(.* .*\)/\1'\2'/\"`"
  
  case "$option" in
    -*=*) value=`echo "$option" | sed -e 's/[-_a-zA-Z0-9]*=//'` ;;
    *) value="" ;;
  esac
  
  case "$option" in
    --help)                  				help=yes                   				 ;;
    --version)               				version=yes                				 ;;

    --http-port=*)       				    http_port="$value"    	  				 ;;
		--http-version=*)               http_ver="$value"                  ;;
   
    *)
			echo "$0: error: invalid option \"$option\""
			exit 1
		;;

  esac
done


if [ "yes" = "$help" ]; then
	usage
	exit 0
fi

if [ "yes" = "$version" ]; then
	echo "$VERSION"
	exit 0
fi


if ! `check_nc`; then
	echo -e "! nc command no found"	
	exit 1
fi

if [ -n "$http_port" ]; then
	if ! `check_port $http_port`; then
		echo -e "! --http-port=$http_port  =invalid"
		exit 1
	fi
	HTTP_PORT="$http_port"
fi


function do_listen() {
	local nc_cmd=`nc_cmd`
	
	trap "exit" INT
	while :
		do
			echo -e "HTTP/${HTTP_VER} 200 OK\n\n $(date)" | $nc_cmd $HTTP_PORT
		done
}

do_listen
