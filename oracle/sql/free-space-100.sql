
--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: free space % by dba 
--------------------------------------------------


--define ts_name=which

column tablespace_name format a20

select df.tablespace_name "TABLESPACE_NAME",
       df.bytes / (1024 * 1024) "SIZE (MB)",
       SUM(fs.bytes) / (1024 * 1024) "FREE (MB)",
       Nvl(Round(SUM(fs.bytes) * 100 / df.bytes),1) "% FREE",
       Round((df.bytes - SUM(fs.bytes)) * 100 / df.bytes) "% USED"
  from dba_free_space fs,
       (SELECT tablespace_name,SUM(bytes) bytes
          FROM dba_data_files
         GROUP BY tablespace_name) df
 where fs.tablespace_name (+)  = df.tablespace_name
 group BY df.tablespace_name,df.bytes
union all
select df.tablespace_name tspace,
       fs.bytes / (1024 * 1024),
       SUM(df.bytes_free) / (1024 * 1024),
       Nvl(Round((SUM(fs.bytes) - df.bytes_used) * 100 / fs.bytes), 1),
       Round((SUM(fs.bytes) - df.bytes_free) * 100 / fs.bytes)
  from dba_temp_files fs,
       (SELECT tablespace_name,bytes_free,bytes_used
          FROM v$temp_space_header
         GROUP BY tablespace_name,bytes_free,bytes_used) df
 where fs.tablespace_name (+)  = df.tablespace_name
 group by df.tablespace_name,fs.bytes,df.bytes_free,df.bytes_used
 order by 4 desc;
