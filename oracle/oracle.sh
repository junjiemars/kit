#!/bin/bash
#=====================================================
# Author: https://github.com/junjiemars
# Git: git clone https://github.com/junjiemars/kit.git
#=====================================================
# NOTE:
# For multiple ORACLE_HOME env only.
#=====================================================

CMD=${CMD:-lsnrctl}
ORACLE_HOME=/usr/lib/oracle/xe/app/oracle/product/10.2.0/server
ORACLE_SID=XE

LD_LIBRARY_PATH=$ORACLE_HOME/lib
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export PATH=$ORACLE_HOME/bin:$PATH

export NLS_LANG=AMERICAN_AMERICA.UTF8
#export NLS_LANG=CHINESE_CHINA.UTF8


$CMD $@
