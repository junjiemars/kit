
--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: create sequence 
--------------------------------------------------

--How to reset:
--1) alter increment by current val;
--2) gen nextval;
--3) alter increment by &&seq_incr

 
--define seq_name=which
--define seq_incr=1
--define seq_min=0

alter sequence &&seq_name 
	minvalue &&seq_min
	increment by &&seq_incr
;
