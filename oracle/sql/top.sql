--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: users when created, locked, status
-- show top CPU-consumming SQL processes
--------------------------------------------------

column sql_text format a20
column buffer_gets a10
column disk_reads a10
column sorts a4
column cpu_time a4
column executions a6

select * from(
  select
      sql_text
    , buffer_gets
    , disk_reads
    , sorts
    , cpu_time/1000000 cpu_sec
    , executions
    , rows_processed
	from v$sqlstats
		order by cpu_time DESC)
where rownum < 11
;

/

