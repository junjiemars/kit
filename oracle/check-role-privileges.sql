-- show the user's role privileges

--define user_name=''

col grantee for a20
col granted_role for a30

select * from dba_role_privs
    where grantee=upper('&&user_name')
    order by granted_role
;
