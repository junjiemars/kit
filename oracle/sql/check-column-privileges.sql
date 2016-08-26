--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: grant select on 
--         user_col_privs/dba_col_privs 
--         to &&user_name
--------------------------------------------------

--define table_name=

select * 
from user_col_privs
  where table_name=upper('&&table_name')
;
