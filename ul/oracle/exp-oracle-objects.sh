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
OBJECT_TYPE="DUMP"

DEBUG="${DEBUG:-0}"
HELP="usage:\texp-oracle-tables.sh <options>\n\
options:-h\t\t\thelp\n\
    \t-p<username/password>\toracle's login\n\
    \t[-w<dump-dir>]\t\tdump directory\n\
    \t[-t<ddl-type>]\t\tddl type:one of table,procedure,sequence,package\n\
    \t-n<object>\t\tobject list, seperate by ','\n\
    \t-l<like-filter>\t\tlike filter, ABC\%, etc.\n\
    \t[-x<exclude>]\t\texclude objects, seperate by ',' or like '%'"

while getopts "hdt:p:w:n:l:x:" arg
do
	case ${arg} in
        h) echo -e $HELP; exit 0;;
        d) DEBUG=1;;
        t) OBJECT_TYPE=`echo ${OPTARG}|tr [:lower:] [:upper:]`;;
		p) PASSCODE=${OPTARG};;
		w) EXP_DIR=${OPTARG};;
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
set serveroutput off;
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

function build_object_list(){
    local _OBJ=""
    if [[ -n "$SQL_LIKE" ]]; then
        run_sqlplus $@
        if [ -f ${OBJECT_LIST} ]; then
            _OBJ=$(awk -v SQL_LIKE=${SQL_LIKE} 'BEGIN{t="";f="^" SQL_LIKE;gsub(/%/,"\\w*",f);}{if (match($0,f)){gsub(/[ \t]*/,"",$0);t=length(t)==0?$0:t "," $0}}END{print t;}' ${OBJECT_LIST})
        fi
    fi
    
    if [[ -n "$OBJECTS" ]]; then
        _OBJ="${OBJECTS},${_OBJ}"
    fi

    if [[ -n "$SQL_EXCLUDE" ]]; then
        _OBJ=$(echo $_OBJ | awk -v X=$SQL_EXCLUDE 'BEGIN{gsub(/%/,"\\w*",X);gsub(/,/,"$|",X);X=X "$";t="";}END{split($0,a,",");for(i in a){if(match(a[i],X)>0)delete a[i];}for(i in a){if(a[i]=="")continue;t=length(t)==0?a[i]:t "," a[i];}print t;}')
    fi
    OBJECTS=$_OBJ
}

function exp_tables() {
    local _SQL="select table_name from user_tables where table_name like '&sql_like';"
    build_object_list $_SQL
    summary $_SQL
    
    EXP_FILE=$(echo $EXP_FILE|awk '{gsub(/.sql/,".dmp",$0);print $0;}')
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

function exp_package_ddl() {
    local _SQL="select a.text from user_source a where a.name='${OBJECTS}' and a.type='PACKAGE' union all select b.text from user_source b where b.name='${OBJECTS}' and b.type='PACKAGE BODY';"
    #local _TMP="${EXP_FILE##*/}" #extract filename 
    local _TMP="${EXP_DIR}/.package.sql"
    summary $_SQL
    run_sqlplus $_SQL
    to_ddl
    if [[ -f "$EXP_FILE" ]]; then
        if [[ 0 -eq $(cp $EXP_FILE "$_TMP" 2>/dev/null; echo $?) ]]; then
            awk -v X=${OBJECTS} '{gsub(X ";",X ";/",$0);gsub("[0-9]+ rows selected.","",$0);print $0;}' < $_TMP > $EXP_FILE
        fi
    fi
}

TODAY=`date +%Y-%m-%d`
EXP_FILE="${EXP_FILE:-${EXP_DIR}/exp-${OBJECT_TYPE}-${TODAY}.sql}";
EXP_LOG="${EXP_LOG:-${EXP_DIR}/exp-${OBJECT_TYPE}-${TODAY}.log}";
OBJECT_LIST="${OBJECT_LIST:-${EXP_DIR}/.object.list}"
spec

echo -e "EXP_DIR:$EXP_DIR "
echo -e "EXP_FILE:$EXP_FILE "
case ".$OBJECT_TYPE" in
    .) echo -e $HELP;;
    .DUMP) exp_tables;;
    .TABLE) exp_table_ddl;;
    .PROCEDURE) exp_procedure_ddl;;
    .SEQUENCE) exp_sequence_ddl;;
    .PACKAGE) exp_package_ddl;;
    *) echo -e "fin(o)n(0)y";echo -e $HELP;;
esac


