set serveroutput on size 1000000;

begin

  for t in (select * from user_tables) loop

    begin
      execute immediate 'drop table '||t.table_name||' cascade constraints';
      dbms_output.put_line('# '||t.table_name||' -> dropped');
    exception
      when others then
        dbms_output.put_line('# '||sqlcode||'@'||t.table_name||' -> '||sqlerrm);
    end;

  end loop;

end;
/
