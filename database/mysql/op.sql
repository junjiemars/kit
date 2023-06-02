-- create database
drop database if exists hi;
create database if not exists hi;

use hi;

-- create user
drop user if exists 'user'@'%';
create user if not exists 'hi'@'%' identified by 'hello';

select `user`, `host` from mysql.user;

-- grant permission
grant all on hi.* to 'hi'@'%';

show grants for 'hi'@'%';
