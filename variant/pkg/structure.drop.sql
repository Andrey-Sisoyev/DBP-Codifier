-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\c <<$db_name$>> user_db<<$db_name$>>_app<<$app_name$>>_owner

SET search_path TO sch_<<$app_name$>>; -- , comn_funs, public; -- sets only for current session

DELETE FROM dbp_packages WHERE package_name = '<<$pkg.name$>>'
                           AND package_version = '<<$pkg.ver$>>'
                           AND dbp_standard_version = '<<$pkg.std_ver$>>';

-- IF DROPPING CUSTOM ROLES/TABLESPACES, then don't forget to unregister
-- them (under application owner DB account) using
-- FUNCTION public.unregister_cwobj_thatwere_dependant_on_current_dbapp(
--        par_cwobj_name varchar
--      , par_cwobj_type t_clusterwide_obj_types
--      )
-- , where TYPE public.t_clusterwide_obj_types IS ENUM ('tablespace', 'role')

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

\i ../data/data.drop.sql

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

\echo NOTICE >>>>> structure.drop.sql [BEGIN]

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

ALTER TABLE named_in_languages
        DROP CONSTRAINT named_in_languages__lng_codekey;

ALTER TABLE names
        DROP CONSTRAINT named_in_languages__entity_codekey;

ALTER TABLE codes_names ALTER COLUMN entity DROP DEFAULT;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

\i functions.drop.sql
\i triggers.drop.sql

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

DROP INDEX IF EXISTS codifiers_idx;
DROP INDEX IF EXISTS codestexts_in_codes_idx;

DROP TABLE IF EXISTS codes_names;

DROP RULE  IF EXISTS lngnames_ins_protection ON named_in_languages;
DROP RULE  IF EXISTS lngnames_upd_protection ON named_in_languages;
DROP RULE  IF EXISTS lngnames_del_protection ON named_in_languages;

DROP TABLE IF EXISTS named_in_languages;

DROP RULE  IF EXISTS names_ins_protection ON names;
DROP RULE  IF EXISTS names_upd_protection ON names;
DROP RULE  IF EXISTS names_del_protection ON names;

DROP TABLE IF EXISTS names;

DROP TABLE IF EXISTS codes_tree;
DROP TABLE IF EXISTS codes;

DROP SEQUENCE IF EXISTS codifiers_ids_seq;
DROP SEQUENCE IF EXISTS plain_codes_ids_seq;
DROP SEQUENCE IF EXISTS languages_ids_seq;
DROP SEQUENCE IF EXISTS namentities_ids_seq;

DROP TYPE IF EXISTS code_type CASCADE;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

\echo NOTICE >>>>> structure.drop.sql [END]