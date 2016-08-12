-- check
-- grant select on user_table_privs/dba to &&user_name

select * from user_table_privs
  where table_name='&&table_name'
