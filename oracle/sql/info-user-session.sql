--sqlplus sys as sysdba
--grant select on v$session to &&user_name

--define user_name='';

select * from v$session
    where username=upper('&&user_name')
;
