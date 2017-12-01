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

function check_sqlplus_path() {
	local p=
	local t=

	p="`which sqlplus 2>/dev/null`"
	t=$?

	[ 0 -eq $t -a -n "$p" ] || return $t
	echo "`dirname $p`"
}

function check_oracle_home() {
	local n="`sqlplus_name`"
	local s="`check_sqlplus_path`"
	local h=( 
		"$s"
		"$PWD_DIR"
		"/u01/app/oracle/product"
		"/u02/app/oracle/product"
		"/oracle"
	)
	if [ -n "$OPT_RUN" -a -d "$OPT_RUN" ]; then
		h+=( "$OPT_RUN" )
		h+=( "`dirname ${OPT_RUN%/}`/oracle" )
	fi

	local p=
	local d=

	for i in "${h[@]}"; do
		[ -n "$i" -a -d "$i" ] || continue
		p="`find $i -type f -name $n -print -quit`"
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
		"$PWD_DIR/oracle"
		"$PWD_DIR/db"
		"$ORACLE_HOME"
	)
	local p=
	local f=	

	if [ -n "$OPT_RUN" -a -d "$OPT_RUN" ]; then
		sql+=( "$OPT_RUN" )
		sql+=( "`dirname ${OPT_RUN%/}`/apps/kit" )
		sql+=( "${HOME%/}/apps/kit" )
	fi

	for i in "${sql[@]}"; do
		[ -n "$i" -a -d "$i" ] || continue
		p="$i${p:+\n$p}"
		f="`find $i -type f -name 'login.sql' -print -quit`"
		if [ -n "$f" -a -f "$f" ]; then
			p="`dirname ${f}`${p:+\n$p}"
		fi
	done
	echo -e "$p" | uniq | tr '\n' ':' | sed -e 's_:$__g'
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

if ! `sqlplus_name -V &>/dev/null`; then
	echo -e "! `sqlplus_name`  =invalid"
	echo -e "# ORACLE_HOME=$ORACLE_HOME"
	echo -e "# SQLPATH=$SQLPATH"
	echo -e "# PATH=$PATH"
	case $PLATFORM in
		Darwin)
			echo -e "# DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH"
			;;
		*)
			echo -e "# LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
			;;
	esac
	exit 1
fi


ORA_USER=${ORA_USER:-system}
ORA_PASSWD=${ORA_PASSWD:-oracle}
HOST=${HOST:-localhost}
PORT=${PORT:-1521}
SID=${SID:-'XE'}
USERID=${USERID:-${HOST}:${PORT}/${SID}}

if `hash rlwrap &>/dev/null`; then
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
fi
