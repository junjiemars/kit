#!/bin/bash
#=====================================================
# Author: https://github.com/junjiemars
# Git: git clone https://github.com/junjiemars/kit.git
#=====================================================
# NOTE:
# If u want to export all objects owned by u
# just run: exp user/passwd owner=user 
# This script just help u to export the objects
# piece by piece.
#=====================================================
# MANUAL: The best advice: Don't use it if u need 
#         a manual really.
#=====================================================
PASSCODE="${PASSCODE:-xws/xws@localhost:1521/XE}"
EXP_DIR=${EXP_DIR:-$PWD}
TODAY=`date +%Y-%m-%d`
EXP_FILE="${EXP_FILE:-${EXP_DIR}/exp-${TODAY}.dmp}"
EXP_LOG="${EXP_LOG:-${EXP_DIR}/exp-${TODAY}.log}"
OBJECTS=""
SQL_LIKE=""
SQL_EXCLUDE=""
EXP_OPTS="${EXP_OPTS:="FEEDBACK=1"}"
OBJECT_LIST="${EXP_DIR}/object.list"
SQLPLUS_PAGES=1000
SQLPLUS_LONG=90000

DEBUG=0
HELP="usage:\texp-oracle-tables.sh <options>\n\
options:-h\t\t\thelp\n\
    \t-p<username/password>\toracle's login\n\
    \t[-w<dump-dir>]\t\tdump directory\n\
    \t-n<object>\t\tobject list, seperate by ','\n\
    \t-l<like-filter>\t\tlike filter, ABC\%, etc.\n\
    \t[-x<excluded>]\t\texcluded tables, seperate by ',' or like '%'"

while getopts "hdp:wn:l:x:" arg
do
	case ${arg} in
        h) echo -e $HELP; exit 0;;
        d) DEBUG=1;;
		p) PASSCODE=${OPTARG};;
		w) EXP_DIR=${OPTARG};;
		n) OBJECTS=`echo ${OPTARG}|tr [:lower:] [:upper:]`;;
		l) SQL_LIKE=`echo ${OPTARG}|tr [:lower:] [:upper:]`;;
        x) SQL_EXCLUDE=`echo ${OPTARG}|tr [:lower:] [:upper:]`;;
        *) echo -e $HELP; exit 1;;
	esac
done

echo -e "========================================"
echo -e "#Included Objects:${OBJECTS}"
echo -e "#Objects Filter:${SQL_LIKE}"
echo -e "#eXclude Objects/Filter:${SQL_EXCLUDE}"
echo -e "========================================"

function run_sqlplus() {
sqlplus ${PASSCODE} <<!
set heading off;
set echo off;
set pages ${SQLPLUS_PAGES}
set long ${SQLPLUS_LONG};
define objects_output='${OBJECT_LIST}';
define sql_like='${SQL_LIKE}';
spool '&objects_output'
$1
spool off
exit
!

#define sql_exclude='${SQL_EXCLUDE}';
#select table_name from user_tables where table_name like '&sql_like';
}

if [[ -n "$SQL_LIKE" ]]; then
    run_sqlplus "select table_name from user_tables where table_name like '&sql_like';"
    if [ -f ${OBJECT_LIST} ]; then
        _TABLES=$(awk -v SQL_LIKE=${SQL_LIKE} 'BEGIN{t="";f="^" SQL_LIKE;gsub(/%/,"\\w*",f);}{if (match($0,f)){gsub(/[ \t]*/,"",$0);t=length(t)==0?$0:t "," $0}}END{print t;}' ${OBJECT_LIST})
        if [[ -n "$OBJECTS" ]]; then
            OBJECTS="${OBJECTS},${_TABLES}"
        else
            OBJECTS="$_TABLES"
    fi
fi

fi

if [[ -z "$OBJECTS" ]]; then
    echo -e "========================================"
    echo "!-n<object> or -l<like-filter> is empty."
    echo -e "========================================"
    echo -e $HELP; exit 1
fi

if [[ -n "$SQL_EXCLUDE" ]]; then
    OBJECTS=$(echo $OBJECTS | awk -v X=$SQL_EXCLUDE 'BEGIN{gsub(/%/,"\\w*",X);gsub(/,/,"|",X);X=X "[,]*";t="";}END{split($0,a,",");for(i in a){if(match(a[i],X)>0)delete a[i];}for(i in a){if(a[i]=="")continue;t=length(t)==0?a[i]:t "," a[i];}print t;}')
fi

echo -e "\n#Objects(`echo ${OBJECTS}|awk 'BEGIN{FS=","}{print NF;}'`):${OBJECTS}"
echo -e "$OBJECTS" | tr ',' '\n'

if [[ -n "$OBJECTS" ]]; then
    exp ${PASSCODE} file=${EXP_FILE} log=${EXP_LOG} tables=${OBJECTS} ${EXP_OPTS}
fi
