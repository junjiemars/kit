--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: users when created, locked, status
--------------------------------------------------

column username format a20
column account_status format a24

select
	  username
	, account_status
	, lock_date
	, created
from dba_users
order by username
;


