#!/bin/bash

CMD=${CMD:-lsnrctl}
ORACLE_HOME=/usr/lib/oracle/xe/app/oracle/product/10.2.0/server
ORACLE_SID=XE

LD_LIBRARY_PATH=$ORACLE_HOME/lib
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export PATH=$ORACLE_HOME/bin:$PATH

$CMD $@
