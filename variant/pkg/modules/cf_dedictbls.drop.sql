-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- (1) case sensetive (2) postgres lowercases real names
\c <<$db_name$>> user_db<<$db_name$>>_app<<$app_name$>>_owner

SET search_path TO sch_<<$app_name$>>, comn_funs, public; -- sets only for current session
\set ECHO none

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

\echo NOTICE >>>>> cf_dedictbls.drop.sql [BEGIN]

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

DROP FUNCTION IF EXISTS remove_dedicated_codifiertable(par_cf_key t_code_key_by_lng, par_tablename regclass, par_drop_table boolean);
DROP FUNCTION IF EXISTS new_dedicated_codifiertable(par_cf_key t_code_key_by_lng, par_tablename name, par_table_exists boolean, par_fullindexing boolean);
DROP FUNCTION IF EXISTS dedicated_codifiertable_by_tabname(par_table_name regclass);
DROP FUNCTION IF EXISTS check_cf_accord_w_dedicated_codifiertable(par_dedicated_codifiertable_id integer, par_codifier_key t_code_key, par_table_oid oid);
DROP FUNCTION IF EXISTS tableoid_is_in_this_schema(par_table_oid oid);
DROP FUNCTION IF EXISTS dct_row_belongsnot_to_codifiers(par_table_oid oid, par_code_id integer);
DROP FUNCTION IF EXISTS dct_code_text_is_valid(par_code_id integer, par_code_text varchar);

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> cf_dedictbls.drop.sql [END]
