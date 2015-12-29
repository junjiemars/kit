define link_name=DL_238
define user_name=sms_search
define user_pwd=sms123
define host_prot=tcp
define host_addr=10.32.65.238
define host_port=1521
define host_sid=orcl
 
CREATE DATABASE LINK &&link_name 
   CONNECT TO &&user_name IDENTIFIED BY &&user_pwd 
   USING '(DESCRIPTION =
       (ADDRESS_LIST =
         (ADDRESS = (PROTOCOL = &&host_prot)(HOST = &&host_addr)(PORT = &&host_port))
       )
       (CONNECT_DATA =
         (SID = &&host_sid)
       )
     )'
;
