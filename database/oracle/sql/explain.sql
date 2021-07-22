--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: oracle version info
--------------------------------------------------

-- 1. explain plan
explain plan for 
select * from v$version;
;

-- 2. review the plan
select * from table(dbms_xplan.display);

