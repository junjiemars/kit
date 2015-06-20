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
#         where ([-s] or [-n]) and ([-x] not in)
#=====================================================
PASSCODE="${PASSCODE:-xws/xws@localhost:1521/XE}"
EXP_OPTS="${EXP_OPTS:="FEEDBACK=1"}"
EXP_DIR=${EXP_DIR:-$PWD}
EXP_FILE=""
EXP_LOG=""
EXP_TMP=""
OBJECT_LIST=""
OBJECT_TYPE="DUMP"

SQLPLUS_PAGESIZE="${SQLPLUS_PAGESIZE:-0}"
SQLPLUS_LONG="${SQLPLUS_LONG:-90000}"
SQLPLUS_LINESIZE="${SQLPLUS_LINESIZE:-200}"
SQLPLUS_TERMOUT="${SQLPLUS_TERMOUT:-off}"
SQLPLUS_SPOOL=""
SQLPLUS_VERIFY="${SQLPLUS_VERIFY:-on}"

OBJECTS=""
SQL_LIKE=""
SQL_EXCLUDE=""
SQLF=""
SQLQ=""
SQL_SCHEME=""
SQL_SPACE=""
SQL_TERMINATOR="true"

DEBUG="${DEBUG:-0}"
HELP="usage:\texp-oracle-tables.sh <options>\n\
options:-h\t\t\thelp\n\
    \t-p<oralce-login>\tusername/password@host:port/sid\n\
    \t[-w<dump-dir>]\t\tdump directory\n\
    \t[-d<ddl-type>]\t\tddl type:one of table,package etc.,\n\
    \t[-n<object>]\t\tobject list, seperate by ','\n\
    \t[-s<sql-like>]\tsql like filter, ABC\%, etc.\n\
    \t[-x<exclude>]\t\texclude objects, seperate by ',' or like '%'\n\
    \t[-u<scheme>]\t\ttrans scheme:<origin-scheme>:<new-scheme>\n\
    \t[-t<tablespace]\t\ttrans tablespace:<origin-tablespace>:<new-tablespace>\n\
    \t[-v<verbose>]"

while getopts "hvd:p:w:n:s:x:u:t:" arg
do
	case ${arg} in
        h) echo -e $HELP; exit 0;;
        v) DEBUG=1;;
        d) OBJECT_TYPE=`echo ${OPTARG}|tr [:lower:] [:upper:]`;;
		p) PASSCODE=${OPTARG};;
		w) EXP_DIR=${OPTARG};;
		n) OBJECTS=`echo ${OPTARG}|tr [:lower:] [:upper:]|sed -e 's/\ *//g'`;;
		s) SQL_LIKE=`echo ${OPTARG}|tr [:lower:] [:upper:]|sed -e 's/\ *//g'`;;
        x) SQL_EXCLUDE=`echo ${OPTARG}|tr [:lower:] [:upper:]|sed -e 's/\ *//g'`;;
        u) SQL_SCHEME=`echo ${OPTARG}|tr [:lower:] [:upper:]|sed -e 's/\ *//g'`;;
        t) SQL_SPACE=`echo ${OPTARG}|tr [:lower:] [:upper:]|sed -e 's/\ *//g'`;;
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
    echo -e "#Exp File(`[[ ! -f ${EXP_FILE} ]];echo $?`):${EXP_FILE}"
    echo -e "#Exp Log(`[[ ! -f ${EXP_LOG} ]];echo $?`):${EXP_LOG}"
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
set longchunksize ${SQLPLUS_LONG};
set linesize ${SQLPLUS_LINESIZE};
set trimspool on;
set verify ${SQLPLUS_VERIFY};
define objects_output="${SQLPLUS_SPOOL}";
define sql_like='${SQL_LIKE}';
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform,'SQLTERMINATOR',${SQL_TERMINATOR});
spool '&objects_output'
$@
spool off
exit
!

}

function log_file() {
    echo -e "========================================" >> $EXP_LOG
    echo -e "#$(date)" >> $EXP_LOG
    echo -e "========================================" >> $EXP_LOG
    cat < $@ >> $EXP_LOG
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

function rm_single_quoted() {
    echo $(echo $OBJECTS | awk '{gsub(/'\''/,"");print $0;}')
}

function to_ddl() {
    if [[ -n "$OBJECT_TYPE" && -f "$EXP_TMP" ]]; then
        log_file $EXP_TMP
        #awk '!/^SQL>/{if (NF > 0)print $0;}' < $EXP_TMP | awk '!/^no rows/{print $0}' > $EXP_FILE
        #awk '{gsub("^SQL>\w*","");gsub("(no|d+) rows\w*","");print $0;}' < $EXP_TMP > $EXP_FILE
        awk 'BEGIN{IGNORECASE=1;}!/^SQL>/{print $0;}' < $EXP_TMP | awk 'BEGIN{IGNORECASE=1;}!/^(no|[0-9]*) rows/{print $0;}' > $EXP_FILE
    fi
}

function trans_scheme() {
    if [[ -n "$SQL_SCHEME" && -f "$EXP_FILE" ]]; then
        if [ 0 -eq $(cp $EXP_FILE $EXP_TMP 2>/dev/null;echo $?) ]; then
            if [ 2 -eq $(echo $SQL_SCHEME | awk 'BEGIN{FS=":";}{print NF;}') ]; then
                awk -v S=$SQL_SCHEME 'BEGIN{split(S,s,":");}{gsub("\"" s[1] "\".","\"" s[2] "\".");print $0;}' < $EXP_TMP > $EXP_FILE
            else 
                echo -e "#![-u<scheme] is wrong."
                echo -e $HELP 
            fi
        fi
    fi
}

function trans_tablespace() {
    if [[ -n "$SQL_SPACE" && -f "$EXP_FILE" ]]; then
        if [ 0 -eq $(cp $EXP_FILE $EXP_TMP 2>/dev/null;echo $?) ]; then
            if [ 2 -eq $(echo $SQL_SPACE | awk 'BEGIN{FS=":";}{print NF;}') ]; then
                awk -v S=$SQL_SPACE 'BEGIN{IGNORECASE=1;split(S,s,":");}{gsub("tablespace \"" s[1] "\"","TABLESPACE \"" s[2] "\"");print $0;}' < $EXP_TMP > $EXP_FILE
            else 
                echo -e "#![-t<tablespace>] is wrong."
                echo -e $HELP 
            fi
        fi
    fi
}
function describe_objects() {
    build_filter "$@"
    SQLPLUS_SPOOL=$OBJECT_LIST run_sqlplus "$SQLQ"
    if [[ -f "$OBJECT_LIST" ]]; then
        log_file $OBJECT_LIST
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
    SQLQ="select dbms_metadata.get_ddl('${OBJECT_TYPE}', t.table_name) || case (select count(*) from user_col_comments c where c.table_name=t.table_name and c.comments is not null) when 0 then empty_clob() else dbms_metadata.get_dependent_ddl('COMMENT',t.table_name) end from user_tables t "
    if [[ -n "$OBJECTS" ]]; then
        OBJECTS=$(to_single_quoted $OBJECTS)
        SQLQ="$SQLQ where t.table_name in ($OBJECTS);"
        SQLPLUS_SPOOL=$EXP_TMP run_sqlplus $SQLQ
        to_ddl
        trans_scheme
        trans_tablespace
    fi
    summary "$SQLQ"
}

function exp_procedure_ddl() {
    SQLF="p.object_name"
    describe_objects "select p.object_name from user_procedures p "
    SQLQ="select dbms_metadata.get_ddl('${OBJECT_TYPE}', p.object_name) from user_procedures p "
    if [[ -n "$OBJECTS" ]]; then
        OBJECTS=$(to_single_quoted $OBJECTS)
        SQLQ="$SQLQ where p.object_name in ($OBJECTS);"
        SQLPLUS_SPOOL=$EXP_TMP run_sqlplus $SQLQ
        to_ddl
        trans_scheme
    fi 
    summary "$SQLQ"
 }

function exp_sequence_ddl() {
    SQLF="s.sequence_name"
    describe_objects "select s.sequence_name from user_sequences s "
    SQLQ="select dbms_metadata.get_ddl('${OBJECT_TYPE}', s.sequence_name) from user_sequences s "
    if [[ -n "$OBJECTS" ]]; then
        OBJECTS=$(to_single_quoted $OBJECTS)
        SQLQ="$SQLQ where s.sequence_name in ($OBJECTS);"
        SQLPLUS_SPOOL=$EXP_TMP run_sqlplus $SQLQ
        to_ddl
        trans_scheme
    fi
    summary "$SQLQ"
}

function exp_package_ddl() {
    #local _TMP="${EXP_FILE##*/}" #extract filename 
    EXP_TMP="${EXP_DIR}/.package.sql"
    SQLQ="select a.text from user_source a where a.name='${OBJECTS}' and a.type='PACKAGE' union all select b.text from user_source b where b.name='${OBJECTS}' and b.type='PACKAGE BODY';"
    SQLPLUS_SPOOL=$EXP_TMP run_sqlplus $SQLQ
    to_ddl
    summary $SQLQ
    if [[ -f "$EXP_FILE" ]]; then
        log_file $EXP_FILE
        if [ 0 -eq $(cp $EXP_FILE "$EXP_TMP" 2>/dev/null;echo $?) ]; then
            awk -v X="end ${OBJECTS};" 'BEGIN{IGNORECASE=1;}{gsub("^package ","create or replace package ",$0);gsub(X,X "\n/");gsub("[0-9]+ rows selected.","");print $0;}' < $EXP_TMP > $EXP_FILE
        fi
    fi
}

TODAY=`date +%Y-%m-%d`
EXP_FILE="${EXP_FILE:-${EXP_DIR}/exp-${OBJECT_TYPE}-${TODAY}.sql}";
EXP_LOG="${EXP_LOG:-${EXP_DIR}/exp-${OBJECT_TYPE}-${TODAY}.log}";
EXP_TMP="${EXP_DIR}/.$(echo ${OBJECT_TYPE}|awk '{print tolower($0);}').sql"
OBJECT_LIST="${OBJECT_LIST:-${EXP_DIR}/.object.list}"
spec

echo -e "EXP_DIR:$EXP_DIR "
echo -e "EXP_FILE:$EXP_FILE "

case ".$OBJECT_TYPE" in
    .) echo -e $HELP;;
    .DUMP) exp_tables;;
    .TABLE) exp_table_ddl;;
    .PROCEDURE) exp_procedure_ddl;;
    .FUNCTION) exp_procedure_ddl;;
    .SEQUENCE) exp_sequence_ddl;;
    .PACKAGE) exp_package_ddl;;
    .CLEAN) 
        if [ "$DEBUG" -gt 0 ]; then 
            rm *.sql *.log *.dmp .*.sql .*.list 
        fi
        ;;
    *) echo -e "fin(o)n(0)y";echo -e $HELP;;
esac


