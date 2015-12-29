define user_name=xws
define user_password=xws
define user_tablespace=USERS

CREATE USER &&user_name IDENTIFIED BY &&user_password
DEFAULT TABLESPACE &&user_tablespace
ACCOUNT UNLOCK;

GRANT CONNECT, RESOURCE TO &&user_name;

GRANT CREATE TABLE TO &&user_name;
