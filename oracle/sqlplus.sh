#!/bin/bash
#------------------------------------------------
# author: junjiemars@gmail.com
# target: SQL*Plus Kits
# note: suit for multiple Oracle coexisting env
#------------------------------------------------

export ORACLE_HOME=${ORACLE_HOME:-"/opt/oracle/instantclient_12_1"}
export SQLPATH=${SQLPATH:-"/opt/oracle/sql"}
export NLS_LANG=${NLS_LANG:-"AMERICAN_AMERICA.UTF8"}
export LD_LIBRARY_PATH=${ORACLE_HOME%/}/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export PATH=${ORACLE_HOME%/}/bin${PATH:+:$PATH}

ORA_USER=${ORA_USER:-'system'}
ORA_PASSWD=${ORA_PASSWD:-'oracle'}
HOST=${HOST:-'localhost'}
PORT=${PORT:-'1521'}
SID=${SID:-'XE'}
CONNECT_IDENTIFIER=${CONNECT_IDENTIFIER:-"${HOST}:${PORT}/${SID}"}

if [ 0 -eq `type -p rlwrap &>/dev/null; echo $?` ]; then
	RLWRAP='rlwrap'
fi	

if [ 0 -eq $# ] ; then
	${RLWRAP} sqlplus ${ORA_USER}/${ORA_PASSWD}@${CONNECT_IDENTIFIER}
elif [ 1 -le $# ]; then
	if `echo $1|grep .*@.*[:/][0-9]*[:/].* &>/dev/null`; then
		${RLWRAP} sqlplus $1 ${@:2}
  else
		${RLWRAP} sqlplus $1@${CONNECT_IDENTIFIER} ${@:2}
  fi
else
	${RLWRAP} sqlplus $@
fi

