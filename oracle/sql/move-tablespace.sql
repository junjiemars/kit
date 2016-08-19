set serveroutput on

define ts_old_name=users
define ts_new_name=ts_xws
define ts_old_iname=users
define ts_new_iname=ts_xws

declare

  cursor i_tables is 
    select table_name from user_tables 
    where tablespace_name = '&&ts_old_name';

  cursor i_indexes is 
    select index_name from user_indexes 
    where tablespace_name = '&&ts_old_iname' and index_type != 'lob';

  cursor i_lob is 
    select table_name, column_name from user_lobs 
    where tablespace_name = '&&ts_old_name';

  cursor i_indexes_invalid is 
    select index_name from user_indexes 
    where status != 'valid';

begin

  dbms_output.put_line('------------------------');
  dbms_output.put_line('! moving tables tablespace from &&ts_old_name to &&ts_new_name...');
  for t in i_tables loop
    begin
      execute immediate 'alter table ' || t.table_name || ' move tablespace &&ts_new_name';
      dbms_output.put_line('# '||t.table_name||' -> tablespace: &&ts_new_name');
    exception
      when others then
        dbms_output.put_line('# '||sqlcode||'@'||t.table_name||' -> '||sqlerrm);
    end;
  end loop;

  dbms_output.put_line('------------------------');
  dbms_output.put_line('! moving indexes tablespace from &&ts_old_iname to &&ts_new_iname...');
  for i in i_indexes loop
    begin
      execute immediate 'alter index ' || i.index_name || ' rebuild tablespace &&ts_new_iname';
      dbms_output.put_line('# '||i.index_name||' -> tablespace: &&ts_new_iname');
    exception
      when others then
        dbms_output.put_line('# '||sqlcode||'@'||i.index_name||' -> '||sqlerrm);
    end;
  end loop;

  dbms_output.put_line('------------------------');
  dbms_output.put_line('! moving lobs tablespace from &&ts_old_name to &&ts_new_name...');
  for l in i_lob loop
    begin
      execute immediate 'alter table ' || l.table_name || ' move lob(' || l.column_name || ') store as (tablespace &&ts_new_name)';
      dbms_output.put_line('# '||l.table_name||'.'||l.column_name||' -> tablespace: &&ts_new_name');
    exception
      when others then
        dbms_output.put_line('# '||sqlcode||'@'||l.table_name||'.'||l.column_name||' -> '||sqlerrm);
    end;
  end loop;

  dbms_output.put_line('------------------------');
  dbms_output.put_line('! rebuild indexes on tablespace &&ts_new_name...');
  for b in i_indexes_invalid loop
    begin
      execute immediate 'alter index ' || b.index_name || ' rebuild';
      dbms_output.put_line('# '||b.index_name||' ^ tablespace: &&ts_new_name');
    exception
      when others then
        dbms_output.put_line('# '||sqlcode||'@'||b.index_name||' ^ '||sqlerrm);
    end;
  end loop;

end;

/
