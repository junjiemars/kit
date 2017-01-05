#!/bin/bash
#------------------------------------------------
# target: tiny web server
# author: junjiemars@gmail.com
#------------------------------------------------

PLATFORM="`uname -s 2>/dev/null`"

usage() {
  echo -e "Usage: $(basename $0) [OPTIONS]"
  echo -e "       $(basename $0) [ -h | --help | -v | --version ]\n"
  echo -e "Options:"
  echo -e "  -h, --help\t\tPrint usage"
  echo -e "  -p, --port\t\thttp listen port\n"
  echo -e "A tiny-handy web server.\n"
}

nc_cmd() {
	local nc_listen="nc -l -p"
	case "${PLATFORM}" in
		Darwin)
			nc_listen="nc -l"
			;;
	esac
	echo "$nc_listen"
}

listen_port() {
	local port="$@"
	case "${PLATFORM}" in
		Darwin)
			echo "`echo $port | sed -E 's/(-p[ ]*|--port=)([0-9][0-9]*).*/\2/'`"
			;;
		*)
			echo "`echo $port | sed -e 's#\(-p[ ]*\|--port=\)\([0-9][0-9]*\).*#\2#'`"
			;;
	esac
}


case ".$@" in
  .-p*|.--port*) 
		nc=$(nc_cmd)
		port=$(listen_port "$@")
		trap "exit" INT
		while :
		do
			echo -e "HTTP/1.1 200 OK\n\n $(date)" | $nc $port 
		done
		;;
  .-h|.--help|.*) 
		usage 
		;;
esac
