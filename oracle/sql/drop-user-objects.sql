set serveroutput on size 1000000

begin

  for o in (select object_name, object_type from user_objects
              where object_type in (
                  'TABLE'
                , 'VIEW'
                , 'PACKAGE'
                , 'PROCEDURE'
                , 'FUNCTION'
                , 'SEQUENCE'
                , 'INDEX')) loop
    begin
      if o.object_type = 'table' then
        execute immediate 'drop '||o.object_type||' "'||o.object_name||'" cascade constraints';
      else
        execute immediate 'drop '||o.object_type||' "'||o.object_name||'"';
      end if;
      dbms_output.put_line('# '||o.object_name||'%'||o.object_type||' -> dropped');
    exception
      when others then
        dbms_output.put_line('# '||sqlcode||'@'||o.object_name||'%'||o.object_type||' -> '||sqlerrm);
    end;
  end loop;

end;

