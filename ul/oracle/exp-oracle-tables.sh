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
PASSCODE="${PASSCODE:-xws/xws@localhost:1521/XE}"
EXP_DIR=${EXP_DIR:-$PWD}
TODAY=`date +%Y-%m-%d`
EXP_FILE="${EXP_DIR}/exp-${TODAY}.dmp"
EXP_LOG="${EXP_DIR}/exp-${TODAY}.log"
TABLES=""
SQL_LIKE=""
SQL_EXCLUDE=""
EXP_OPTS="${EXP_OPTS:="FEEDBACK=1"}"
TABLES_LIST="${EXP_DIR}/tables.list"

DEBUG=false
HELP="usage:\texp-oracle-tables.sh <options>\n\
options:-h\t\t\thelp\n\
    \t-p<username/password>\toracle's login\n\
    \t[-w<dump-dir>]\t\tdump directory\n\
    \t-t<tables>\t\ttable list, seperate by ','\n\
    \t-s<like-filter>\t\tlike filter, ABC\%, etc.\n\
    \t[-x<excluded>]\t\texcluded tables, seperate by ','"

while getopts "hdp:wt:s:x:" arg
do
	case ${arg} in
        h) echo -e $HELP; exit 0;;
        d) DEBUG=true;;
		p) PASSCODE=${OPTARG};;
		w) EXP_DIR=${OPTARG};;
		t) TABLES=${OPTARG};;
		s) SQL_LIKE=${OPTARG};;
		x) SQL_EXCLUDE=${OPTARG};;
        *) echo -e $HELP; exit 1;;
	esac
done

function build_tables() {
# sqlplus context 
sqlplus ${PASSCODE} <<!
set heading off;
set echo off;
set pages 1000
set long 90000;
define tables_output='${TABLES_LIST}';
define sql_like='${SQL_LIKE}';
define sql_exclude='${SQL_EXCLUDE}';
spool '&tables_output'
select table_name from user_tables where table_name like '&sql_like';
spool off
exit
!

echo ${TABLES_LIST}
echo "$SQL_LIKE"
if [ -f ${TABLES_LIST} ]; then
    _TABLES=$(awk -v SQL_LIKE=${SQL_LIKE} 'BEGIN{t="";f="^" SQL_LIKE;gsub(/%/,"\\w*",f);}{if (match($0,f)){gsub(/[ \t]*/,"",$0);t=length(t)==0?$0:t "," $0}}END{print t;}' ${TABLES_LIST})
    if [[ -n "$TABLES" ]]; then
        TABLES="${TABLES},${_TABLES}"
    else
        TABLES="$_TABLES"
    fi
fi
}

if [[ -n "$SQL_LIKE" ]]; then
    build_tables
fi

echo $TABLES

if [[ -z "$TABLES" ]]; then
    echo "!-t<tables> or -s<like-filter> is null/empty."
    echo -e $HELP; exit 1
fi

if [[ -n "$SQL_EXCLUDE" ]]; then
    TABLES=$(echo $TABLES | awk -vX=$SQL_EXCLUDE 'BEGIN{gsub(/%/,"\\w*",X);X=X "[,]*";t="";}END{split($0,a,",");for(i in a){if(match(a[i],X)>0)delete a[i];}for(i in a){if(a[i]=="")continue;t=length(t)==0?a[i]:t "," a[i];}print t;}')
    echo $TABLES
fi

exp ${PASSCODE} file=${EXP_FILE} log=${EXP_LOG} tables=${TABLES} ${EXP_OPTS}
