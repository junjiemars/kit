#!/bin/bash
#------------------------------------------------
# target: tiny web server
# author: junjiemars@gmail.com
#------------------------------------------------


usage() {
  echo -e "Usage: $(basename $0) [OPTIONS]"
  echo -e "       $(basename $0) [ -h | --help | -v | --version ]\n"
  echo -e "Options:"
  echo -e "  -h, --help\t\tPrint usage"
  echo -e "  -p, --port\t\thttp listen port\n"
  echo -e "A tiny-handy web server.\n"
}

case ".$@" in
  .-p*|.--port*) 
		_port_=`echo $@ | sed -e 's/\(-p\|--port=\) *\([0-9][0-9]*\).*/\2/'`
		while true; do
			echo -e "HTTP/1.1 200 OK\n\n $(date)" | nc -l -p $_port_; done
		 ;;
  .-h|.--help|.*) 
		usage 
		;;
esac
