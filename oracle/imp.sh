#!/bin/bash
#!/bin/bash
#------------------------------------------------
# author: junjiemars@gmail.com
# target: SQL*Plus Kits
# note: suit for multiple Oracle coexisting env
#------------------------------------------------

ORACLE_HOME=${ORACLE_HOME:-"<oracle-home-dir>"}
ORACLE_SID=XE

export LD_LIBRARY_PATH=${ORACLE_HOME%/}/lib{LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export PATH=${ORACLE_HOME%/}/bin${PATH:+:$PATH}
export NLS_LANG=${NLS_LANG:-'AMERICAN_AMERICA.UTF8'}
export NLS_CHARACTERSET=${NLS_CHARACTERSET:-"AL32UTF8"}
export NLS_LENGTH_SEMANTICS=${NLS_LENGTH_SEMANTICS:-"CHAR"} # BYTE

imp $@
