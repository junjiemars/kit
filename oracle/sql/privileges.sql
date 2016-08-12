--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: view user's privileges
--------------------------------------------------

select * from dba_sys_privs
    where grantee=upper('&&username')
    order by privilege
;
