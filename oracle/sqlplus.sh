#!/bin/bash
#------------------------------------------------
# target: SQL*Plus Toolbox 
# author: junjiemars@gmail.com
#------------------------------------------------

ORACLE_HOME=${ORACLE_HOME:-}
export SQLPLUS_HOME=${SQLPLUS_HOME:-'/opt/oracle/instantclient_12_1/'}
export SQLPATH=${SQLPATH:-'/opt/oracle/sql'}
export NLS_LANG=${NLS_LANG:-'AMERICAN_AMERICA.UTF8'}
export LD_LIBRARY_PATH=$SQLPLUS_HOME${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export PATH=$SQLPLUS_HOME:${PATH:+:$PATH}

USERNAME=${USERNAME:-'system'}
PASSWORD=${PASSWORD:-'oracle'}
CONNECT_IDENTIFIER=${CONNECT_IDENTIFIER:-'localhost:1521/XE'}

if [ 0 -eq `type -p rlwrap &>/dev/null; echo $?` ]; then
	RLWRAP='rlwrap'
else
	RLWRAP=''	
fi	

if [ 0 -eq $# ] ; then
	rlwrap sqlplus ${USERNAME}/${PASSWORD}@${CONNECT_IDENTIFIER}
else 
	rlwrap sqlplus $@
fi

