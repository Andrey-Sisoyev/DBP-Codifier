-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
-- 
-- All rights reserved.
-- 
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- (1) case sensetive (2) postgres lowercases real names
\c <<$db_name$>> user_<<$db_name$>>_owner
DROP SCHEMA IF EXISTS sch_<<$app_name$>>;

DROP TABLESPACE IF EXISTS tabsp_<<$db_name$>>_<<$app_name$>>;
DROP TABLESPACE IF EXISTS tabsp_<<$db_name$>>_<<$app_name$>>_idxs;

\! rm -rf <<$PGDATA$>>pg_tblspc/<<$db_name$>>/<<$app_name$>>/tabsp.data
\! rm -rf <<$PGDATA$>>pg_tblspc/<<$db_name$>>/<<$app_name$>>/tabsp_idxs.data

DROP ROLE IF EXISTS user_<<$app_name$>>_owner;
DROP ROLE IF EXISTS user_<<$app_name$>>_data_admin;
DROP ROLE IF EXISTS user_<<$app_name$>>_data_reader;

---------------------------------
---------------------------------
---------------------------------

CREATE ROLE user_<<$app_name$>>_owner 
   WITH LOGIN
        UNENCRYPTED PASSWORD 'app_owner_password';

CREATE ROLE user_<<$app_name$>>_data_admin 
   WITH LOGIN
        UNENCRYPTED PASSWORD 'app_data_admin_password';

CREATE ROLE user_<<$app_name$>>_data_reader 
   WITH LOGIN
        UNENCRYPTED PASSWORD 'app_data_reader_password';


\! mkdir <<$PGDATA$>>pg_tblspc/<<$db_name$>>
\! mkdir <<$PGDATA$>>pg_tblspc/<<$db_name$>>/<<$app_name$>>
\! mkdir <<$PGDATA$>>pg_tblspc/<<$db_name$>>/<<$app_name$>>/tabsp.data
\! mkdir <<$PGDATA$>>pg_tblspc/<<$db_name$>>/<<$app_name$>>/tabsp_idxs.data

CREATE TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>> 
        OWNER user_<<$app_name$>>_owner 
        LOCATION '<<$PGDATA$>>pg_tblspc/<<$db_name$>>/<<$app_name$>>/tabsp.data';

CREATE TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs
        OWNER user_<<$app_name$>>_owner 
        LOCATION '<<$PGDATA$>>pg_tblspc/<<$db_name$>>/<<$app_name$>>/tabsp_idxs.data';

-------------------------

GRANT CONNECT ON DATABASE <<$db_name$>> TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_owner, user_<<$app_name$>>_data_reader;

-------------------------
-- (1) case sensetive (2) postgres lowercases real names
\c <<$db_name$>> user_<<$db_name$>>_owner

CREATE SCHEMA sch_<<$app_name$>> AUTHORIZATION user_<<$app_name$>>_owner;

GRANT USAGE ON SCHEMA sch_<<$app_name$>> TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
