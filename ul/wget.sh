#!/bin/bash
#------------------------------------------------
# target: a wget shortcut to mirror a website 
# author: junjiemars@gmail.com
#------------------------------------------------

PREFIX="${PREFIX:-`pwd`}"
PLATFORM="`uname -s 2>/dev/null`"
VERSION="1.0"


function usage() {
  echo -e "Usage: $(basename $0) [OPTIONS] [COMMAND]"
  echo -e "       $(basename $0) [ --help | --version]"
	echo -e ""
	echo -e "A shortcut of wget to mirror a website"
	echo -e ""
  echo -e "Options:"
  echo -e "  --help\t\t\tPrint this message"
  echo -e "  --version\t\t\tPrint version"
  echo -e "  --website\t\t\tspecify the website to mirror"
  echo -e "  --cookie\t\t\tcookie file"
  echo -e "  --user-agent\t\t\tuser agent"
  echo -e "  --prefix\t\t\toutput dir prefix"
  echo -e "  --encode\t\t\tinput encoding"
  echo -e "  --decode\t\t\toutput encoding"
  echo -e "  --decode-dir\t\t\tdecode dir"
  echo -e "  --decode-filter\t\t\tdecode files on filter"
  echo -e "  --wget-options\t\twget options"

	echo -e ""
	echo -e "Commands:"
  echo -e "  mirror\t\t\tmirror a website"
  echo -e "  decode\t\t\tdecode the website"
}

function mirror() {
	local w="$1"
	local c="$2"
	local ua="$3" 
	local opt="$4"
	local d="$5"

	wget --load-cookie=$c --user-agent="`cat $ua`" --directory-prefix=$d $opt -c -m "$w"
}

function decode() {
	fsrc="$1"
	fdst="$2"
	csrc="$3"
	ddst="$4"
	dfilter="$5"
	
	for f in $(find $fsrc)
	do
		echo $f
		if [ -d $f ]; then
			[ -d ${fdst%/}/$f ] || mkdir -p ${fdst%/}/$f
		else
			case "$f" in
				$dfilter)
					if [ ! -f ${fdst%/}$f ]; then
						iconv -f$csrc -t$ddst $f >${fdst%/}/$f
					fi
					;;
				*)
					echo "skip $f"
					;;
			esac	
		fi
	done
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

		--website=*)             website="$value"           ;;
		--cookie=*)              cookie="$value"            ;;
		--user-agent=*)          user_agent="$value"        ;;
		--prefix=*)              prefix="$value"            ;;
		--encode=*)              encode="$value"            ;;
		--decode=*)              decode="$value"            ;;
		--decode-dir=*)          decode_dir="$value"        ;;
		--decode-filter=*)       decode_filter="$value"     ;;

    --wget-options=*)        wget_opt="$value"			    ;;
    
    *)
			command=$option
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

if [ -n "$prefix" -a -d "$prefix" ]; then
	PREFIX=$prefix
fi


retval=0
command="`echo $command | tr '[:upper:]' '[:lower:]'`"
case "$command" in
  mirror)
		if [ -z "$website" ]; then
			echo -e "! missing --website=* option"
			exit 1
		fi

		if [ ! -f "$cookie" ]; then
			echo -e "! missing --cookie=* option"
			exit 1
		fi

		if [ -z "$user_agent" ]; then
			echo -e "# missing --user-agent=* option, using default one"
		fi
		
		mirror $website $cookie $user_agent $wget_opt $PREFIX
    ;;
  decode)
		if [ -z "$decode_dir" ]; then
			echo -e "! missing --decode-dir=* option"
			exit 1
		else
			[ -d "$decode_dir" ] || mkdir -p "$decode_dir"	
		fi

		if [ -z "$encode" ]; then
			echo -e "! missing --encode=* option"
			exit 1
		fi

		if [ -z "$decode" ]; then
			echo -e "# missing --decode=* option, using --decode=utf8"
			decode="utf8"
		fi

		if [ -z "$decode_filter" ]; then
			echo -e "! missing --decode-filter=* option"
			exit 1
		fi

		decode "$PREFIX" "$decode_dir" $encode $decode "$decode_filter"
    ;;
  *)
    echo "$0: error: invalid command \"$command\""
		usage
    ;;
esac

