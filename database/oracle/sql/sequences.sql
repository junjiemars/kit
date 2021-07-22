
--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: list sequences 
--------------------------------------------------

column sequence_name format a30
column min_value heading MIN|VALUE format 9999
column max_value heading MAX|VALUE
column increment_by heading INCR|BY
column cache_size heading CACHE|SIZE format 9999
column last_number heading LAST|NUMBER format 9999

select *
	from user_sequences
	order by sequence_name
;
