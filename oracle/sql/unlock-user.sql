
--------------------------------------------------
-- author: junjiemars@gmail.com
-- target: unlock user
--------------------------------------------------

--define user_name=hr
--define user_password=hr

alter user &&user_name identified by &&user_password;
alter user &&user_name account unlock;


-- alter user system identified by oracle;
