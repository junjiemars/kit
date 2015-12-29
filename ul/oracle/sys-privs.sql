/*
 * show the user's sys privileges
*/
--define username=''

col grantee for a30
col privilege for a30

select 	
		*
from dba_sys_privs
where grantee=upper('&&username')
order by privilege
;
