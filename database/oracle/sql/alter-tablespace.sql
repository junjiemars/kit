
--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: alter tablespace interactive 
--------------------------------------------------

--Note--
--When: ORA-32773: operation not supported for 
--smallfile tablespace ARLO
--Then: alter-datafile.sql

--define ts_name=which
--define ts_size=64M
--define ts_autoextend=on --off
--define ts_next=32M
--define ts_maxsize=512M

alter tablespace &&ts_name
  autoextend &&ts_autoextend
  next &&ts_next
  maxsize &&ts_maxsize
;
