-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\c <<$db_name$>> user_db<<$db_name$>>_app<<$app_name$>>_owner
SET search_path TO sch_<<$app_name$>>, comn_funs, public;
--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> data.drop.sql [BEGIN]

SELECT pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__initial_data_delete__();
DROP FUNCTION IF EXISTS pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__initial_data_insert__();
DROP FUNCTION IF EXISTS pkg_<<$pkg.name_p$>>_<<$pkg.ver_p$>>__initial_data_delete__();

-- This is not obligate:
-- DELETE FROM dbp_helloworld;

\echo NOTICE >>>>> data.drop.sql [END]