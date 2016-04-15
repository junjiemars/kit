#!/bin/bash
#=====================================================
# Author: https://github.com/junjiemars
# Git: git clone https://github.com/junjiemars/kit.git
#=====================================================
# NOTE:
# For multiple ORACLE_HOME env only.
#====================================================
# MANUAL:
# imp.sh passcode file=? fromuser=? touser=? ignore=y
#=====================================================

ORACLE_HOME=${ORACLE_HOME:-"<oracle-home-dir>"}
ORACLE_SID=XE

LD_LIBRARY_PATH=$ORACLE_HOME/lib
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export PATH=$ORACLE_HOME/bin:$PATH

export NLS_LANG=AMERICAN_AMERICA.UTF8
#export NLS_LANG=CHINESE_CHINA.UTF8

imp $@
