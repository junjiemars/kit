define ts_name=xws
define ts_size=50M
define ts_autoextend=ON --OFF
define ts_next=512K
define ts_maxsize=500M

ALTER TABLESPACE TS_&&ts_name
  AUTOEXTEND &&ts_autoextend
  NEXT &&ts_next
  MAXSIZE &&ts_maxsize
;
