select 
	table_name
	,grantee
	,privilege
from user_tab_privs_made
where table_name=$1

