#!/bin/bash
#------------------------------------------------
# author: junjiemars@gmail.com
# target: SQL*Plus Kits
# note: suit for multiple Oracle coexisting env
#------------------------------------------------

export ORACLE_HOME=${ORACLE_HOME:-"/opt/oracle/u01/app/oracle/product/11.2.0/xe"}
export LD_LIBRARY_PATH=${ORACLE_HOME%/}/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export PATH=${ORACLE_HOME%/}/bin:$PATH
export NLS_LANG=${NLS_LANG:-'AMERICAN_AMERICA.UTF8'}
#export NLS_LANG=CHINESE_CHINA.UTF8
ORACLE_SID=XE

exp $@
