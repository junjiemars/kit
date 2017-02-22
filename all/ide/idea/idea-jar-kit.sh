#!/bin/bash
#------------------------------------------------
# target: make Idea's settings.jar
# author: junjiemars@gmail.com
#------------------------------------------------

PREFIX=${PREFIX:-"`pwd`"}
PLATFORM=`uname -s 2>/dev/null`
R_DIR="`dirname $0`"
S_DIR="${R_DIR%/}/linux"
S_JAR=${S_JAR:-"settings.jar"}

case "$PLATFORM" in
	MSYS_NT*)
		S_DIR="${R_DIR%/}/win"
		;;
	Darwin)
		S_DIR="${R_DIR%/}/darwin"
		;;
esac

case "$@" in
	-x*|--extract=*)
		echo "xyz|$2|abc"
		[ -d "${PREFIX}" ] || mkdir -p "${PREFIX}"
		cd "${PREFIX}" ; jar xvf "$2"	
		;;
	*)
		jar cvfM "${PREFIX%/}/${S_JAR}" -C "${S_DIR}" .
		;;
esac

