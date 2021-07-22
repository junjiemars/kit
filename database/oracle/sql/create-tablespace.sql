--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: users when created, locked, status
--------------------------------------------------


--define ts_name=which
define ts_dbf=/u01/app/oracle/oradata/XE/&&ts_name

define ts_size=64M
define ts_autoextend=on --|off
--define ts_next=16M
--define ts_maxsize=512M

create tablespace &&ts_name
  datafile '&&ts_dbf'
  size &&ts_size
  autoextend &&ts_autoextend
  next &&ts_next
  maxsize &&ts_maxsize
;

