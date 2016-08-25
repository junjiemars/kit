
--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: rolling database/session 
--         nls_length_semantics
--------------------------------------------------

define env='session'; -- session|system

declare
  semantic varchar2(10) := null;
begin
  select value into semantic
  from nls_database_parameters
    where PARAMETER='NLS_LENGTH_SEMANTICS'; 
  dbms_output.put_line('From NLS_LENGTH_SEMANTICS=' || semantic);

  if (semantic = 'BYTE') then
    semantic := 'CHAR';
  else
    semantic := 'BYTE';
  end if;
  
  execute immediate 'alter &&env set NLS_LENGTH_SEMANTICS=' || semantic;

  select value into semantic
  from nls_database_parameters
    where PARAMETER='NLS_LENGTH_SEMANTICS'; 
  dbms_output.put_line('To NLS_LENGTH_SEMANTICS=' || semantic);


end
;

/

