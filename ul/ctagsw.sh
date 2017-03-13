#!/bin/bash
#------------------------------------------------
# target: ctags wrapper
# author: junjiemars@gmail.com
#------------------------------------------------

CTAGS=${CTAGS:-ctags}
PREFIX=${PREFIX:-"`pwd`"}
PLATFORM=`uname -s 2>/dev/null`

ctags_exists() {
	type -P $CTAGS &>/dev/null; echo $?
}

ctags_exuberant() {
	$CTAGS --version 2>/dev/null | grep "^Exuberant Ctags" &>/dev/null; echo $?
}

if [ 0 -eq $(ctags_exists) -a 0 -eq $(ctags_exuberant) ]; then
	case $@ in
		C)
			;;
		Java)
			;;
		*)
			;;
	esac

	case $PLATFORM in
		MSYS_NT*)
			;;
		*)
			;;	
	esac	
fi
