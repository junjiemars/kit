#!/bin/bash
#------------------------------------------------
# target: make Idea's settings.jar
# author: junjiemars@gmail.com
#------------------------------------------------

PREFIX=
JAR_NAME="${JAR_NAME:-settings.zip}"

function set_kit_prefix() {
  local p="$HOME/.config/JetBrains"
  local d=
  
  if [ -d "$p" ]; then
    d="`find $HOME/.config/JetBrains -maxdepth 1 -type d | sort -r | head -n1`"
  else
    d="`pwd`"
  fi
  echo "${d}/$JAR_NAME"
}

function set_os_prefix() {
	local p="$1"
  local d=""
	local os=`uname -s 2>/dev/null`

  if [ -z "$p" ]; then
    p="`pwd`"
  fi

	case "$os" in
		MSYS_NT*|MINGW*)
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
  echo -e "PREFIX=${PREFIX}/${JAR_NAME}\n"
  echo -e "Commands:"
  echo -e "\t-x=|--extract=<where>\t\teXtract to <where> from <PREFIX>"
  echo -e "\t-a=|--archive=<where>\t\tarchive to <PREFIX> from <where>"
  echo -e "\t-l=|--list=<where>\t\tlist the content of <PREFIX>"
}

PREFIX="$(set_kit_prefix)"
KIT_WHERE="${@#*=}"

case "$@" in
	-x=*|--extract=*)
		KIT_WHERE="${@#*=}"
		if [ ! -d "$KIT_WHERE" ]; then
			usage
			exit 1
		else
			KIT_WHERE=$(set_os_prefix "$KIT_WHERE")
			[ -d "$KIT_WHERE" ] || mkdir -p "$KIT_WHERE"; 
			echo "extracting [${PREFIX}] to [$KIT_WHERE] ..."
			cd "$KIT_WHERE" ; jar xvf "$PREFIX"
		fi
		;;
	-a=*|--archive=*)
		KIT_WHERE="${@#*=}"
		if [ ! -d "$KIT_WHERE" ]; then
			usage
			exit 1
		else
			KIT_WHERE=$(set_os_prefix "$KIT_WHERE")
			echo "archiving [${KIT_WHERE}] to [${PREFIX}] ..."
			jar cvfM "$PREFIX" -C "$KIT_WHERE" .
		fi
		;;
	-l=*|--list=*)
		KIT_WHERE="${@#*=}"
    if [ ! -d "$KIT_WHERE" ]; then
		  KIT_WHERE="`eval echo "${PREFIX}"`"
    else
      KIT_WHERE="${KIT_WHERE%/}/$JAR_NAME"
		fi
		echo "listing [$KIT_WHERE] ..."
		jar tf "$KIT_WHERE"
		;;
	-h|--help|*)
		usage
		exit 1
		;;
esac

