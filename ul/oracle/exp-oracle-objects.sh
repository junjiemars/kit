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
#         a manual exactly. But there is one:
#         where ([-l] or [-n]) and ([-x] not in)
#=====================================================
PASSCODE="${PASSCODE:-xws/xws@localhost:1521/XE}"
EXP_OPTS="${EXP_OPTS:="FEEDBACK=1"}"
EXP_DIR=${EXP_DIR:-$PWD}
EXP_FILE=""
EXP_LOG=""
OBJECT_LIST=""

SQLPLUS_PAGESIZE="${SQLPLUS_PAGESIZE:-0}"
SQLPLUS_LONG="${SQLPLUS_LONG:-90000}"
SQLPLUS_LINESIZE="${SQLPLUS_LINESIZE:-200}"
SQLPLUS_TERMOUT="OFF"

OBJECTS=""
SQL_LIKE=""
SQL_EXCLUDE=""
SQLF=""
SQLQ=""
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
    if [[ -n "$OBJECTS" ]]; then
        echo -e "$OBJECTS" | tr ',' '\n'
    fi
    echo -e "#Exp File:${EXP_FILE}"
    echo -e "#Exp Log:${EXP_LOG}"
    if [ "$DEBUG" -gt 0 ]; then
        echo -e "#SQL:$SQLQ"
    fi
    echo -e "========================================\n"
}

function run_sqlplus() {
##set serveroutput off;
##set termout on;
##SQLPLUS_TERMOUT="ON"
sqlplus ${PASSCODE} <<!
set heading off;
set echo on;
set pages ${SQLPLUS_PAGESIZE};
set long ${SQLPLUS_LONG};
set linesize ${SQLPLUS_LINESIZE};
set trimspool on;
define objects_output='${OBJECT_LIST}';
define sql_like='${SQL_LIKE}';
spool '&objects_output'
$@
spool off
exit
!

}

function build_filter() {
    SQLQ="$@ where ($SQLF like '@L' or $SQLF in (@N)) and (@X);"
    if [[ -n "$OBJECTS" ]]; then
        OBJECTS=$(to_single_quoted $OBJECTS)
    else
        OBJECTS="''"
    fi
    if [[ -n "$SQL_EXCLUDE" ]]; then
        SQL_EXCLUDE=$(to_single_quoted $SQL_EXCLUDE)
        SQL_EXCLUDE="$SQLF not in ($SQL_EXCLUDE)"
    else
        SQL_EXCLUDE="1=1"
    fi
    SQLQ=$(echo $SQLQ|awk -v N="$OBJECTS" -v L="$SQL_LIKE" -v X="$SQL_EXCLUDE" '{gsub("@N",N,$0);gsub("@L",L,$0);gsub("@X",X,$0);print $0}')
}

function to_single_quoted() {
    local _L=$(echo $@|awk 'BEGIN{FS=",";t="";}END{for(i=1;i<=NF;i++){length(t)==0?t="'\''" $i "'\''":t=t ",'\''" $i "'\''";}print t;}')
    echo $_L
}

function to_ddl() {
    if [[ -n "$OBJECT_TYPE" && -f "$OBJECT_LIST" ]]; then
        awk '!/^SQL>/{if (NF > 0)print $0;}' $OBJECT_LIST | awk '!/^no rows/{print $0}' > $EXP_FILE
    fi
}

function describe_objects() {
    build_filter "$@"
    run_sqlplus "$SQLQ"
    if [[ -f "$OBJECT_LIST" ]]; then
        OBJECTS=$(awk '!/^SQL>/{if(NF>0)print $0;}' < $OBJECT_LIST | awk '!/^no rows/{print $0;}')
        if [[ -n "$OBJECTS" ]]; then
            OBJECTS=$(echo $OBJECTS|awk '{gsub(" ",",");print $0;}')
        fi
    fi
}

function exp_tables() {
    SQLF="t.table_name"
    describe_objects "select table_name from user_tables t "
    if [[ -n "$OBJECTS" ]]; then
        EXP_FILE=$(echo $EXP_FILE|awk '{gsub(/.sql/,".dmp",$0);print $0;}')
        exp ${PASSCODE} file=${EXP_FILE} log=${EXP_LOG} tables=${OBJECTS} ${EXP_OPTS}
    fi
    summary "$SQLQ"
}

function exp_table_ddl() {
    SQLF="t.table_name"
    describe_objects "select table_name from user_tables t "
    SQLQ="select dbms_metadata.get_ddl('TABLE', t.table_name) from user_tables t "
    if [[ -n "$OBJECTS" ]]; then
        OBJECTS=$(to_single_quoted $OBJECTS)
        SQLQ="$SQLQ where t.table_name in ($OBJECTS);"
        run_sqlplus $SQLQ
    fi
    to_ddl
    summary "$SQLQ"
}

function exp_procedure_ddl() {
    SQLF="p.object_name"
    describe_objects "select p.object_name from user_procedures p "
    SQLQ="select dbms_metadata.get_ddl('PROCEDURE', p.object_name) from user_procedures p "
    if [[ -n "$OBJECTS" ]]; then
        OBJECTS=$(to_single_quoted $OBJECTS)
        SQLQ="$SQLQ where p.object_name in ($OBJECTS);"
        run_sqlplus $SQLQ
    fi 
    to_ddl
    summary "$SQLQ"
 }

function exp_sequence_ddl() {
    SQLF="s.sequence_name"
    describe_objects "select s.sequence_name from user_sequences s "
    SQLQ="select dbms_metadata.get_ddl('SEQUENCE', s.sequence_name) from user_sequences s "
    if [[ -n "$OBJECTS" ]]; then
        OBJECTS=$(to_single_quoted $OBJECTS)
        SQLQ="$SQLQ where s.sequence_name in ($OBJECTS);"
        run_sqlplus $SQLQ
    fi
    to_ddl
    summary "$SQLQ"
}

function exp_package_ddl() {
    #local _TMP="${EXP_FILE##*/}" #extract filename 
    local _TMP="${EXP_DIR}/.package.sql"
    SQLQ="select a.text from user_source a where a.name='${OBJECTS}' and a.type='PACKAGE' union all select b.text from user_source b where b.name='${OBJECTS}' and b.type='PACKAGE BODY';"
    run_sqlplus $SQLQ
    to_ddl
    summary $SQLQ
    if [[ -f "$EXP_FILE" ]]; then
        if [[ 0 -eq $(cp $EXP_FILE "$_TMP" 2>/dev/null; echo $?) ]]; then
            awk -v X=${OBJECTS} '{gsub("^package ","create or replace package ",$0);gsub(X ";",X ";\n/",$0);gsub("[0-9]+ rows selected.","",$0);print $0;}' < $_TMP > $EXP_FILE
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


