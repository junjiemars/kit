--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: list databases 
--------------------------------------------------

column OPEN_MODE format a12
column DATABASE_ROLE heading DATABASE|ROLE format a10
column OPEN_MODE heading OPEN|MODE format a10 word_wrap
column PLATFORM_NAME heading PLATFORM|NAME format a16 word_wrap

select 
    name
  , created
  , log_mode
  , open_mode
  , database_role
  , platform_name
from v$database
  order by name
;

/