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
  local options="$1"
	local inc=("/usr/include")
  local inc_file="$HOME/.cc-inc.list"

	if [ -f "$inc_file" ]; then 
    local cc_list=
		case $PLATFORM in
			MSYS_NT*)
        cc_list="`cat $inc_file | tr '\r\n' ';' | tr -d \'`"
				;;
			*)
				cc_list="`cat $inc_file | tr ' ' '\n' | sort | tr '\n' ';'`"
				;;
		esac

    $CTAGS --language-force=C --C-kinds=+px --extra=+fq \
	 				 --langmap=c:.c.h                             \
           -R "${PREFIX}" ${options}
    IFS=';' read -a inc <<< "${cc_list}"
    for i in "${inc[@]}"; do
      $CTAGS --language-force=C --C-kinds=+px --extra=+fq -a \
	 				   --langmap=c:.c.h                                \
					   --exclude=c++ --exclude=*.d                     \
             -R "${i}" ${options}
    done
  else
    $CTAGS --language-force=C --C-kinds=+px --extra=+fq  \
	 				 --langmap=c:.c.h                              \
					 --exclude=c++ --exclude=*.d                   \
           -R "${PREFIX}" "${inc[@]}" ${options}
	fi
}

java_tags() {
	#extract src.zip under $JAVA_HOME 
	local src="$JAVA_HOME/src"
	[ -d "$src" ] || src=""
	$CTAGS --language-force=Java --Java-kinds=+p --extra=+fq \
         -R "${PREFIX}" "${src}"
}

sh_tags() {
	$CTAGS --language-force=Sh --extra=+f -R "${PREFIX}"
}

sql_tags() {
	$CTAGS --language-force=SQL --SQL-kinds=+px --extra=+fq -R "${PREFIX}"
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
			c_tags "$CTAGS_OPTIONS"
			;;
		JAVA)
      java_tags "$CTAGS_OPTIONS"
			;;
		SH)
      sh_tags "$CTAGS_OPTIONS"
			;;
		SQL)
			sql_tags "$CTAGS_OPTIONS"
			;;
		*)
			$CTAGS $CTAGS_OPTIONS
	esac

fi
