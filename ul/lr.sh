#!/bin/bash
#------------------------------------------------
# target: log rotate
# author: junjiemars@gmail.com
#------------------------------------------------

FILE=
SIZE=${SIZE:-10}
KEEP=${KEEP:-0}

usage() {
  echo -e "Usage: $(basename $0) [OPTIONS]"
  echo -e "       $(basename $0) [ --help | --file | --size ]\n"
  echo -e "Options:"
  echo -e "  --help\t\tPrint usage"
  echo -e "  --file\t\tFile path will be rotated"
  echo -e "  --size\t\tSize in MiB, default 10MiB"
  echo -e "  --keep\t\tKeep the file, default is false"
}


rotate() {
	local size=`echo $SIZE | sed 's/\([0-9][0-9]*\)\([kKmMgG]\)/\1/'`
	local unit=`echo $SIZE | sed 's/\([0-9][0-9]*\)\([kKmMgG]\)/\2/'`
	local bytes=$(( 1024*1024*10 ))
	
	if [ -z "$unit" ]; then
		unit="M"
	else
		unit=`echo $unit | tr -s [:lower:] [:upper:]`
	fi

	[ -z "$size" ] && size=$SIZE

	case $unit in
		K)
			bytes=$(( 1024*size ))
		;;
		M)
			bytes=$(( 1024*1024*size ))
		;;
		G)
			bytes=$(( 1024*1024*1024*size ))
		;;
	esac

	if [ 0 -lt $KEEP ]; then
		cp "$FILE" "$FILE.b0"
	fi

	cat /dev/null > "$FILE"
}

for option
do
  opt="$opt `echo $option | sed -e \"s/\(--[^=]*=\)\(.* .*\)/\1'\2'/\"`"
  
  case "$option" in
    -*=*) value=`echo "$option" | sed -e 's/[-_a-zA-Z0-9]*=//'` ;;
    *) value="" ;;
  esac
  
  case "$option" in
    --help)                          help=yes                   ;;
    
    --file=*)                        FILE="$value"     			    ;;
    --size=*)   	                   SIZE="$value"       				;;
    --keep)   	                     KEEP=1             				;;
    
    *)
      echo "$0: error: invalid option \"$option\""
			usage
      exit 1
    ;;
  esac
done

if [ "$help" = "yes" ]; then
	usage
	exit 1
fi

if [ -z "$FILE" ]; then
	echo "missiing --file option"
	exit 1
fi

if [ ! -f "$FILE" ]; then
	echo "$file no found"
	exit 1
fi

rotate
