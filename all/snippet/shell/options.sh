#!/bin/bash


HELP=
VERBOSE=
IPV6=${IPV6:-"-4"}
COMMAND=${COMMAND:-"CREATE"}
HOST=${HOST:-"localhost"}
PORT=${PORT:-"8080"}
CUR_USER=


usage() {
  echo -e "Usage: $(basename $0) [OPTIONS] [COMMANDS] [ARGUMENTS...]\n"

  echo -e "Options:"
  echo -e "  --help\t\tPrint this message"
  echo -e "  --verbose\t\tVerbose output"

  echo -e "Commands:"
  echo -e "  --op=create\t\tCreate issues"
  echo -e "  --op=meta\t\tQuery API's meta\n"

  echo -e "Arguments:"

  echo -e "  --host\t\tHost, IP or hostname, default is localhost"
  echo -e "  --port\t\Port number, default is 8080\n"
  echo -e "  --user\t\tLogin user, <username>:<passwd>, required"
}


for option
do
  opt="$opt `echo $option | sed -e \"s/\(--[^=]*=\)\(.* .*\)/\1'\2'/\"`"
  
  case "$option" in
    -*=*) value=`echo "$option" | sed -e 's/[-_a-zA-Z0-9]*=//'` ;;
    *) value="" ;;
  esac
  
  case "$option" in
    --help)                          HELP=YES                   ;;
    --verbose)                       VERBOSE="-v"               ;;
    
    --host=*)   	                   HOST="$value"     				  ;;
    --post=*)   	                   PORT="$value"     				  ;;

    --op=*) 	                   		 COMMAND="$value"      			;;
    --user=*)   	                   CUR_USER="$value"    			;;
    
    *)
      echo "$0 [error]: invalid option \"$option\"\n"
			usage
      exit 1
    ;;
  esac
done


if [ "YES" = "$HELP" -o 0 -eq $# ]; then
	usage
	exit 0
fi
