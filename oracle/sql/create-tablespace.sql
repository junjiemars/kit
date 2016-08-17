define ts_name=TS_XWS
Define ts_dbf=/u01/app/oracle/oradata/XE/xws.dbf
define ts_size=50M
define ts_autoextend=ON --OFF
define ts_next=512K
define ts_maxsize=500M

CREATE TABLESPACE &&ts_name
  DATAFILE '&&ts_dbf'
  SIZE &&ts_size
  AUTOEXTEND &&ts_autoextend
  NEXT &&ts_next
  MAXSIZE &&ts_maxsize
;

