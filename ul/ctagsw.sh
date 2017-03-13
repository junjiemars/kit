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

c_tags() {
	local inc='/usr/include'
	[ -f "~/.cc-inc.list" ] && inc="`cat ~/.cc-inc.list`"
	echo "--language-force=C --C-kinds=+px --extra=+fq -R $PREFIX $inc"
}

java_tags() {
	#extract src.zip under $JAVA_HOME 
	local src="$JAVA_HOME/src"
	[ -d "$src" ] || src=""
	echo "--language-force=Java --Java-kinds=+p --extra=+fq -R $PREFIX $src"
}

sh_tags() {
	echo "--language-force=Sh --extra=+f -R $PREFIX "
}

sql_tags() {
	echo "--language-force=SQL --SQL-kinds=+px --extra=+fq -R $PREFIX "
}

if [ 0 -eq $(ctags_exists) -a 0 -eq $(ctags_exuberant) ]; then
	[ $# -lt 1 ] && exit 1

	case $1 in
		C)
			shift 
			$CTAGS $@ `eval echo $(c_tags)`
			;;
		Java)
			shift
			$CTAGS $@ `eval echo $(java_tags)`
			;;
		Sh)
			shift
			$CTAGS $@ `eval echo $(sh_tags)`
			;;
		SQL)
			shift
			$CTAGS $@ `eval echo $(sql_tags)`
			;;
	esac

fi
