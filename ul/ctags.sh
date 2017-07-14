#!/bin/bash
#------------------------------------------------
# target: a shortcut of exuberant ctags 
# author: junjiemars@gmail.com
#------------------------------------------------

CTAGS="${CTAGS:-ctags}"
PREFIX="${PREFIX:-`pwd`}"
PLATFORM="`uname -s 2>/dev/null`"
VERSION="1.1"


function usage() {
	local x="."
	if [ 0 -ne `ctags_exuberant` ]; then
		x=", but it seems like exhaust ..."
	fi

  echo -e "Usage: $(basename $0) [OPTIONS]"
  echo -e "       $(basename $0) [ --help | --version]"
	echo -e ""
	echo -e "A shortcut of exuberant ctags${x}"
	echo -e ""
  echo -e "Options:"
  echo -e "  --help\t\t\tPrint this message"
  echo -e "  --version\t\t\tPrint version"
  echo -e "  --language\t\t\tspecify language:c,java,sql,sh"
  echo -e "  --ctags-options\t\tctags options"
}

function ctags_exists() {
	type -P $CTAGS &>/dev/null; echo $?
}

function ctags_exuberant() {
	$CTAGS --version 2>/dev/null | grep "^Exuberant Ctags" &>/dev/null; echo $?
}

function c_tags() {
  local options="$1"
	local inc=("/usr/include")
  local inc_file="$HOME/.cc-inc.list"

	if [ -f "$inc_file" ]; then 
    local cc_list=
		case $PLATFORM in
			MSYS_NT*|MINGW*)
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

function java_tags() {
	#extract src.zip under $JAVA_HOME 
	local src="$JAVA_HOME/src"
	[ -d "$src" ] || src=""
	$CTAGS --language-force=Java --Java-kinds=+p --extra=+fq \
         -R "${PREFIX}" "${src}"
}

function sh_tags() {
	$CTAGS --language-force=Sh --extra=+f -R "${PREFIX}"
}

function sql_tags() {
	$CTAGS --language-force=SQL --SQL-kinds=+px --extra=+fq -R "${PREFIX}"
}

function ctags_shell {
	local lan="$1"
	local opt="$2"
	case $lan in
		c)
			c_tags "$opt"
			;;
		java)
			java_tags "$opt"
			;;
		sh)
			sh_tags "$opt"
			;;
		sql)
			sql_tags "$opt"
			;;
		*)
			$CTAGS $opt
	esac
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

    --language=*)            ctags_lang="$value" 				;;
    --ctags-options=*)       ctags_options="$value"			;;
    
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

if [ 0 -ne $(ctags_exists) ]; then
	echo -e "! [$CTAGS] no found ..."
	exit 1
fi

if [ 0 -ne $(ctags_exuberant) ]; then
	echo -e "! [$CTAGS] is exhaust ..."
	exit 1
fi

ctags_lang="`echo $ctags_lang | tr [:upper:] [:lower:]`"
ctags_shell "$ctags_lang" "$ctags_options"

