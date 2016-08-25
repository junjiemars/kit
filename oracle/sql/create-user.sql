
--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: create/grant user
--------------------------------------------------

define user_name=xws
define user_password=xws
define user_tablespace=ts_xws


create user &&user_name identified by &&user_password
  default tablespace &&user_tablespace
  account unlock;

grant connect, resource to &&user_name;

grant create table to &&user_name;
grant create database link to &&user_name;
grant create view to &&user_name;
grant create sequence to &&user_name;
grant create procedure to &&user_name;
grant create materialized view to &&user_name;
grant create synonym to &&user_name;
grant imp_full_database to &&user_name;
grant debug connect session to &&user_name;
