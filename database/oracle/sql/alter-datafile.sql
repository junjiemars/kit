
--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: alter datafile interactive 
--------------------------------------------------


define ts_dbf='/u01/app/oracle/oradata/XE/&&ts_name'
--define ts_autoextend=on --off
--define ts_next=32M
--define ts_maxsize=512M

alter database
	datafile '&&ts_dbf'
  autoextend &&ts_autoextend
  next &&ts_next
  maxsize &&ts_maxsize
;
