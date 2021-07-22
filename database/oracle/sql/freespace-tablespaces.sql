
--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: free space of tablespace
--------------------------------------------------


--define ts_name=which

column tablespace_name format a20

select df.tablespace_name "TABLESPACE_NAME",
       df.bytes / (1024 * 1024) "SIZE (MB)",
       sum(fs.bytes) / (1024 * 1024) "FREE (MB)",
       nvl(round(sum(fs.bytes) * 100 / df.bytes),1) "% FREE",
       round((df.bytes - sum(fs.bytes)) * 100 / df.bytes) "% USED"
  from dba_free_space fs,
       (select tablespace_name, sum(bytes) bytes
          from dba_data_files
         group by tablespace_name) df
 where fs.tablespace_name (+)  = df.tablespace_name
 group by df.tablespace_name, df.bytes
union all
select df.tablespace_name tspace,
       fs.bytes / (1024 * 1024),
       sum(df.bytes_free) / (1024 * 1024),
       nvl(round((sum(fs.bytes) - df.bytes_used) * 100 / fs.bytes), 1),
       round((sum(fs.bytes) - df.bytes_free) * 100 / fs.bytes)
  from dba_temp_files fs,
       (select tablespace_name, bytes_free, bytes_used
          from v$temp_space_header
         group by tablespace_name, bytes_free, bytes_used) df
 where fs.tablespace_name (+)  = df.tablespace_name
 group by df.tablespace_name, fs.bytes, df.bytes_free, df.bytes_used
 order by 4 desc
;
