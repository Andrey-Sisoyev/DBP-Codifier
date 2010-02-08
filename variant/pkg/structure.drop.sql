-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For information about license see COPYING file in the root directory of current nominal package

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\c <<$db_name$>> user_<<$app_name$>>_owner

SET search_path TO sch_<<$app_name$>>, public; -- sets only for current session

DELETE FROM dbp_packages WHERE package_name = '<<$pkg.name$>>'
                           AND package_version = '<<$pkg.ver$>>'
                           AND dbp_standard_version = '<<$pkg.std_ver$>>';

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

ALTER TABLE named_in_languages
        DROP CONSTRAINT named_in_languages__lng_codekey;

ALTER TABLE names
        DROP CONSTRAINT named_in_languages__entity_codekey;

ALTER TABLE codes_names ALTER COLUMN entity DROP DEFAULT;

\i functions.drop.sql

DROP TRIGGER IF EXISTS tri_codes_tree_onmodify ON codes_tree;
DROP TRIGGER IF EXISTS tri_codes_onmodify ON codes;

DROP FUNCTION IF EXISTS codes_onmodify();
DROP FUNCTION IF EXISTS codes_tree_onmodify();

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
