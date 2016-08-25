#!/bin/bash
#------------------------------------------------
# author: junjiemars@gmail.com
# target: SQL*Plus Kits
# note: suit for multiple Oracle coexisting env
#------------------------------------------------

export ORACLE_HOME=${ORACLE_HOME:-"/d/opt/oracle/product/11.2.0/server"}
ORACLE_SID=${ORACLE_SID:-"XE"}

export LD_LIBRARY_PATH=${ORACLE_HOME%/}/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export PATH=${ORACLE_HOME%/}/bin${PATH:+:$PATH}

export NLS_LANG=${NLS_LANG:-'AMERICAN_AMERICA.UTF8'}
#export NLS_CHARACTERSET=${NLS_CHARACTERSET:-"AL32UTF8"} # AL16UTF8
#export NLS_LENGTH_SEMANTICS=${NLS_LENGTH_SEMANTICS:-"CHAR"} # BYTE

exp $@
