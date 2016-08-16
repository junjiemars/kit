define ts_name=xws
define ts_dbf=/u01/app/oracle/oradata/XE/xws.dbf
define ts_size=50M
define ts_autoextend=ON --OFF
define ts_next=512K
define ts_maxsize=500M

CREATE TABLESPACE TS_&&ts_name
  DATAFILE '&&ts_dbf'
  SIZE &&ts_size
  AUTOEXTEND &&ts_autoextend
  NEXT &&ts_next
  MAXSIZE &&ts_maxsize
;


--ALTER TABLESPACE TS_&&ts_name
--  AUTOEXTEND &&ts_autoextend
--  NEXT &&ts_next
--  MAXSIZE &&ts_maxsize
--;


--DROP TABLESPACE TS_&&ts_name
--  INCLUDING CONTENTS AND DATAFILES
--  CASCADE CONSTRAINTS
--;
