
--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: free space owner by user
--------------------------------------------------


--define ts_name=which

column tablespace_name format a20
column relative_fno heading RELATIVE|FNO

select 
		tablespace_name
	,	file_id
	,	block_id
	, bytes
	, blocks
	,	relative_fno
	from user_free_space
	where tablespace_name=upper('&&ts_name')
		or 1=1
;
