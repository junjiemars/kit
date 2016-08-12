-- check
-- grant select on user_col_privs/dba_col_privs to &&user_name

select * from user_column_privs
  where table_name='&&table_name'
