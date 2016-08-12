--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: view users when created, locked, status
--------------------------------------------------

SELECT
	username
	,account_status
	,lock_date
	,created
FROM dba_users
ORDER BY username;

