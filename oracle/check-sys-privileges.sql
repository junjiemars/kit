-- show the user's sys privileges

--define user_name=''

col grantee for a20
col privilege for a30

select * from dba_sys_privs
    where grantee=upper('&&user_name')
    order by privilege
;
