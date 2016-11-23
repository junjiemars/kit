
select substr(comp_name, 1, 30) comp_name,
       substr(comp_id, 1, 10) comp_id,
       substr(version, 1, 12) version,
       status
from dba_registry;

/
       
