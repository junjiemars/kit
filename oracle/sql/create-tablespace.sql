--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: users when created, locked, status
--------------------------------------------------


define ts_name=ts_xws

define ts_dbf=/u01/app/oracle/oradata/XE/xws.dbf
define ts_size=50M
define ts_autoextend=on --|off
define ts_next=512K
define ts_maxsize=500M

create tablespace &&ts_name
  datafile '&&ts_dbf'
  size &&ts_size
  autoextend &&ts_autoextend
  next &&ts_next
  maxsize &&ts_maxsize
;

