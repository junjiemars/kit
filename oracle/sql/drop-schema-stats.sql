

--define schema=<what>
execute dbms_stats.delete_schema_stats('&&schema');

