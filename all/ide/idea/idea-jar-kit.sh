#!/bin/bash
#------------------------------------------------
# target: make Idea's settings.jar
# author: junjiemars@gmail.com
#------------------------------------------------

PREFIX=${PREFIX:-"`pwd`"}

function set_os_prefix() {
	local p="$1"	
	local os=`uname -s 2>/dev/null`

	[ -z "$p" ] && p="$PREFIX"

	case "$os" in
		MSYS_NT*)
			p="${p%/}/win"
			;;
		Darwin)
			p="${p%/}/darwin"
			;;
		Linux)
			p="${p%/}/linux"
			;;
	esac

	echo "$p"
}

function usage() {
  echo -e "Usage: $(basename $0) COMMAND [arg...]"
  echo -e "       $(basename $0) [ -h | --help | -v | --version ]\n"
  echo -e "Options:"
  echo -e "  -h, --help\t\tPrint usage"
  echo -e "A Idea settings extract/archive kit.\n"
  echo -e "Commands:"
  echo -e "\t-x|--extract\t\teXtract <settings.jar> to <PREFIX|somewhere>"
  echo -e "\t-a|--archive\t\tarchive <settings> from git repo to <PREFIX|somewhere>"
}

case "$@" in
	-x*|--extract=*)
		if [ $# -lt 2 ]; then
			usage	
		else
			p=$(set_os_prefix "$3")
			[ -d "$p" ] || mkdir -p "$p"; 
			echo "extracting [$2] to \n\t$p ..."
			cd "$p" ; jar xvf "$2"
		fi
		;;
	-a*|--archive=*)
		if [ $# -lt 2 ]; then
			usage
		else
			p=$(set_os_prefix "$3")
			echo "archiving [$2] to \n\t[$p] ..."
			jar cvfM "${2%/}" -C "$p" .
		fi
		;;
	-h|--help|*)
		usage
		;;
esac

