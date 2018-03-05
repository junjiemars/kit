#!/bin/bash
#------------------------------------------------
# author: junjiemars@gmail.com
# target: SQL*Plus Kits
# note: suit for multiple Oracle coexisting env
#------------------------------------------------

PLATFORM="`uname -s 2>/dev/null`"
ROOT="$(cd `dirname ${BASH_SOURCE[0]}`; pwd -P)"
RLWRAP="${RLWRAP:-`hash rlwrap &>/dev/null && echo rlwrap`}"

ORACLE_HOME="${ORACLE_HOME%/:-}"
SQLPATH="${SQLPATH%/:-}"
NLS_LANG="${NLS_LANG:-AMERICAN_AMERICA.UTF8}"

oracle_home_file="${ROOT%/}/.oracle.home"
oracle_sqlpath_file="${ROOT%/}/.oracle.sqlpath"
oracle_uid_file="${ROOT%/}/.oracle.uid"
oracle_login_file="${ROOT%/}/login.sql"

argv=()
help=no
verbose=no
oracle_home=
oracle_sqlpath=
oracle_uid=
oracle_nls_lang=
sqlplus_opts=

sqlplus_name() {
  case "$PLATFORM" in
    MSYS_NT*|MINGW*)
			echo "sqlplus.exe"
     ;;
    *)
			echo "sqlplus"
		;;
  esac
}

find_sqlplus_path() {
	local p=
	local t=

	p="`which sqlplus 2>/dev/null`"
	t=$?

	[ 0 -eq $t -a -n "$p" ] || return $t
	echo "`dirname $p`"
}

gen_oracle_home_file() {
	local pre_file="${oracle_home_file}.pre"

	if [ -f "$oracle_home_file" ]; then
		mv "$oracle_home_file" "$pre_file"
	fi

	cat << END > "$oracle_home_file" 
export ORACLE_HOME="${ORACLE_HOME}"
END
}

gen_oracle_sqlpath_file() {
	local pre_file="${oracle_sqlpath_file}.pre"

	if [ -f "$oracle_sqlpath_file" ]; then
		mv "$oracle_sqlpath_file" "$pre_file"
	fi

	cat << END > "$oracle_sqlpath_file" 
export SQLPATH="${SQLPATH}"
END
}

gen_oracle_uid_file() {
	local userid="$@"
	local pre_file="${userid_file}.pre"

	if [ -f "$oracle_uid_file" ]; then
		mv "$oracle_uid_file" "$pre_file"
	fi

	cat << END > "$oracle_uid_file" 
oracle_uid=${oracle_uid}
END
}

gen_oracle_login_file() {
	if [ ! -f "$oracle_login_file" ]; then
		cat << END > "$oracle_login_file"
--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: set sqlplus prompt
-- note: 
-- > put login.sql under the directory that
-- > \$SQLPATH point to
--------------------------------------------------

set sqlprompt '&_user.@&_connect_identifier.> ';

-- use \$? | %errorlevel%
-- whenever sqlerror exit sql.sqlcode

set serveroutput on

--set define on;
--define _editor=/usr/bin/vi;
--set define off;
--set sqlblanklines on;
END
	fi
}

validate_oracle_home() {
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

find_oracle_home() {
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

find_sqlpath() {
	if [ -n "$oracle_sqlpath" ]; then
		echo "$oracle_sqlpath"
		return 0;
	fi

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

check_oracle_env() {
	if [ -z "$ORACLE_HOME" ]; then
		[ -f "$oracle_home_file" ] && . "$oracle_home_file"
	fi

	if [ -z "$SQLPATH" ]; then
		[ -f "$oracle_sqlpath_file" ] && . "$oracle_sqlpath_file"
	fi

	if validate_oracle_home; then
		SQLPATH="`find_sqlpath`"
		export SQLPATH
		gen_oracle_sqlpath_file
		gen_oracle_home_file && return 0
	fi

	ORACLE_HOME="`find_oracle_home`"
	validate_oracle_home || return $?

	SQLPATH="`find_sqlpath`"
	export SQLPATH

	gen_oracle_sqlpath_file
	gen_oracle_home_file
}

usage() {
	echo -e "Usage: $(basename $0) [OPTIONS] [sqlplus argv...]"
	echo -e ""
  echo -e "Options:"
  echo -e "  --help\t\t\tPrint this message"
  echo -e "  --verbose\t\t\tverbose print environment variables"
  echo -e "  --sqlplus-opts=\t\tsqlplus options, should be quoted"
  echo -e "  --oracle-home=\t\tset local ORACLE_HOME"
  echo -e "  --oracle-sqlpath=\t\tpush local oracle SQLPATH"
  echo -e "  --oracle-nls-lang=\t\tset local oracle NLS_LANG=$NLS_LANG"
  echo -e "  --oracle-uid=\t\t\toracle user id: user/password@host:port/sid"
}

echo_env() {
	[ "yes" = "$verbose" ] || return 0
	
	echo "ORACLE_HOME=$ORACLE_HOME"
	echo "SQLPATH=$SQLPATH"
	echo "NLS_LANG=$NLS_LANG"
	echo "oracle_home_file=$oracle_home_file"
	echo "oracle_sqlpath_file=$oracle_sqlpath_file"
	echo "oracle_uid_file=$oracle_uid_file"
	echo "oracle_login_file=$oracle_login_file"
	echo "oracle_uid=$oracle_uid"
	echo "argv=${sqlplus_opts:+$sqlplus_opts }${argv[@]}"
}


for option
do
  case "$option" in
    --help)                  help=yes                   ;;
		--verbose)               verbose=yes                ;;
		--sqlplus-opts=*) 
			sqlplus_opts="`echo $option | sed -e 's/--sqlplus-opts=\(.*\)/\1/'`"
		;;
		--oracle-home=*) 
			oracle_home="`echo $option | sed -e 's/--oracle-home=\(.*\)/\1/'`"
		;;
		--oracle-sqlpath=*) 
			oracle_sqlpath="`echo $option | sed -e 's/--oracle-sqlpath=\(.*\)/\1/'`"
		;;
    --oracle-uid=*) 
			oracle_uid="`echo $option | sed -e 's/--oracle-uid=\(.*\)/\1/'`"
		;;
    --oracle-nls-lang=*) 
			oracle_nls_lang="`echo $option | sed -e 's/--oracle-nls-lang=\(.*\)/\1/'`"
		;;

    *) argv+=("$option") ;;
  esac
done


if [ "yes" = "$help" ]; then
	usage
	exit 0
fi

if [ -n "$oracle_home" ]; then
	oracle_home="${oracle_home%/}"
	export ORACLE_HOME="$oracle_home"
fi

if [ -n "${oracle_sqlpath}" ]; then
	oracle_sqlpath="${oracle_sqlpath%/}"
	export SQLPATH="$oracle_sqlpath"
fi

if [ -n "$oracle_nls_lang" ]; then
	NLS_LANG="$oracle_nls_lang"
fi
export NLS_LANG

check_oracle_env
if [ 0 -ne $? ]; then
	echo_env
	exit 1
fi

if [ -z "$oracle_uid" ]; then
	[ -f "$oracle_uid_file" ] && . "$oracle_uid_file"
fi

gen_oracle_login_file
echo_env

${RLWRAP} sqlplus ${sqlplus_opts} ${oracle_uid} ${argv[@]}
if [ 0 -eq $? -a -n "$oracle_uid" ]; then
	gen_oracle_uid_file
fi
