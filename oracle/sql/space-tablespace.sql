
--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: free space owner by user
--------------------------------------------------


--define ts_name=which

column tablespace_name format a20
column relative_fno heading RELATIVE|FNO
break on tablespace_name

select 
	  tablespace_name
	, file_id
	,	block_id
	, bytes
	, blocks
	,	relative_fno
	from user_free_space
	where tablespace_name=upper('&&ts_name')
	order by block_id
;
