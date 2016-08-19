set serveroutput on size 1000000;

BEGIN
  FOR t IN (select * from user_tables) LOOP
    BEGIN
      EXECUTE IMMEDIATE 'drop table '||t.table_name||' cascade constraints';
      dbms_output.put_line('# '||t.table_name||' -> dropped');
    EXCEPTION
      WHEN OTHERS THEN
        dbms_output.put_line('# '||sqlcode||'@'||t.table_name||' -> '||sqlerrm);
    END;
  END LOOP;

END;
/
