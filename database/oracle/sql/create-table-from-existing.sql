
--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: drop table interactive
--------------------------------------------------

--define table_name=which
--define tablespace_name=which
--define new_initial=number
--define new_next=number
--define new_freelists=number
--define existing_table=which
--define primary_index=what

create table &&table_name 
tablespace &&tablespace
storage(initial &&new_initial next &&new_next freelists &&new_freelists)
as select * from &&existing_table
order by &&primary_index
;
