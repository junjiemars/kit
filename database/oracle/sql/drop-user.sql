
--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: drop user by name
--------------------------------------------------

--define user_name=who

--Note:
--If failed with ORA-00942: Table or view doesn´t exist 
--then connect as sysdba, and run 
--@$ORACLE_HOME/rdbms/admin/catqueue.sql
--and do it again, good luck!

drop user &&user_name cascade;



