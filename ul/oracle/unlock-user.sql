-- unlock user

define user_name=hr
define user_password=hr

ALTER USER &&user_name IDENTIFIED BY &&user_password;
ALTER USER &&user_name ACCOUNT UNLOCK;

