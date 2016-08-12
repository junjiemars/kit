--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: set sqlplus prompt
-- prerequisite: put login.sql under then directory
--               that $SQLPATH env variable point to
--------------------------------------------------

set sqlprompt '&_user.@&_connect_identifier.> ';

-- use $? | %errorlevel%
-- whenever sqlerror exit sql.sqlcode

set serveroutput on

--set define on;
--define _editor=/usr/bin/vi;
--set define off;


