#!/bin/bash
#------------------------------------------------
# author: junjiemars@gmail.com
# dependent: sqlplus.sh
# target: SQL*Plus Kits
# note: check oracle working correctly
#------------------------------------------------

TRY_N=${TRY_N:-5}
SLEEP_SECONDS=${SLEEP_SECONDS:-10}
SQLPLUS_SH=${SQLPLUS_SH:-$1}

trap "exit" INT
for N in `seq 1 ${TRY_N}`; do
	echo "\$@=$@"
	sleep ${SLEEP_SECONDS}
  echo -e "whenever sqlerror exit sql.sqlcode\nselect 1+2 from dual;" \
		| ${SQLPLUS_SH} "$@" && exit 0;
done
exit $?
