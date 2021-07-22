--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: users when created, locked, status
-- show top CPU-consumming SQL processes
--------------------------------------------------

column sql_text format a14
column buffer_gets heading BUFFER|GETS
column disk_reads heading DISK|READS
column cpu_sec heading CPU|SEC
column rows_processed heading ROWS|PROCESSED

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



