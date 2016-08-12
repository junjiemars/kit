--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: set sqlplus prompt
-- note: put login.sql under the directory
-- > that $SQLPATH point to
--------------------------------------------------

set sqlprompt '&_user.@&_connect_identifier.> ';

-- use $? | %errorlevel%
-- whenever sqlerror exit sql.sqlcode

set serveroutput on

--set define on;
--define _editor=/usr/bin/vi;
--set define off;


