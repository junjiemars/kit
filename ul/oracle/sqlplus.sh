# sqlplus wrapper
export SQLPATH=${SQLPATH:-"$HOME/apps/kit/ul/oracle"}
export NLS_LANG=AMERICAN_AMERICA.UTF8

if [ $# -eq 0 ] ; then
	rlwrap sqlplus system/password@host:1521/XE
else 
	rlwrap sqlplus $@
fi

# remote:
# sqlplus sms_search/sms123@10.32.65.238:1521/orcl

