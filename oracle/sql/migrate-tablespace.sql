define ts_name=TS_XWS
define ts_iname=TS_XWS

DECLARE

  CURSOR i_tables IS 
    SELECT TABLE_NAME FROM USER_TABLES 
    WHERE TABLESPACE_NAME != '&&ts_name';
/*
  CURSOR i_indexes is 
    SELECT INDEX_NAME FROM USER_INDEXES 
    WHERE TABLESPACE_NAME != '&&ts_iname' AND INDEX_TYPE != 'LOB';

  CURSOR i_lob IS 
    SELECT TABLE_NAME, COLUMN_NAME FROM USER_LOBS 
    WHERE TABLESPACE_NAME != '&&ts_name';

  CURSOR i_indexes_invalid IS 
    SELECT INDEX_NAME FROM USER_INDEXES 
    WHERE STATUS != 'VALID';
*/

BEGIN

  FOR t IN i_tables LOOP
    EXECUTE IMMEDIATE 'alter table ' || t.table_name || ' move tablespace &&ts_name';
  END LOOP;

/*
  FOR i IN i_indexes loop
    EXECUTE IMMEDIATE 'alter index ' || i.index_name || ' rebuild tablespace &&ts_iname';
  END LOOP;

  FOR l IN i_lob LOOP
    EXECUTE IMMEDIATE 'alter table ' || l.table_name || ' move lob(' || l.column_name || ') store as (tablespace &&ts_name)';
  END LOOP;

  FOR b IN i_indexes_invalid LOOP
    EXECUTE IMMEDIATE 'alter index ' || b.index_name || ' rebuild';
  END LOOP;
*/
END;
/
