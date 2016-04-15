/*
The following script lists the top CPU-consuming SQL processes. It’s useful for identifying problem SQL statements. 
*/

select * from(
			select
				sql_text
				,buffer_gets
				,disk_reads
				,sorts
				,cpu_time/1000000 cpu_sec
				,executions
				,rows_processed
			from v$sqlstats
			order by cpu_time DESC)
where rownum < 11;

