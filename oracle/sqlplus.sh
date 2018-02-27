#!/bin/bash
#------------------------------------------------
# author: junjiemars@gmail.com
# target: SQL*Plus Kits
# note: suit for multiple Oracle coexisting env
#------------------------------------------------

PLATFORM="`uname -s 2>/dev/null`"
ROOT="$(cd `dirname ${BASH_SOURCE[0]}`; pwd -P)"
SQLPLUS_SH_ARGS=
SQLPLUS_BIN_ARGS=
RLWRAP="${RLWRAP:-`hash rlwrap &>/dev/null && echo rlwrap`}"

ORACLE_HOME="${ORACLE_HOME:-}"
SQLPATH="${SQLPATH:-}"
NLS_LANG="${NLS_LANG:-AMERICAN_AMERICA.UTF8}"

oracle_env_file="${ROOT%/}/.oracle.env"
oracle_uid_file="${ROOT%/}/.oracle.uid"

argv=()
help=no
verbose=no
oracle_home=
oracle_uid=
oracle_nls_lang=
sqlplus_opts=

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
	local pre_file="${oracle_env_file}.pre"

	if [ -f "$oracle_env_file" ]; then
		mv "$oracle_env_file" "$pre_file"
	fi

	cat << END > "$oracle_env_file" 
export ORACLE_HOME="${ORACLE_HOME}"
export SQLPATH="${SQLPATH}"
END
}

function gen_oracle_uid_file() {
	local userid="$@"
	local pre_file="${userid_file}.pre"

	if [ -f "$oracle_uid_file" ]; then
		mv "$oracle_uid_file" "$pre_file"
	fi

	cat << END > "$oracle_uid_file" 
oracle_uid=${oracle_uid}
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

	validate_oracle_home
	t=$?
	if [ 0 -eq $t ]; then
		SQLPATH="`find_sqlpath`"
		export SQLPATH
		gen_oracle_env_file
		return 0
	fi


	[ -f "$oracle_env_file" ] && . "$oracle_env_file"
	
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

	gen_oracle_env_file
}

function usage() {
	echo -e "Usage: $(basename $0) [OPTIONS] -- [sqlplus argv...]"
	echo -e ""
  echo -e "Options:"
  echo -e "  --help\t\t\tPrint this message"
  echo -e "  --verbose\t\t\tverbose print environment variables"
  echo -e "  --oracle-home=\t\tset local ORACLE_HOME"
  echo -e "  --oracle-nls-lang=\t\tset local oracle NLS_LANG=$NLS_LANG"
  echo -e "  --oracle-uid=\t\t\toracle user id, such as user/password@host:port/sid"
}

function echo_env() {
	[ "yes" = "$verbose" ] || return 0
	
	echo "ORACLE_HOME=$ORACLE_HOME"
	echo "SQLPATH=$SQLPATH"
	echo "NLS_LANG=$NLS_LANG"
	echo "SQLPLUS_SH_ARGS=$SQLPLUS_SH_ARGS"
	echo "SQLPLUS_BIN_ARGS=$SQLPLUS_BIN_ARGS"
	echo "oracle_env_file=$oracle_env_file"
	echo "oracle_uid_file=$oracle_uid_file"
	echo "oracle_uid=$oracle_uid"
	echo "argv=${sqlplus_opts} ${oracle_uid} ${SQLPLUS_BIN_ARGS[@]}"
}


for option
do
  case "$option" in
    --sqlplus-opts=*) 
			sqlplus_opts="`echo "$option" | sed -e 's/--sqlplus-opts=\([-.a-zA-Z0-9]*\)/\1/'`" 
			continue ;;
    *) argv+=("$option") ;;
  esac
done


if [[ ${argv[@]} =~ ^.*--$ ]]; then
  SQLPLUS_SH_ARGS="`echo ${argv[@]} | sed -e \"s/\(.*\)--$/\1/\"`"
elif [[ ${argv[@]} =~ ^--[[:space:]][[:space:]]*.*$ ]]; then
	SQLPLUS_BIN_ARGS="`echo ${argv[@]} | sed -e \"s/^--\s\s*\(.*\)/\1/\"`"
elif [[ ${argv[@]} =~ ^..*--[^=]..* ]]; then
  SQLPLUS_SH_ARGS="`echo ${argv[@]} | sed -e \"s/\(.* .*\)--[^=].*/\1/\"`"
	SQLPLUS_BIN_ARGS="`echo ${argv[@]} | sed -e \"s/.*--[^=]\(.*\)/\1/\"`"
else
	SQLPLUS_BIN_ARGS="${argv[@]}"
fi

for option in ${SQLPLUS_SH_ARGS[@]};
do
  opt="$opt `echo $option | sed -e \"s/\(--[^=]*=\)\(.* .*\)/\1'\2'/\"`"
  
  case "$option" in
    --*=*) value=`echo "$option" | sed -e 's/[-_a-zA-Z0-9]*=//'` ;;
    *) value="" ;;
  esac
  
  case "$option" in
    --help)                  help=yes                   ;;
		--verbose)               verbose=yes                ;;
		--oracle-home=*)         oracle_home="$value"       ;;
    --oracle-uid=*)          oracle_uid="$value"        ;;
    --oracle-nls-lang=*)     oracle_nls_lang="$value"   ;;

    *)
			echo "$0: error: invalid `basename $0` option \"$option\""
			usage
			exit 1
    ;;
  esac
done

if [ "yes" = "$help" ]; then
	usage
	exit 0
fi

if [ -n "$oracle_home" ]; then
	export ORACLE_HOME="$oracle_home"
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

echo_env

if [ -z "${SQLPLUS_BIN_ARGS[@]}" ]; then
	${RLWRAP} sqlplus ${sqlplus_opts} ${oracle_uid}
else
	${RLWRAP} sqlplus ${sqlplus_opts} ${oracle_uid} ${SQLPLUS_BIN_ARGS[@]}
fi

if [ 0 -eq $? -a -n "$oracle_uid" ]; then
	gen_oracle_uid_file
fi
