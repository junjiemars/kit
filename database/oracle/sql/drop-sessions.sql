
--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: drop user's sessions
--------------------------------------------------

--define user_name=who

declare 
  x varchar(255) := null;
  u varchar(30) := '&&user_name';
begin
  select 'alter system kill session ''' || sid || ',' || serial# || '''' into x
  from v$session 
  where username = u;

  dbms_output.put_line(x);

  execute immediate x;

end;
