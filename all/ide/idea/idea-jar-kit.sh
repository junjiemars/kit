#!/bin/bash
#------------------------------------------------
# target: make Idea's settings.jar
# author: junjiemars@gmail.com
#------------------------------------------------

PREFIX=${PREFIX:-"`pwd`"}
JAR_NAME="settings.jar"

function set_os_prefix() {
	local p="$1"	
	local os=`uname -s 2>/dev/null`

	[ -z "$p" ] && p="`eval echo "$PREFIX"`"

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
  echo -e "  -h, --help\t\tPrint this message"
  echo -e "A Idea settings extract/archive kit.\n"
  echo -e "Commands:"
  echo -e "\t-x=|--extract=<where>\t\teXtract to <PREFIX> from <where> settings.jar"
  echo -e "\t-a=|--archive=<where>\t\tarchive from <PREFIX> to <where> settings.jar"
  echo -e "\t-l=|--list=<where>\t\tlist the content of settings.jar"
}

case "$@" in
	-x=*|--extract=*)
		KIT_EXTRACT="${@#*=}"
		if [ -z "$KIT_EXTRACT" ]; then
			usage	
			exit 1
		else
			shift
			p=$(set_os_prefix "$1")
			[ -d "$p" ] || mkdir -p "$p"; 
			KIT_EXTRACT="`eval echo "$KIT_EXTRACT"`"
			echo "extracting [${KIT_EXTRACT}] to [$p] ..."
			cd "$p" ; jar xvf "$KIT_EXTRACT"
		fi
		;;
	-a=*|--archive=*)
		KIT_ARCHIVE="${@#*=}"
		if [ -z "$KIT_ARCHIVE" ]; then
			usage
			exit 1
		else
			shift
			KIT_ARCHIVE="`eval echo "${KIT_ARCHIVE%/}/$JAR_NAME"`"
			p=$(set_os_prefix "$1")
			echo "archiving [$p] to [${KIT_ARCHIVE}] ..."
			jar cvfM "$KIT_ARCHIVE" -C "$p" .
		fi
		;;
	-l=*|--list=*)
		KIT_LIST="${@#*=}"
		if [ -z "$KIT_LIST}" ]; then
			usage
			exit 1
		else
			KIT_LIST="`eval echo "${KIT_LIST%/}/$JAR_NAME"`"
			echo "listing [$KIT_LIST] ..."
			jar tf "$KIT_LIST"
		fi
		;;
	-h|--help|*)
		usage
		exit 1
		;;
esac

