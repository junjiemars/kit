
--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: create sequence 
--------------------------------------------------

--Code:--
--select seq_name.nextval from dual;


--define seq_name=which
--define seq_incr=1

create sequence &&seq_name 
	minvalue 1
	maxvalue 99999999999999999
	start with 1
	increment by &&seq_incr
	cache 20
;
