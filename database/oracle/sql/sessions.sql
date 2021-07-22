--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: sessions
--------------------------------------------------

column username format a20
column schemaname format a20
column program format a20


select 
		sid
	, serial#
	, username
	, schemaname
	, program
from v$session
order by sid
;


