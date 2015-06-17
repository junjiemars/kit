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
#         a manual exactly.
#=====================================================
PASSCODE="${PASSCODE:-xws/xws@localhost:1521/XE}"
EXP_DIR=${EXP_DIR:-$PWD}
TODAY=`date +%Y-%m-%d`
EXP_FILE=""
EXP_LOG=""
EXP_OPTS="${EXP_OPTS:="FEEDBACK=1"}"
OBJECT_LIST=""

SQLPLUS_PAGESIZE="${SQLPLUS_PAGESIZE:-0}"
SQLPLUS_LONG="${SQLPLUS_LONG:-90000}"
SQLPLUS_LINESIZE="${SQLPLUS_LINESIZE:-80}"
SQLPLUS_TERMOUT="${SQLPLUS_TERMOUT:-ON}"

OBJECTS=""
SQL_LIKE=""
SQL_EXCLUDE=""
SQL_DDL_NAME=""
OBJECT_TYPE=""

DEBUG="${DEBUG:-0}"
HELP="usage:\texp-oracle-tables.sh <options>\n\
options:-h\t\t\thelp\n\
    \t-p<username/password>\toracle's login\n\
    \t[-w<dump-dir>]\t\tdump directory\n\
    \t[-t<ddl-type>]\t\tddl type:one of table,procedure,sequence\n\
    \t-n<object>\t\tobject list, seperate by ','\n\
    \t-l<like-filter>\t\tlike filter, ABC\%, etc.\n\
    \t[-x<excluded>]\t\texcluded tables, seperate by ',' or like '%'"

while getopts "hdt:p:wn:l:x:" arg
do
	case ${arg} in
        h) echo -e $HELP; exit 0;;
        d) DEBUG=1;;
        t) OBJECT_TYPE=`echo ${OPTARG}|tr [:lower:] [:upper:]`;;
		p) PASSCODE=${OPTARG};;
		w) EXP_DIR=${OPTARG:-$PWD};;
		n) OBJECTS=`echo ${OPTARG}|tr [:lower:] [:upper:]|sed -e's/\ *'//g`;;
		l) SQL_LIKE=`echo ${OPTARG}|tr [:lower:] [:upper:]|sed -e's/\ *'//g`;;
        x) SQL_EXCLUDE=`echo ${OPTARG}|tr [:lower:] [:upper:]|sed -e's/\ *'//g`;;
        *) echo -e $HELP; exit 1;;
	esac
done

function spec() {
    local _TYPE=""
    if [[ -z "$OBJECT_TYPE" ]]; then
        _TYPE="TABLE<DUMP>"
    else
        _TYPE="$OBJECT_TYPE<DDL>"
    fi
    echo -e "=SPEC==================================="
    echo -e "#Object Type:${_TYPE}"
    echo -e "#Included Objects:${OBJECTS}"
    echo -e "#Objects Filter:${SQL_LIKE}"
    echo -e "#eXclude Objects/Filter:${SQL_EXCLUDE}"
    echo -e "========================================"
}

function summary() {
    echo -e "\n=SUMMARY:==============================="
    echo -e "#${OBJECT_TYPE}(`echo ${OBJECTS}|awk 'BEGIN{FS=","}{print NF;}'`):${OBJECTS}"
    echo -e "$OBJECTS" | tr ',' '\n'
    echo -e "#Exp File:${EXP_FILE}"
    echo -e "#Exp Log:${EXP_LOG}"
    if [ "$DEBUG" -gt 0 ]; then
        echo -e "#SQL:$@"
    fi
    echo -e "========================================\n"
}

function run_sqlplus() {
if [ "$DEBUG" -gt 0 ];then
    SQLPLUS_TERMOUT="ON"
else
    SQLPLUS_TERMOUT="OFF"
fi

sqlplus ${PASSCODE} <<!
set termout ${SQLPLUS_TERMOUT};
set heading off;
set echo off;
set pages ${SQLPLUS_PAGESIZE};
set long ${SQLPLUS_LONG};
set linesize ${SQLPLUS_LINESIZE};
define objects_output='${OBJECT_LIST}';
define sql_like='${SQL_LIKE}';
spool '&objects_output'
$@
spool off
exit
!

}

function exp_tables() {
    local _OBJ=""
    if [[ -n "$SQL_LIKE" ]]; then
        run_sqlplus "select table_name from user_tables where table_name like '&sql_like';"
        if [ -f ${OBJECT_LIST} ]; then
            _OBJ=$(awk -v SQL_LIKE=${SQL_LIKE} 'BEGIN{t="";f="^" SQL_LIKE;gsub(/%/,"\\w*",f);}{if (match($0,f)){gsub(/[ \t]*/,"",$0);t=length(t)==0?$0:t "," $0}}END{print t;}' ${OBJECT_LIST})
            echo -e "XXX: $_OBJ"
            if [[ -n "$OBJECTS" ]]; then
                OBJECTS="${OBJECTS},${_OBJ}"
            else
                OBJECTS="$_OBJ"
            fi
        fi
    fi
    
    echo -e "ZYX:$OBJECTS"
    echo -e "_OBJ:$_OBJ"
    if [[ -z "$OBJECTS" ]]; then
        if [[ "$DEBUG" -gt 0 ]]; then
            echo -e "========================================"
            echo -e "#!'<\$OBJECTS>' is zero"
            echo -e "========================================"
        fi 
        echo -e $HELP; exit 1
    fi
    
    if [[ -n "$SQL_EXCLUDE" ]]; then
        echo -e "eXclude:$OBJECTS|x:$SQL_EXCLUDE "
        OBJECTS=$(echo $OBJECTS | awk -v X=$SQL_EXCLUDE 'BEGIN{gsub(/%/,"\\w*",X);gsub(/,/,"$|",X);X=X "$";t="";}END{print "(x):" X;split($0,a,",");for(i in a){if(match(a[i],X)>0)delete a[i];}for(i in a){if(a[i]=="")continue;t=length(t)==0?a[i]:t "," a[i];}print t;}')

        echo -e "eXclude:$OBJECTS"
    fi
    summary
    
    if [[ -n "$OBJECTS" ]]; then
        exp ${PASSCODE} file=${EXP_FILE} log=${EXP_LOG} tables=${OBJECTS} ${EXP_OPTS}
    fi
}

function to_single_quoted() {
    local _L=$(echo $@|awk 'BEGIN{FS=",";t="";}END{for(i=1;i<=NF;i++){length(t)==0?t="'\''" $i "'\''":t=t ",'\''" $i "'\''";}print t;}')
    echo $_L
}

function to_exclude_ddl() {
    local _X=$@
    if [[ -n "$SQL_EXCLUDE" ]]; then
        OBJECTS=$(to_single_quoted $SQL_EXCLUDE)
        _X=$(echo $_X|awk -v X=$OBJECTS -v Y=$SQL_DDL_NAME 'END{if(match($0,/;/)>0){gsub(/;/,"",$0);printf "%s and (%s not in (%s));",$0,Y,X}}')
    fi
    echo $_X
}

function to_ddl() {
    if [[ -n "$OBJECT_TYPE" && -f "$OBJECT_LIST" ]]; then
        EXP_FILE=$(echo $EXP_FILE|awk '{gsub(/.dmp/,".sql",$0);print $0;}')
        awk '!/SQL>/{print $0;}' $OBJECT_LIST > $EXP_FILE
    fi
}

function exp_procedure_ddl() {
    local _SQL="select dbms_metadata.get_ddl('PROCEDURE', d.object_name) from user_procedures d"
    if [[ -n "$SQL_LIKE" ]]; then
        _SQL="${_SQL} where d.object_name like '${SQL_LIKE}';"
    elif [[ -n "$OBJECTS" ]]; then
        OBJECTS=$(to_single_quoted $OBJECTS)
        _SQL="${_SQL} where d.object_name in (${OBJECTS});"
    else
        echo -e $HELP
        exit 1
    fi
    SQL_DDL_NAME="d.object_name"
    _SQL=$(to_exclude_ddl $_SQL)
    summary $_SQL
    run_sqlplus ${_SQL}
    to_ddl
}

function exp_sequence_ddl() {
    local _SQL="select dbms_metadata.get_ddl('SEQUENCE', s.sequence_name) from user_sequences s "
    if [[ -n "$SQL_LIKE" ]]; then
        _SQL="${_SQL} where s.sequence_name like '${SQL_LIKE}';"
    elif [[ -n "$OBJECTS" ]]; then
        OBJECTS=$(to_single_quoted $OBJECTS)
        _SQL="${_SQL} where s.sequence_name in (${OBJECTS});"
    else
        echo -e $HELP
        exit 1
    fi
    SQL_DDL_NAME="s.sequence_name"
    _SQL=$(to_exclude_ddl $_SQL)
    summary $_SQL
    run_sqlplus ${_SQL}
    to_ddl
}

function exp_table_ddl() {
    local _SQL="select dbms_metadata.get_ddl('TABLE', d.table_name) from user_tables d "
    if [[ -n "$SQL_LIKE" ]]; then
        _SQL="${_SQL} where d.table_name like '${SQL_LIKE}';"
    elif [[ -n "$OBJECTS" ]]; then
        OBJECTS=$(to_single_quoted $OBJECTS)
        _SQL="${_SQL} where d.table_name in (${OBJECTS});"
    else
        echo -e $HELP
        exit 1
    fi
    SQL_DDL_NAME="d.table_name"
    _SQL=$(to_exclude_ddl $_SQL)
    summary $_SQL
    run_sqlplus ${_SQL}
    to_ddl
}

EXP_FILE="${EXP_FILE:-${EXP_DIR}/exp-${TODAY}.dmp}"
EXP_LOG="${EXP_LOG:-${EXP_DIR}/exp-${TODAY}.log}"
OBJECT_LIST="${OBJECT_LIST:-${EXP_DIR}/object.list}"
spec

case ".$OBJECT_TYPE" in
    .) exp_tables;;
    .TABLE) exp_table_ddl;;
    .PROCEDURE) exp_procedure_ddl;;
    .SEQUENCE) exp_sequence_ddl;;
    *)to_single_quoted "A,B,C";;
esac


