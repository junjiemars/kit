
--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: show the user's role privileges
--------------------------------------------------


--define user_name=''

column GRANTEE FORMAT a20
column GRANTED_ROLE FORMAT a30

select * from dba_role_privs
  where grantee=upper('&&user_name')
  order by granted_role
;
