--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: list tablespaces
--------------------------------------------------

column NAME format a20
column INCLUDED_IN_DATABASE_BACKUP heading INCLUDED|IN|DATABASE|BACKUP 
column ENCRYPT_IN_BACKUP heading ENCRYPT|IN|BACKUP

select * from v$tablespace
  order by ts#
;

