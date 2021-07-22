
--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: drop tablespace by name
--------------------------------------------------

--define ts_name=which


drop tablespace &&ts_name
  including contents 
  and datafiles
  cascade constraints
;
