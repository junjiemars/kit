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
ORACLE_PATH="${ORACLE_PATH%/:-}"
NLS_LANG="${NLS_LANG:-AMERICAN_AMERICA.UTF8}"

oracle_home_file=".oracle.home"
oracle_path_file=".oracle.path"
oracle_uid_file=".oracle.uid"
oracle_login_file="${ROOT%/}/login.sql"

argv=()
help=no
verbose=no
profile=
oracle_home=
oracle_path=
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

gen_oracle_path_file() {
	local pre_file="${oracle_path_file}.pre"

	if [ -f "$oracle_path_file" ]; then
		mv "$oracle_path_file" "$pre_file"
	fi

	cat << END > "$oracle_path_file" 
export ORACLE_PATH="${ORACLE_PATH}"
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
-- > \$ORACLE_PATH point to
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

find_oracle_path() {
	if [ -n "$oracle_path" ]; then
		echo "$oracle_path"
		return 0;
	fi

	if [ -n "$ORACLE_PATH" ]; then
		echo "$ORACLE_PATH"
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

	if [ -z "$ORACLE_PATH" ]; then
		[ -f "$oracle_path_file" ] && . "$oracle_path_file"
	fi

	if validate_oracle_home; then
		ORACLE_PATH="`find_oracle_path`"
		export ORACLE_PATH
		gen_oracle_path_file
		gen_oracle_home_file && return 0
	fi

	ORACLE_HOME="`find_oracle_home`"
	validate_oracle_home || return $?

	ORACLE_PATH="`find_oracle_path`"
	export ORACLE_PATH

	gen_oracle_path_file
	gen_oracle_home_file
}

usage() {
	echo -e "Usage: $(basename $0) [OPTIONS] [sqlplus argv...]"
	echo -e ""
  echo -e "Options:"
  echo -e "  --help\t\t\tPrint this message"
  echo -e "  --verbose\t\t\tverbose print environment variables"
	echo -e "  --profile=\t\t\tprofile environment"
  echo -e "  --sqlplus-opts=\t\tsqlplus options, should be quoted"
  echo -e "  --oracle-home=\t\tset local ORACLE_HOME"
  echo -e "  --oracle-path=\t\tpush local oracle ORACLE_PATH"
  echo -e "  --oracle-nls-lang=\t\tset local oracle NLS_LANG=$NLS_LANG"
  echo -e "  --oracle-uid=\t\t\toracle user id: user/password@host:port/sid"
}

echo_env() {
	[ "yes" = "$verbose" ] || return 0
	
	echo "ORACLE_HOME=$ORACLE_HOME"
	echo "ORACLE_PATH=$ORACLE_PATH"
	echo "NLS_LANG=$NLS_LANG"
	echo "oracle_home_file=$oracle_home_file"
	echo "oracle_path_file=$oracle_path_file"
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
		--profile=*)
			profile="`echo $option | sed -e 's/--profile=\(.*\)/\1/'`"
			;;
		--sqlplus-opts=*) 
			sqlplus_opts="`echo $option | sed -e 's/--sqlplus-opts=\(.*\)/\1/'`"
			;;
		--oracle-home=*) 
			oracle_home="`echo $option | sed -e 's/--oracle-home=\(.*\)/\1/'`"
			;;
		--oracle-path=*) 
			oracle_path="`echo $option | sed -e 's/--oracle-path=\(.*\)/\1/'`"
			;;
    --oracle-uid=*) 
			oracle_uid="`echo $option | sed -e 's/--oracle-uid=\(.*\)/\1/'`"
			;;
    --oracle-nls-lang=*) 
			oracle_nls_lang="`echo $option | sed -e 's/--oracle-nls-lang=\(.*\)/\1/'`"
			;;

    *) argv+=("$option")
		  ;;
  esac
done


if [ "yes" = "$help" ]; then
	usage
	exit 0
fi

if [ -n "$profile" ]; then
	oracle_home_file="${ROOT%/}/${oracle_home_file}${profile:+.$profile}"
	oracle_uid_file="${ROOT%/}/${oracle_uid_file}${profile:+.$profile}"
	oracle_path_file="${ROOT%/}/${oracle_path_file}${profile:+.$profile}"
else
	oracle_home_file="${ROOT%/}/${oracle_home_file}"
	oracle_uid_file="${ROOT%/}/${oracle_uid_file}"
	oracle_path_file="${ROOT%/}/${oracle_path_file}"
fi

if [ -n "$oracle_home" ]; then
	oracle_home="${oracle_home%/}"
	export ORACLE_HOME="$oracle_home"
fi

if [ -n "${oracle_path}" ]; then
	oracle_path="${oracle_path%/}"
	export ORACLE_PATH="$oracle_path"
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
