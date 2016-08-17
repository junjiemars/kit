set serveroutput on

define ts_name=TS_XWS
define ts_iname=TS_XWS

DECLARE

  CURSOR i_tables IS 
    SELECT TABLE_NAME FROM USER_TABLES 
    WHERE TABLESPACE_NAME != '&&ts_name';

  CURSOR i_indexes is 
    SELECT INDEX_NAME FROM USER_INDEXES 
    WHERE TABLESPACE_NAME != '&&ts_iname' AND INDEX_TYPE != 'LOB';

  CURSOR i_lob IS 
    SELECT TABLE_NAME, COLUMN_NAME FROM USER_LOBS 
    WHERE TABLESPACE_NAME != '&&ts_name';

  CURSOR i_indexes_invalid IS 
    SELECT INDEX_NAME FROM USER_INDEXES 
    WHERE STATUS != 'VALID';

BEGIN
  dbms_output.put_line('------------------------');
  dbms_output.put_line('# MIGRATING TABLES TO TABLESPACE &&ts_name...');
  FOR t IN i_tables LOOP
    BEGIN
      dbms_output.put_line('# '||t.table_name||' -> TABLESPACE: &&ts_name ...');
      EXECUTE IMMEDIATE 'alter table ' || t.table_name || ' move tablespace &&ts_name';
    EXCEPTION
      WHEN OTHERS THEN
        dbms_output.put_line('# '||sqlcode||'@'||t.table_name||' -> '||sqlerrm);
    END;
  END LOOP;

  dbms_output.put_line('------------------------');
  dbms_output.put_line('# MIGRATING INDEXES TO TABLESPACE &&ts_iname...');
  FOR i IN i_indexes LOOP
    BEGIN
      dbms_output.put_line('# '||i.index_name||' -> TABLESPACE: &&ts_iname ...');
      EXECUTE IMMEDIATE 'alter index ' || i.index_name || ' rebuild tablespace &&ts_iname';
    EXCEPTION
      WHEN OTHERS THEN
        dbms_output.put_line('# '||sqlcode||'@'||i.index_name||' -> '||sqlerrm);
    END;
  END LOOP;

  dbms_output.put_line('------------------------');
  dbms_output.put_line('# MIGRATING LOBS TO TABLESPACE &&ts_name...');
  FOR l IN i_lob LOOP
    BEGIN
      dbms_output.put_line('# '||l.table_name||'.'||l.column_name||' -> TABLESPACE: &&ts_name ...');
      EXECUTE IMMEDIATE 'alter table ' || l.table_name || ' move lob(' || l.column_name || ') store as (tablespace &&ts_name)';
    EXCEPTION
      WHEN OTHERS THEN
        dbms_output.put_line('# '||sqlcode||'@'||l.table_name||'.'||l.column_name||' -> '||sqlerrm);
    END;
  END LOOP;

  dbms_output.put_line('------------------------');
  dbms_output.put_line('# REBUILD INDEXES ON TABLESPACE &&ts_name...');
  FOR b IN i_indexes_invalid LOOP
    BEGIN
      dbms_output.put_line('# '||b.index_name||' ^ TABLESPACE: &&ts_name ...');
      EXECUTE IMMEDIATE 'alter index ' || b.index_name || ' rebuild';
    EXCEPTION
      WHEN OTHERS THEN
        dbms_output.put_line('# '||sqlcode||'@'||b.index_name||' ^ '||sqlerrm);
    END;
  END LOOP;

END;
/
