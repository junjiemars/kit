
--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: space occupied of tables 
--------------------------------------------------


--define table_name=which

column table_name format a30
column tablespace_name format a16 wrapped

select 
	  t.table_name "TABLE_NAME"
	, s.bytes / (1024 * 1024) "SIZE (MB)"
	, s.blocks 
  ,	s.tablespace_name
	from user_segments s, user_tables t
	where t.table_name = s.segment_name
		and s.segment_type='TABLE'
	order by s.bytes desc, t.table_name
;
