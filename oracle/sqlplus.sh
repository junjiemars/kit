#!/bin/bash
#------------------------------------------------
# author: junjiemars@gmail.com
# target: SQL*Plus Kits
# note: suit for multiple Oracle coexisting env
#------------------------------------------------

PLATFORM=`uname -s 2>/dev/null`
PWD_DIR="$(cd `dirname ${BASH_SOURCE[0]}`; pwd -P)"

function sqlplus_name() {
  case "$PLATFORM" in
    MSYS_NT*|MINGW*)
			echo "sqlplus.exe"
     ;;
    *)
			echo "sqlplus"
		;;
  esac
}

function check_oracle_home() {
	local n="`sqlplus_name`"
	local h=( 
		"$PWD_DIR"
		"/u01/app/oracle/product"
		"/u02/app/oracle/product"
		"/oracle"
		"/opt/oracle"
		"/c/oracle"
	)

	local p=
	local d=

	for i in "${h[@]}"; do
		[ -n "$i" -o -d "$i" ] || continue
		p="`find $i -type f -name $n`"
		if [ 0 -eq $? -a -n "$p" ]; then
			d=$(basename `dirname "$p"`)
			if [ "bin" == "$d" ]; then
				echo "$(dirname `dirname $p`)"
			else
				echo "`dirname $p`"
			fi
			return 0
		fi
	done
	return 1
}

function check_sql_path() {
	local sql=(
		"$PWD_DIR"
		"$ORACLE_HOME"
		"$OPT_RUN"
	)
	local p=
	local f=	

	for i in "${sql[@]}"; do
		[ -n "$i" -o -d "$i" ] || continue
		f="`find $i -type f -name '*.sql' -print -quit`"
		if [ 0 -eq $? -a -n "$f" ]; then
			p="`dirname $f`${p:+:$p}"
		fi
	done
	echo "$p"
}


export ORACLE_HOME="${ORACLE_HOME:-`check_oracle_home`}"
export SQLPATH="${SQLPATH:-`check_sql_path`}"
export NLS_LANG="${NLS_LANG:-AMERICAN_AMERICA.UTF8}"


ORA_LD=${ORACLE_HOME%/}
if [ -d "${ORA_LD}/lib" ]; then
	ORA_LD="${ORA_LD}/lib"
fi

ORA_BIN=${ORACLE_HOME%/}
if [ -d "${ORA_BIN}/bin" ]; then
	ORA_BIN="${ORA_BIN}/bin"
fi

case $PLATFORM in
	Darwin)
		export DYLD_LIBRARY_PATH="${ORA_LD}${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
		;;
	*)
		export LD_LIBRARY_PATH="${ORA_LD}${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
		;;
esac

export PATH="${ORA_BIN}${PATH:+:$PATH}"

ORA_USER=${ORA_USER:-system}
ORA_PASSWD=${ORA_PASSWD:-oracle}
HOST=${HOST:-localhost}
PORT=${PORT:-1521}
SID=${SID:-'XE'}
USERID=${USERID:-${HOST}:${PORT}/${SID}}

if [ 0 -eq `type -p rlwrap &>/dev/null; echo $?` ]; then
	RLWRAP='rlwrap'
fi	

if [ 0 -eq $# ] ; then
	${RLWRAP} sqlplus ${ORA_USER}/${ORA_PASSWD}@${USERID}
elif [ 1 -le $# ]; then
	if `echo $1|grep .*@.*[:/][0-9]*[:/].* &>/dev/null`; then
		${RLWRAP} sqlplus $1 ${@:2}
  else
		${RLWRAP} sqlplus $1@${USERID} ${@:2}
  fi
else
	${RLWRAP} sqlplus ${ORA_USER}/${ORA_PASSWD}@${USERID} $1
 $1
fi

