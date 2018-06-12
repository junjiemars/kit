#!/bin/bash
#------------------------------------------------
# author: junjiemars@gmail.com
# dependent: sqlplus.sh
# target: SQL*Plus Kits
# note: check oracle working correctly
#------------------------------------------------

TRY_N=${TRY_N:-6}
ORACLE_UID=${ORACLE_UID}
SLEEP_SECONDS=${SLEEP_SECONDS:-10}
SQLPLUS_SH=${SQLPLUS_SH}

for N in `seq 1 ${TRY_N}`; do
  echo -e "whenever sqlerror exit sql.sqlcode\nselect 1+2 from dual;" | \
    ${SQLPLUS_SH} --verbose --oracle-uid=${ORACLE_UID} \
    && break;
  sleep ${SLEEP_SECONDS}
done