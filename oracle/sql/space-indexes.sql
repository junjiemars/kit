
--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: space occupied of indexes
--------------------------------------------------


--define index_name=which

column index_name format a30
column table_name format a20 wrapped 
break on table_name

select 
	  i.index_name "INDEX_NAME"
	, s.bytes / (1024 * 1024) "SIZE (MB)"
	, s.blocks 
  ,	i.table_name
	from user_segments s, user_indexes i
	where i.index_name = s.segment_name
		and (s.segment_type='INDEX' or s.segment_type='LOBINDEX')
	order by s.bytes desc, i.index_name
;
