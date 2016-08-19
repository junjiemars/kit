set serveroutput on

define ts_old_name=USERS
define ts_new_name=TS_XWS
define ts_old_iname=USERS
define ts_new_iname=TS_XWS

DECLARE

  CURSOR i_tables IS 
    SELECT TABLE_NAME FROM USER_TABLES 
    WHERE TABLESPACE_NAME = '&&ts_old_name';

  CURSOR i_indexes is 
    SELECT INDEX_NAME FROM USER_INDEXES 
    WHERE TABLESPACE_NAME = '&&ts_old_iname' AND INDEX_TYPE != 'LOB';

  CURSOR i_lob IS 
    SELECT TABLE_NAME, COLUMN_NAME FROM USER_LOBS 
    WHERE TABLESPACE_NAME = '&&ts_old_name';

  CURSOR i_indexes_invalid IS 
    SELECT INDEX_NAME FROM USER_INDEXES 
    WHERE STATUS != 'VALID';

BEGIN
  dbms_output.put_line('------------------------');
  dbms_output.put_line('! MOVING TABLES TABLESPACE FROM &&ts_old_name TO &&ts_new_name...');
  FOR t IN i_tables LOOP
    BEGIN
      EXECUTE IMMEDIATE 'alter table ' || t.table_name || ' move tablespace &&ts_new_name';
      dbms_output.put_line('# '||t.table_name||' -> TABLESPACE: &&ts_new_name');
    EXCEPTION
      WHEN OTHERS THEN
        dbms_output.put_line('# '||sqlcode||'@'||t.table_name||' -> '||sqlerrm);
    END;
  END LOOP;

  dbms_output.put_line('------------------------');
  dbms_output.put_line('! MOVING INDEXES TABLESPACE FROM &&ts_old_iname TO &&ts_new_iname...');
  FOR i IN i_indexes LOOP
    BEGIN
      EXECUTE IMMEDIATE 'alter index ' || i.index_name || ' rebuild tablespace &&ts_new_iname';
      dbms_output.put_line('# '||i.index_name||' -> TABLESPACE: &&ts_new_iname');
    EXCEPTION
      WHEN OTHERS THEN
        dbms_output.put_line('# '||sqlcode||'@'||i.index_name||' -> '||sqlerrm);
    END;
  END LOOP;

  dbms_output.put_line('------------------------');
  dbms_output.put_line('! MOVING LOBS TABLESPACE FROM &&ts_old_name TO &&ts_new_name...');
  FOR l IN i_lob LOOP
    BEGIN
      EXECUTE IMMEDIATE 'alter table ' || l.table_name || ' move lob(' || l.column_name || ') store as (tablespace &&ts_new_name)';
      dbms_output.put_line('# '||l.table_name||'.'||l.column_name||' -> TABLESPACE: &&ts_new_name');
    EXCEPTION
      WHEN OTHERS THEN
        dbms_output.put_line('# '||sqlcode||'@'||l.table_name||'.'||l.column_name||' -> '||sqlerrm);
    END;
  END LOOP;

  dbms_output.put_line('------------------------');
  dbms_output.put_line('! REBUILD INDEXES ON TABLESPACE &&ts_new_name...');
  FOR b IN i_indexes_invalid LOOP
    BEGIN
      EXECUTE IMMEDIATE 'alter index ' || b.index_name || ' rebuild';
      dbms_output.put_line('# '||b.index_name||' ^ TABLESPACE: &&ts_new_name');
    EXCEPTION
      WHEN OTHERS THEN
        dbms_output.put_line('# '||sqlcode||'@'||b.index_name||' ^ '||sqlerrm);
    END;
  END LOOP;

END;
/
