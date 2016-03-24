#!/bin/bash

# 1. download instantclient basic and unzip it;
# 2. download sqlplus and unzip into basic;

export SQLPLUS_HOME=${SQLPLUS_HOME:-"/opt/oracle/instantclient_12_1/"}
export SQLPATH=${SQLPATH:-"/opt/oracle/sql"}
export NLS_LANG=AMERICAN_AMERICA.UTF8
export LD_LIBRARY_PATH=$SQLPLUS_HOME${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export PATH=$SQLPLUS_HOME:$PATH

if [ $# -eq 0 ] ; then
	rlwrap sqlplus system/password@host:1521/XE
else 
	rlwrap sqlplus $@
fi

