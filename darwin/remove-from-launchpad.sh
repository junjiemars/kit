#!/bin/bash
#------------------------------------------------
# target: show or remove icon from Launchpad
# author: junjiemars@gmail.com
#------------------------------------------------

function usage() {
  echo -e "Usage: $(basename $0) [OPTIONS]"
  echo -e "       $(basename $0) [ --help | --version ]\n"
  echo -e "Options:"
  echo -e "  --help      Print usage"
  echo -e "  --names=    app's name splited by comma"
  echo -e "  --remove    if yes then to remove, otherwise to show"
	echo -e "  --dry       dry run"
}

for option
do
  opt="$opt `echo $option | sed -e \"s/\(--[^=]*=\)\(.* .*\)/\1'\2'/\"`"

  case "$option" in
    -*=*) value=`echo "$option" | sed -e 's/[-_a-zA-Z0-9]*=//'` ;;
    *) value="" ;;
  esac

  case "$option" in
    --help)                  				help=yes                   				 ;;
    --names=*)               				__names="$value"             			 ;;
    --remove=*)       				      __remove="$value"    	  				   ;;
		--dry)                          __dry=yes                          ;;
    *)
			echo "$0: error: invalid option \"$option\""
			exit 1
		;;
  esac
done

if [ "yes" = "$help" ]; then
	usage
	exit 0
fi

NAMES=()
SQL=""

if [ -z "$__names" ]; then
	if [ "yes" = "$__remove" ]; then
		echo "$0: error: --name option can not be empty"
		exit 1
	fi
else
	IFS=',' read -a NAMES <<< "${__names}"
	for n in "${NAMES[@]}"; do
		SQL="title='$n' ${SQL:+or $SQL}"
	done
	unset IFS
fi

if [ "yes" != "$__remove" ]; then
	SQL="${SQL:+SELECT * FROM apps WHERE $SQL}"
else
	SQL="${SQL:+DELETE FROM apps WHERE $SQL}"
fi

if [ "yes" = "$__dry" ]; then
	echo "# dry run: ... "
	echo "${SQL}"
else
	sqlite3 \
		$(find /private/var/folders \
					 \( -name com.apple.dock.launchpad -a -user $USER \) \
					 2> /dev/null)/db/db \
		"${SQL}"
	if [ "yes" = "$__remove" ]; then
		killall Dock
	fi
fi

