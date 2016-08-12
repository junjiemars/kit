#!/bin/bash
#------------------------------------------------
# author: junjiemars@gmail.com
# target: SQL*Plus Kits
# note: suit for multiple Oracle coexisting env
#------------------------------------------------

CMD=${CMD:-lsnrctl}

export ORACLE_HOME=${ORACLE_HOME:-"<oracle-home-dir"}
ORACLE_SID=XE

export LD_LIBRARY_PATH=${ORACLE_HOME%/}${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export PATH=${ORACLE_HOME%/}/bin:$PATH

export NLS_LANG=${NLS_LANG:-'AMERICAN_AMERICA.UTF8'}


$CMD "$@"
