--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: users when created, locked, status
-- Note:
-- > sqlplus sys as sysdba
-- > grant select on v$session to &&user_name
--------------------------------------------------

define user_name=xws;

select * from v$session 
  where username=upper('&&user_name')
;


