#!/bin/bash
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
USERID=${USERID:-"${HOST}:${PORT}/${SID}"}


if [ 0 -eq $# ] ; then
	imp help=y
elif [ 1 -le $# ]; then
	if `echo $1|grep .*@.*[:/][0-9]*[:/].* &>/dev/null`; then
		imp $1 ${@:2} 
  else
		imp $1@${USERID} ${@:2}
  fi
else
	imp ${ORA_USER}/${ORA_PASSWD}@${USERID} $1
fi

