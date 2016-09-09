#!/bin/bash
#------------------------------------------------
# author: junjiemars@gmail.com
# target: SQL*Plus Kits
# note: suit for multiple Oracle coexisting env
#------------------------------------------------

export ORACLE_HOME=${ORACLE_HOME:-"/opt/oracle/u01/app/oracle/product/11.2.0/xe"}

export LD_LIBRARY_PATH=${ORACLE_HOME%/}/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export PATH=${ORACLE_HOME%/}/bin${PATH:+:$PATH}
export NLS_LANG=${NLS_LANG:-'AMERICAN_AMERICA.UTF8'}
#export NLS_CHARACTERSET=${NLS_CHARACTERSET:-"AL32UTF8"} # AL16UTF8
#export NLS_LENGTH_SEMANTICS=${NLS_LENGTH_SEMANTICS:-"CHAR"} # BYTE

ORA_USER=${ORA_USER:-'system'}
ORA_PASSWD=${ORA_PASSWD:-'oracle'}
HOST=${HOST:-'localhost'}
PORT=${PORT:-'1521'}
SID=${SID:-'XE'}
CONNECT_IDENTIFIER=${CONNECT_IDENTIFIER:-"${HOST}:${PORT}/${SID}"}

if [ 0 -eq $# ] ; then
	expdp help=y
elif [ 1 -le $# ]; then
	if `echo $1|grep .*@.*[:/][0-9]*[:/].* &>/dev/null`; then
		expdp $1 ${@:2} 
  else
		expdp ${ORA_USER}/${ORA_PASSWD}@${CONNECT_IDENTIFIER} $@
  fi
else
	expdp $1@${CONNECT_IDENTIFIER} help=y
fi

