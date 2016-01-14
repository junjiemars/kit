#!/bin/bash
#=====================================================
# Author: https://github.com/junjiemars
# Git: git clone https://github.com/junjiemars/kit.git
#=====================================================
# NOTE:
# If u want to export all objects owned by u
# just run oracle command: exp user/passwd owner=user 
# This script just help u to export the objects
# what ur want exactly.
#====================================================
# MANUAL: The best advice: Don't use it if u need 
#         a manual exactly. But there is one:
#         where ([-s] or [-n]) and ([-x] not in)
#=====================================================

CMD_EXP=exp.sh
CMD_SQLPLUS=sqlplus.sh
PASSCODE=${PASSCODE:-'hr/hr@localhost:1521/XE'}
EXP_OPTS=${EXP_OPTS:='FEEDBACK=1'}
EXP_DIR=${EXP_DIR:-$PWD}
EXP_FILE=${EXP_FILE}
EXP_LOG=${EXP_LOG}
EXP_TMP=""
OBJECT_LIST=""
OBJECT_TYPE="DUMP"
IN_SQL_FILE=""

SQLPLUS_HEADING=${SQLPLUS_HEADING:-off}
SQLPLUS_COLSEP=${SQLPLUS_COLSEP:-" "}
SQLPLUS_ECHO=${SQLPLUS_ECHO:-off}
SQLPLUS_PAGESIZE=${SQLPLUS_PAGESIZE:-0}
SQLPLUS_LONG=${SQLPLUS_LONG:-90000}
SQLPLUS_LINESIZE=${SQLPLUS_LINESIZE:-200}
SQLPLUS_TERMOUT=${SQLPLUS_TERMOUT:-off}
SQLPLUS_TRIMSPOOL=${SQLPLUS_TRIMSPOOL:-on}
SQLPLUS_SPOOL=""
SQLPLUS_VERIFY=${SQLPLUS_VERIFY:-off}
SQLPLUS_SERVEROUTPUT=${SQLPLUS_SERVEROUTPUT:-off}

SPOOL_HEAD='^select '
SPOOL_TAIL='^spool off'

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
options:\n
    \t[-h]\t\t\thelp\n\
    \t[-p<oralce-login>]\tusername/password@host:port/sid\n\
    \t[-w<dump-dir>]\t\tdump directory\n\
    \t[-d<ddl-type>]\t\tddl type:one of table,package etc.,\n\
    \t[-n<object>]\t\tobject list, seperate by ','\n\
    \t[-s<sql-like>]\t\tsql like filter, ABC\%, etc.\n\
    \t[-x<exclude>]\t\texclude objects, seperate by ',' or like '%'\n\
    \t[-u<scheme>]\t\ttrans scheme:<origin-scheme>:<new-scheme>\n\
    \t[-t<tablespace]\t\ttrans tablespace:<origin-tablespace>:<new-tablespace>\n\
    \t[-f<sql-file]\n\
    \t[-v<verbose>]"

while getopts "hvd:p:w:n:s:x:u:t:f:" arg
do
	case ${arg} in
        h) echo -e $HELP; exit 0;;
        v) DEBUG=1;;
        d) OBJECT_TYPE=`echo ${OPTARG}|tr [:lower:] [:upper:]`;;
    	p) PASSCODE=${OPTARG};;
    	w) EXP_DIR=${OPTARG%/};;
    	n) OBJECTS=`echo ${OPTARG}|tr '[:lower:]' '[:upper:]'|sed -e 's/\ *//g'`;;
    	s) SQL_LIKE=`echo ${OPTARG}|tr '[:lower:]' '[:upper:]'|sed -e 's/\ *//g'`;;
        x) SQL_EXCLUDE=`echo ${OPTARG}|tr '[:lower:]' '[:upper:]'|sed -e 's/\ *//g'`;;
        u) SQL_SCHEME=`echo ${OPTARG}|tr '[:lower:]' '[:upper:]'|sed -e 's/\ *//g'`;;
        t) SQL_SPACE=`echo ${OPTARG}|tr '[:lower:]' '[:upper:]'|sed -e 's/\ *//g'`;;
        f) IN_SQL_FILE=${OPTARG};;
        *) echo -e $HELP; exit 1;;
	esac
done
shift $(($OPTIND - 1))
SQLQ="$*"

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
    echo -e "#${OBJECT_TYPE}(`echo ${OBJECTS}|awk 'BEGIN{FS=","}{print NF;}'`): ${OBJECTS}"
    if [[ -n "$OBJECTS" ]]; then
        echo -e "$OBJECTS" | tr ',' '\n'
    fi
    echo -e "#Exp File(`[[ ! -f ${EXP_FILE} ]];echo $?`): ${EXP_FILE}"
    echo -e "#Exp Log(`[[ ! -f ${EXP_LOG} ]];echo $?`): ${EXP_LOG}"
    if [ "$DEBUG" -gt 0 ]; then
        echo -e "#SQL: $SQLQ"
    fi
    echo -e "========================================\n"
}

function run_sqlplus() {
export NLS_LANG=${NLS_LANG:-"AMERICAN_AMERICA.UTF8"}
##set termout on;
##SQLPLUS_TERMOUT="ON"
${CMD_SQLPLUS} ${PASSCODE} <<!
set sqlprompt '';
set feedback off;
set termout off;
set heading ${SQLPLUS_HEADING};
set echo ${SQLPLUS_ECHO};
set colsep ${SQLPLUS_COLSEP};
set pages ${SQLPLUS_PAGESIZE};
set long ${SQLPLUS_LONG};
set longchunksize ${SQLPLUS_LONG};
set linesize ${SQLPLUS_LINESIZE};
set trimspool ${SQLPLUS_TRIMSPOOL};
set verify ${SQLPLUS_VERIFY};
set serveroutput ${SQLPLUS_SERVEROUTPUT};
col source_code format a${SQLPLUS_LINESIZE} WORD_WRAPPED;
define objects_output="${SQLPLUS_SPOOL}";
define sql_exec="${SQLQ}";
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

function to_comma_seperated() {
    local _L=$(echo $@ | awk '{gsub(" |\n",",");print $0;}')
    echo $_L
}

function to_single_quoted() {
    local _L=$(echo $@|awk 'BEGIN{FS=",";t="";}END{for(i=1;i<=NF;i++){length(t)==0?t="'\''" $i "'\''":t=t ",'\''" $i "'\''";}print t;}')
    echo $_L
}

function rm_single_quoted() {
    echo $(echo $OBJECTS | awk '{gsub(/'\''/,"");print $0;}')
}

function replace_file_ext() {
    if [[ 2 -eq $# ]]; then
        echo $(echo "${EXP_FILE}" \
            | awk -v S=$1 -v D=$2 '{gsub(S,D);print $0;}')
    fi
}

function spool_to_object() {
    if [[ 4 -eq $# ]] && [[ -f "${3}" ]]; then
        awk -v H="${1}" 'BEGIN{IGNORECASE=1;}{if ($0 !~ H) print $0;}' "${3}" \
            | awk -v T="${2}" 'BEGIN{IGNORECASE=1;}{if ($0 !~ T) print $0;}' \
            > "${4}"
    fi
}

function to_ddl() {
    if [[ -n "$OBJECT_TYPE" && -f "$EXP_TMP" ]]; then
        log_file $EXP_TMP
        spool_to_object "${SPOOL_HEAD}" "${SPOOL_TAIL}" "${EXP_TMP}" "${EXP_FILE}"
    fi
}

function to_csv() {
    EXP_FILE=$(replace_file_ext ".sql" ".csv")
    SPOOL_HEAD=";"
    spool_to_object "${SPOOL_HEAD}" "${SPOOL_TAIL}" "${EXP_TMP}" "${EXP_FILE}"
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
    if [[ -n "$IN_SQL_FILE" ]]; then
        OBJECTS=$(cat $IN_SQL_FILE)
        OBJECTS=$(to_comma_seperated $OBJECTS)
    else
        build_filter "$@"
        SQLPLUS_SPOOL=$OBJECT_LIST run_sqlplus $SQLQ
        if [[ -f ${OBJECT_LIST} ]]; then
            log_file $OBJECT_LIST
            OBJECTS=$(awk '!/;/{print $0;}' < $OBJECT_LIST | awk '!/^spool off/{print $0;}')
            if [[ -n ${OBJECTS} ]]; then
                OBJECTS=$(to_comma_seperated $OBJECTS)
            fi
        fi
    fi
}

function exp_tables() {
    SQLF="t.table_name"
    describe_objects "select table_name from user_tables t "
    if [[ -n "$OBJECTS" ]]; then
        EXP_FILE=$(replace_file_ext ".sql" ".dmp")
        ${CMD_EXP} ${PASSCODE} file=${EXP_FILE} log=${EXP_LOG} tables="${OBJECTS}" ${EXP_OPTS}
    fi
    summary "$SQLQ" 
}

function exp_csv() {
    SQLPLUS_COLSEP=, 
    SQLPLUS_HEADING=on 
    OBJECTS="export-to-csv"
    if [[ -z "${SQLQ}" ]] && [[ -f "${IN_SQL_FILE}" ]]; then
        SQLQ="$(cat $IN_SQL_FILE)"
    fi
    SQLPLUS_SPOOL="${EXP_TMP}" run_sqlplus "${SQLQ}"
    to_csv
    summary "${SQLQ}"
}

function exp_table_ddl() {
    SQLF="t.table_name"
    describe_objects "select ${SQLF} from user_tables t "
    SQLQ="select dbms_metadata.get_ddl('${OBJECT_TYPE}', ${SQLF}) || case (select count(*) as source_code from user_col_comments c where c.table_name=${SQLF} and c.comments is not null) when 0 then empty_clob() else dbms_metadata.get_dependent_ddl('COMMENT',${SQLF}) end from user_tables t "
    if [[ -n "$OBJECTS" ]]; then
        OBJECTS=$(to_single_quoted $OBJECTS)
        SQLQ="$SQLQ where ${SQLF} in ($OBJECTS);"
        SQLPLUS_SPOOL=$EXP_TMP run_sqlplus "${SQLQ}"
        to_ddl
        trans_scheme
        trans_tablespace
    fi
    summary "$SQLQ"
}

function exp_procedure_ddl() {
    SQLF="p.object_name"
    describe_objects "select ${SQLF} from (select t.object_name \
        from user_procedures t \
        where t.procedure_name is null and t.object_type='${OBJECT_TYPE}') p "
    SQLQ="select dbms_metadata.get_ddl('${OBJECT_TYPE}', ${SQLF}) as source_code from user_procedures p "
    if [[ -n "$OBJECTS" ]]; then
        OBJECTS=$(to_single_quoted $OBJECTS)
        SQLQ="$SQLQ where (${SQLF} in ($OBJECTS));"
        SQLPLUS_SPOOL=$EXP_TMP run_sqlplus $SQLQ
        to_ddl
        trans_scheme
    fi
    summary "$SQLQ"
}

function exp_type_ddl() {
    SQLF="p.type_name"
    describe_objects "select ${SQLF} from (select t.type_name from user_types t ) p "
    SQLQ="select dbms_metadata.get_ddl('${OBJECT_TYPE}', ${SQLF}) as source_code from user_types p "
    if [[ -n "$OBJECTS" ]]; then
        OBJECTS=$(to_single_quoted $OBJECTS)
        SQLQ="$SQLQ where (${SQLF} in ($OBJECTS));"
        SQLPLUS_SPOOL=$EXP_TMP run_sqlplus $SQLQ
        to_ddl
        trans_scheme
    fi
    summary "$SQLQ"
}


function exp_sequence_ddl() {
    SQLF="s.sequence_name"
    describe_objects "select ${SQLF} from user_sequences s "
    SQLQ="select dbms_metadata.get_ddl('${OBJECT_TYPE}', ${SQLF}) as source_code from user_sequences s "
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

function exp_dblink_ddl() {
    SQLF="l.db_link"
    describe_objects "select l.db_link from user_db_links l"
    SQLQ="select dbms_metadata.get_ddl('${OBJECT_TYPE}', ${SQLF}) as source_code from user_db_links l "
    if [[ -n "$OBJECTS" ]]; then
        OBJECTS=$(to_single_quoted $OBJECTS)
        SQLQ="$SQLQ where l.db_link in ($OBJECTS);"
        SQLPLUS_SPOOL=$EXP_TMP run_sqlplus $SQLQ
        to_ddl
        trans_scheme
    fi
    summary "$SQLQ"
}

function exp_scheduler_ddl() { 
    SQLF="s.job_name"
    describe_objects "select s.job_name from user_scheduler_jobs s"
    SQLQ="select dbms_metadata.get_ddl('${OBJECT_TYPE}', ${SQLF}) from user_scheduler_jobs s "
    if [[ -n "$OBJECTS" ]]; then
        OBJECTS=$(to_single_quoted $OBJECTS)
        SQLQ="$SQLQ where ${SQLF} in ($OBJECTS);"
        SQLPLUS_SPOOL=$EXP_TMP run_sqlplus $SQLQ
        to_ddl
        trans_scheme
    fi
    summary "$SQLQ"
}

function exp_job_ddl() {
    SQLF="j.job"
    describe_objects "select j.job from user_jobs j"
    if [[ -n "$OBJECTS" ]]; then
        OBJECTS=$(to_single_quoted $OBJECTS)
        SQLQ="declare job_txt varchar2(4000);begin for c in (select job from user_jobs j where j.job in ($OBJECTS)) loop dbms_job.user_export(c.job,job_txt);dbms_output.put_line(job_txt);end loop;end;\n/"
        SQLPLUS_SPOOL=$EXP_TMP SQLPLUS_SERVEROUTPUT="on" run_sqlplus $SQLQ
        to_ddl
        trans_scheme
    fi
    summary "$SQLQ"
}

function exp_view_ddl() {
    SQLF="v.view_name"
    describe_objects "select v.view_name from user_views v"
    SQLQ="select dbms_metadata.get_ddl('${OBJECT_TYPE}',${SQLF}) as source_code from user_views v "
    if [[ -n "$OBJECTS" ]]; then
        OBJECTS=$(to_single_quoted $OBJECTS)
        SQLQ="$SQLQ where ${SQLF} in ($OBJECTS);"
        SQLPLUS_SPOOL=$EXP_TMP run_sqlplus $SQLQ
        to_ddl
        trans_scheme
    fi
    summary "$SQLQ"
}

function trans_sql_file() {
    if [[ -f "${IN_SQL_FILE}" ]]; then
        EXP_FILE=$IN_SQL_FILE trans_scheme
        EXP_FILE=$IN_SQL_FILE trans_tablespace
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
    .CSV) exp_csv;;
    .TABLE) exp_table_ddl;;
    .PROCEDURE) exp_procedure_ddl;;
    .FUNCTION) exp_procedure_ddl;;
    .TRIGGER) exp_procedure_ddl;;
    .TYPE) exp_type_ddl;;
    .SEQUENCE) exp_sequence_ddl;;
    .PACKAGE) exp_package_ddl;;
    .DB_LINK) exp_dblink_ddl;;
    .SCHEDULER) OBJECT_TYPE="PROCOBJ" exp_scheduler_ddl;;
    .JOB) exp_job_ddl;;
    .VIEW) exp_view_ddl;;
    .SQLFILE) trans_sql_file;;
    .CLEAN) 
        if [ "$DEBUG" -gt 0 ]; then 
            rm *.sql *.log *.dmp .*.sql .*.list 
        fi
        ;;
    .DEBUG) SQLF="t.table_name" build_filter "select table_name from user_tables t ";;
    *) echo -e "fin(o)n(0)y";echo -e $HELP;;
esac


