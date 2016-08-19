set serveroutput on size 1000000

BEGIN

  FOR o IN (select object_name, object_type from user_objects
              where object_type in ('TABLE','VIEW','PACKAGE','PROCEDURE','FUNCTION','SEQUENCE','INDEX','LOB')) LOOP
    BEGIN
      IF o.object_type = 'TABLE' THEN
        EXECUTE IMMEDIATE 'drop '||o.object_type||' "'||o.object_name||'" cascade constraints';
      ELSE
        EXECUTE IMMEDIATE 'drop '||o.object_type||' "'||o.object_name||'"';
      END IF;
      dbms_output.put_line('# '||o.object_name||'%'||o.object_type||' -> dropped');
    EXCEPTION
      WHEN OTHERS THEN
        dbms_output.put_line('# '||sqlcode||'@'||o.object_name||'%'||o.object_type||' -> '||sqlerrm);
    END;
  END LOOP;

END;
/
