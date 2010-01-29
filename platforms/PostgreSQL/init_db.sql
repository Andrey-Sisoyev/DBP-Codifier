-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
-- 
-- All rights reserved.
-- 
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- \! clear

DROP DATABASE IF EXISTS <<$db_name$>>;
DROP TABLESPACE IF EXISTS tabsp_<<$db_name$>>_dflt;
DROP ROLE IF EXISTS user_<<$db_name$>>_owner;

\! rm -rf <<$PGDATA$>>pg_tblspc/<<$db_name$>>/default.data

---------------------------------
---------------------------------
---------------------------------

CREATE ROLE user_<<$db_name$>>_owner 
   WITH SUPERUSER 
        NOCREATEDB
        LOGIN
        CREATEROLE
        UNENCRYPTED PASSWORD 'db_owner_password';

\! mkdir <<$PGDATA$>>pg_tblspc/<<$db_name$>>
\! mkdir <<$PGDATA$>>pg_tblspc/<<$db_name$>>/default.data

CREATE TABLESPACE tabsp_<<$db_name$>>_dflt
   OWNER user_<<$db_name$>>_owner
   LOCATION '<<$PGDATA$>>pg_tblspc/<<$db_name$>>/default.data';
   
-------------------------

CREATE DATABASE <<$db_name$>>
  WITH OWNER = user_<<$db_name$>>_owner 
       ENCODING = 'UTF8'
       TABLESPACE = tabsp_<<$db_name$>>_dflt;

-------------------------
-- (1) case sensetive (2) postgres lowercases real names
\c <<$db_name$>> user_<<$db_name$>>_owner

CREATE LANGUAGE plpgsql;
