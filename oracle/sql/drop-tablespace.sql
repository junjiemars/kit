define ts_name=ts_xws


drop tablespace &&ts_name
  including contents 
  and datafiles
  cascade constraints
;
