--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: list tablespaces
--------------------------------------------------

column ts# format 9999
column name format a20
column included_in_database_backup heading INCLUDED|IN|DATABASE|BACKUP 
column encrypt_in_backup heading ENCRYPT|IN|BACKUP

select * from v$tablespace
  order by ts#
;

