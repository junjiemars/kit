-- sqlplus startup script, put login.sql
-- under the directory that $SQLPATH env variable point to

set sqlprompt '&_user.@&_connect_identifier.> ';

-- use $? | %errorlevel%
-- whenever sqlerror exit sql.sqlcode

set serveroutput on
##define _editor=/usr/bin/vi


