#!/bin/bash
#===============================================
# Author: https://github.com/junjiemars/kit
#===============================================
# NOTE:
# If u want to export all objects owned by u
# just run: exp user/passwd owner=user 
# This script just help u to export the objects
# piece by piece.
#===============================================
# MANUAL
#===============================================
PASSCODE=""
dmpdir=""
dmpname=""
tables=""
sqllike=""
sqlexclude=""
debug=false
EXP_OPTS="${EXP_OPTS:="FEEDBACK=1"}"
HELP="usage:\t-h\t\t\thelp\n\
    \t-p<username/password>\toracle login\n\
    \t-d<dump-dir>\t\tdump directory\n\
    \t-t<tables>\t\ttable list, seperate by ','\n\
    \t-s<like-filter>\t\tlike filter, ABC%\n\
    \t-x<excluded>\t\texcluded tables, seperate by ','"

while getopts "hp:dn:t:s:" arg
do
	case ${arg} in
        h) echo -e $HELP;;
		p) PASSCODE=${OPTARG};;
		d) dmpdir=${OPTARG};;
		n) dmpname=${OPTARG};;
		t) tables=${OPTARG};;
		s) sqllike=${OPTARG};;
		#x) sqlexclude=${OPTARG};;
	esac
done

#echo ${dmpname}
PASSCODE="${PASSCODE:-xws/xws@localhost:1521/XE}"
dmpdir="${dmpdir:-/home/junjie/cache/xe}"
dmpname="${dmpname:-tables}"
sqlexclude=""
today=`date +%Y-%m-%d`
dmpfile="${dmpdir}/dump-${dmpname}-${today}.dmp"
logfile="${dmpdir}/dump-${dmpname}-${today}.log"
tablesfile=".tables"

function build_tables() {

echo "${sqllike}"
#echo "${sqlexclude}"
sqlplus ${PASSCODE} <<!
set heading off;
set echo off;
set pages 1000
set long 90000;
define tables_output='${tablesfile}';
define sql_like='${sqllike}';
define sql_exclude='${sqlexclude}';
spool '&tables_output'
select table_name from user_tables where table_name like '&sql_like';
spool off
exit
!

if [ -f ${tablesfile} ]; then
	_trimed="${tablesfile}-trimed"
	cat ${tablesfile} | sed '1,4d' | sed -e :a -e '$d;N;2,4ba' -e 'P;D' | sed 's/[ \t]*$//' | tr '\n' ',' | sed '$s/.$//' > ${_trimed}
	if [ -f ${_trimed} ]; then
		tables=`cat ${_trimed}`
	fi 
fi
}

if [[ -z "${tables}" && -z "${sqllike}" ]]; then
	echo "-t<tables> or -s<sqllike> cannot be null"
	exit;
fi

if [ -n "${sqllike}" ]; then
	build_tables
fi
#echo "exp ${PASSCODE} file=${dmpfile} log=${logfile} tables=${tables} sqllike=${sqllike}"
exp ${PASSCODE} file=${dmpfile} log=${logfile} tables=${tables} ${EXP_OPTS}

