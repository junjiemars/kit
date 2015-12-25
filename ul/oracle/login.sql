## sqlplus startup script, put login.sql
## under the directory that $SQLPATH env variable point to

set sqlprompt '&_user.@&_connect_identifier.> ';

REM use $? | %errorlevel%
REM whenever sqlerror exit sql.sqlcode

REM set serveroutput on
REM define _editor=/usr/bin/vi


