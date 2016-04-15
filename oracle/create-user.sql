define user_name=xws
define user_password=xws
define user_tablespace=USERS

CREATE USER &&user_name IDENTIFIED BY &&user_password
DEFAULT TABLESPACE &&user_tablespace
ACCOUNT UNLOCK;

GRANT CONNECT, RESOURCE TO &&user_name;

GRANT CREATE TABLE TO &&user_name;
GRANT CREATE DATABASE LINK TO &&user_name;
GRANT CREATE VIEW TO &&user_name;
GRANT CREATE SEQUENCE TO &&user_name;
GRANT CREATE PROCEDURE TO &&user_name;
GRANT CREATE MATERIALIZED VIEW TO &&user_name;
GRANT CREATE SYNONYM TO &&user_name;
GRANT IMP_FULL_DATABASE to &&user_name;
GRANT DEBUG CONNECT SESSION TO &&user_name;
