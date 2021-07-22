column original_name format a24;
column object_name format a32;
column operation format a10;
column type format a10;

SELECT 
    original_name
  , object_name
  , operation
  , type
FROM user_recyclebin
;


