#!/bin/bash
#------------------------------------------------
# target: ctags wrapper
# author: junjiemars@gmail.com
#------------------------------------------------

CTAGS="${CTAGS:-ctags}"
PREFIX="${PREFIX:-`pwd`}"
PLATFORM="`uname -s 2>/dev/null`"
VERSION="1.1"

CTAGS_LANG=
CTAGS_OPTIONS=

usage() {
  echo -e "Usage: $(basename $0) [OPTIONS]"
  echo -e "       $(basename $0) [ --help | --version]\n"
  echo -e "Options:"
  echo -e "  --help\t\tPrint this message"
  echo -e "  --version\t\tPrint version"
  echo -e "  --language\t\tspecify language:c,java,sql,sh"
  echo -e "  --ctags-options\tctags options"
}

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

for option
do
  opt="$opt `echo $option | sed -e \"s/\(--[^=]*=\)\(.* .*\)/\1'\2'/\"`"
  
  case "$option" in
    -*=*) value=`echo "$option" | sed -e 's/[-_a-zA-Z0-9]*=//'` ;;
    *) value="" ;;
  esac
  
  case "$option" in
    --help)                  help=yes                   ;;
    --version)               version=yes      			    ;;

    --language=*)            CTAGS_LANG="$value" 				;;
    --ctags-options=*)       CTAGS_OPTIONS="$value"			;;
    
    *)
      echo "$0: error: invalid option \"$option\""
			usage
      exit 1
    ;;
  esac
done

if [ "$help" = "yes" -o 0 -eq $# ]; then
	usage
	exit 0
fi

if [ "$version" = "yes" ]; then
	echo -e "$VERSION"
	exit 0
fi

if [ 0 -eq $(ctags_exists) -a 0 -eq $(ctags_exuberant) ]; then
	[ $# -lt 1 ] && exit 1

	CTAGS_LANG="`echo $CTAGS_LANG | tr [:lower:] [:upper:]`"

	case $CTAGS_LANG in
		C)
			$CTAGS `eval echo $(c_tags)` $CTAGS_OPTIONS
			;;
		JAVA)
			$CTAGS `eval echo $(java_tags)` $CTAGS_OPTIONS
			;;
		SH)
			$CTAGS `eval echo $(sh_tags)` $CTAGS_OPTIONS
			;;
		SQL)
			$CTAGS `eval echo $(sql_tags)` $CTAGS_OPTIONS
			;;
		*)
			$CTAGS $CTAGS_OPTIONS
	esac

fi
