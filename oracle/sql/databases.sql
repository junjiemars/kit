--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: list databases 
--------------------------------------------------


select * from v$database
  order by name
;

/