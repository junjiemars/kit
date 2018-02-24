#!/bin/bash
#------------------------------------------------
# author: junjiemars@gmail.com
# target: SQL*Plus Kits
# note: suit for multiple Oracle coexisting env
#------------------------------------------------

PLATFORM=`uname -s 2>/dev/null`
ROOT="$(cd `dirname ${BASH_SOURCE[0]}`; pwd -P)"

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

function find_sqlplus_path() {
	local p=
	local t=

	p="`which sqlplus 2>/dev/null`"
	t=$?

	[ 0 -eq $t -a -n "$p" ] || return $t
	echo "`dirname $p`"
}

function gen_oracle_env_file() {
	local env_file="$@"
	local pre_file="${env_file}.pre"

	if [ -f "$env_file" ]; then
		mv "$env_file" "$pre_file"
	fi

	cat << END > "$env_file" 
export ORACLE_HOME="${ORACLE_HOME}"
export SQLPATH="${SQLPATH}"
END
}

function validate_oracle_home() {
	[ -n "$ORACLE_HOME" ] || return 1

	ORACLE_HOME="${ORACLE_HOME%/}"
	if `sqlplus -V &>/dev/null`; then
		return 0 
	fi

	local lib_path="${ORACLE_HOME}"
	local bin_path="${ORACLE_HOME}"

	if [ -d "${ORACLE_HOME}/lib" ]; then
		lib_path="${ORACLE_HOME}/lib"
	fi

	if [ -d "${ORACLE_HOME}/bin" ]; then
		bin_path="${ORACLE_HOME}/bin"
	fi


	bin_path="${bin_path}${PATH:+:$PATH}"

	local t=0
	case $PLATFORM in
    MSYS_NT*|MINGW*)
			bin_path="${lib_path}:${bin_path}"

			PATH="$bin_path" sqlplus -V &>/dev/null
			t=$?

			if [ 0 -eq $t ]; then
				export ORACLE_HOME="$ORACLE_HOME"
				export PATH="$bin_path"
				return 0
			fi
			;;

		Darwin)
			lib_path="${lib_path}${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"

			PATH="${bin_path}" DYLD_LIBRARY_PATH="${lib_path}" \
			sqlplus -V &>/dev/null
			t=$?

			if [ 0 -eq $t ]; then
				export ORACLE_HOME="$ORACLE_HOME"
				export DYLD_LIBRARY_PATH="$lib_path"
				export PATH="$bin_path"
				return 0
			fi
			;;

		*)
			lib_path="${lib_path}${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

			PATH="${bin_path}" LD_LIBRARY_PATH="${lib_path}" \
			sqlplus -V &>/dev/null
			t=$?

			if [ 0 -eq $t ]; then
				export ORACLE_HOME="$ORACLE_HOME"
				export LD_LIBRARY_PATH="$lib_path"
				export PATH="$bin_path"
				return 0
			fi	
			;;
	esac	
	return $t 
}

function find_oracle_home() {
	local n="`sqlplus_name`"
	local s="`find_sqlplus_path`"
	local h=( 
		"$ROOT"
		"$s"
		"/u01/app/oracle/product"
		"/u02/app/oracle/product"
		"/c/u01/app/oracle/product"
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

function find_sqlpath() {
	if [ -n "$SQLPATH" ]; then
		echo "$SQLPATH"
		return 0
	fi

	local sql=(
		"$ROOT"
		"$ROOT/oracle"
		"$ROOT/db"
		"$ORACLE_HOME"
		"$ORACLE_BASE"
		"${HOME%/}/product"
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
		p="${p:+$p\n}${i}"
		f="`find $i -type f -name 'login.sql' -print -quit`"
		if [ -n "$f" -a -f "$f" ]; then
			p="${p:+$p\n}`dirname ${f}`"
		fi
	done
	echo -e "$p" | uniq | tr '\n' ':' | sed -e 's_:$__g'
}

function check_oracle_env() {
	local t=0
	local env_file="${ROOT%/}/.oracle.env"

	validate_oracle_home
	t=$?
	if [ 0 -eq $t ]; then
		SQLPATH="`find_sqlpath`"
		export SQLPATH
		gen_oracle_env_file "$env_file"
		return 0
	fi


	[ -f "$env_file" ] && . "$env_file"
	
	validate_oracle_home
	t=$?
	if [ 0 -ne $t ]; then
		ORACLE_HOME="`find_oracle_home`"
		validate_oracle_home
		t=$?
		[ 0 -eq $t ] || return $t
	fi

	SQLPATH="`find_sqlpath`"
	export SQLPATH

	gen_oracle_env_file "$env_file"
}


ORACLE_HOME="${ORACLE_HOME:-}"
SQLPATH="${SQLPATH:-}"
export NLS_LANG="${NLS_LANG:-AMERICAN_AMERICA.UTF8}"

check_oracle_env
if [ 0 -ne $? ]; then
	echo "ORACLE_HOME=$ORACLE_HOME"
	echo "PATH=$PATH"
	echo "! ORACLE environment  =invalid"
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
else
	if [[ $1 =~ ..*/..*@..*:[0-9][0-9]*[:/]..* ]]; then
		${RLWRAP} sqlplus $1 ${@:2}
	elif [[ $1 =~ ..*/..* ]]; then
			${RLWRAP} sqlplus $1@${USERID} ${@:2}
  else
		${RLWRAP} sqlplus ${ORA_USER}/${ORA_PASSWD}@${USERID} $@
  fi
fi
