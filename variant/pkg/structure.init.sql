-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\c <<$db_name$>> user_db<<$db_name$>>_app<<$app_name$>>_owner

SET search_path TO sch_<<$app_name$>>, comn_funs, public; -- sets only for current session
\set ECHO none

INSERT INTO dbp_packages (package_name, package_version, dbp_standard_version)
                   VALUES('<<$pkg.name$>>', '<<$pkg.ver$>>', '<<$pkg.std_ver$>>');

-- ^^^ don't change this !!
--
-- IF CREATING NEW CUSTOM ROLES/TABLESPACES, then don't forget to register
-- them (under application owner DB account) using
-- FUNCTION public.register_cwobj_tobe_dependant_on_current_dbapp(
--        par_cwobj_name              varchar
--      , par_cwobj_type              t_clusterwide_obj_types
--      , par_cwobj_additional_data_1 varchar
--      , par_application_name        varchar
--      , par_drop_it_by_cascade_when_dropping_db  boolean
--      , par_drop_it_by_cascade_when_dropping_app boolean
--      )
-- , where TYPE public.t_clusterwide_obj_types IS ENUM ('tablespace', 'role')

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
\echo NOTICE >>>>> structure.init.sql [BEGIN]

CREATE TYPE code_type AS ENUM ('metacodifier', 'codifier', 'statuses-set', 'composite code part', 'plain code', 'undefined', 'unclassified');

COMMENT ON TYPE code_type IS
'Type "plain code" is special. Code of such type can''t have subcodes.
';

-- one hunded sch_<<$app_name$>>.codes reserved for the most fundamental codifiers roots
CREATE SEQUENCE codifiers_ids_seq -- WARNING!!! Some alterations are there in the data.sql
        INCREMENT BY 1
        MINVALUE 1000
        MAXVALUE 79999 -- 80000-99999 reserved fo languages and nameable entities
        START WITH 1000
        NO CYCLE;

-- one hunded sch_<<$app_name$>>.codes reserved for the most fundamental codifiers roots
CREATE SEQUENCE plain_codes_ids_seq
        INCREMENT BY 10
        MINVALUE 100000
        START WITH 100000
        NO CYCLE;

CREATE TABLE codes (
        code_id            integer   NOT NULL PRIMARY KEY
      , code_type          code_type NOT NULL
      , code_text          varchar   NOT NULL
      , additional_field_1 varchar       NULL
      , additional_field_2 varchar       NULL
      , additional_field_3 varchar       NULL
      , additional_field_4 varchar       NULL
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

CREATE INDEX codestexts_in_codes_idx ON codes(code_text) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;

CREATE TABLE codes_tree (
        supercode_id       integer NOT NULL REFERENCES codes (code_id) ON DELETE CASCADE ON UPDATE CASCADE
      , subcode_id         integer NOT NULL REFERENCES codes (code_id) ON DELETE CASCADE ON UPDATE CASCADE
      , dflt_subcode_isit  boolean NOT NULL DEFAULT FALSE
      , additional_field_1 varchar       NULL
      , additional_field_2 varchar       NULL
      , additional_field_3 varchar       NULL
      , additional_field_4 varchar       NULL
      , PRIMARY KEY (supercode_id, subcode_id)
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

CREATE INDEX codifiers_idx ON codes_tree(supercode_id) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;

-------------------------------------

-- one hunded sch_<<$app_name$>>.codes reserved for the most fundamental codifiers roots
CREATE SEQUENCE languages_ids_seq -- WARNING!!! Some alterations are there in the data.sql
        INCREMENT BY 1
        MINVALUE 80000
        MAXVALUE 89999
        START WITH 80000
        NO CYCLE;

-- one hunded sch_<<$app_name$>>.codes reserved for the most fundamental codifiers roots
CREATE SEQUENCE namentities_ids_seq
        INCREMENT BY 1
        MINVALUE 90000
        MAXVALUE 99999
        START WITH 90000
        NO CYCLE;


CREATE TABLE names (
         name        varchar NOT NULL
       , description varchar     NULL
       , entity      integer NOT NULL
       , comments    varchar     NULL
       -- , FOREIGN KEY (entity) REFERENCES codes(code_id) ON DELETE RESTRICT ON UPDATE CASCADE
       -- Note: had to choose - either this FK, or RULE "names_upd_protection"
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

CREATE RULE names_ins_protection AS ON INSERT TO names DO INSTEAD NOTHING;
CREATE RULE names_upd_protection AS ON UPDATE TO names DO INSTEAD NOTHING;
CREATE RULE names_del_protection AS ON DELETE TO names DO INSTEAD NOTHING;

COMMENT ON TABLE names IS
'The table is totally abstract - you can''t INSERT, UPDATE or DELETE in it,
but use it as an ancestor in your child-tables, that need name, description
and/or comments.';

-------------------------------------

CREATE TABLE named_in_languages (
          lng_of_name integer
        -- , FOREIGN KEY (lng_of_name) REFERENCES codes(code_id) ON DELETE RESTRICT ON UPDATE CASCADE
        -- , FOREIGN KEY (entity)      REFERENCES codes(code_id) ON DELETE RESTRICT ON UPDATE CASCADE
        -- Note: had to choose - either these FKs, or RULE "lngnames_upd_protection"
) INHERITS (names)
  TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

CREATE RULE lngnames_ins_protection AS ON INSERT TO named_in_languages DO INSTEAD NOTHING;
CREATE RULE lngnames_upd_protection AS ON UPDATE TO named_in_languages DO INSTEAD NOTHING;
CREATE RULE lngnames_del_protection AS ON DELETE TO named_in_languages DO INSTEAD NOTHING;

COMMENT ON TABLE named_in_languages IS
'The table is totally abstract - you can''t INSERT, UPDATE or DELETE in it,
but use it as an ancestor in your child-tables, that need name, description
and/or comments in different languages.

A general template for child-tables of "named_in_languages":
======================================================
CREATE TABLE <your_object>s_names (
        <your_object>_id integer NOT NULL
      , PRIMARY KEY (<your_object>_id, lng_of_name)
      , FOREIGN KEY (<your_object>_id) REFERENCES <your_object>s(<your_object>_id)
                                                                 ON DELETE CASCADE  ON UPDATE CASCADE
      , FOREIGN KEY (lng_of_name)      REFERENCES codes(code_id) ON DELETE RESTRICT ON UPDATE CASCADE
      , FOREIGN KEY (entity)           REFERENCES codes(code_id) ON DELETE RESTRICT ON UPDATE CASCADE
) INHERITS (named_in_languages)
  TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

SELECT new_code_by_userseqs(
                ROW (''<your_object>'', ''plain code'' :: code_type) :: code_construction_input
              , make_codekeyl_bystr(''Named entities'')
              , FALSE
              , ''''
              , ''sch_<<$app_name$>>.namentities_ids_seq''
              ) AS <your_object>_entity_id;

ALTER TABLE <your_object>s_names ALTER COLUMN entity SET DEFAULT code_id_of_entity(''<your_object>'');
======================================================
Notice: if you inherit from both "names" and "named_in_languages", then it''s better to use "<your_object>s_names_in_lngs" instead of "<your_object>s_names" for child-tables of "named_in_languages".
';

CREATE TABLE codes_names (
        code_id     integer NOT NULL
      , PRIMARY KEY (code_id, lng_of_name)
      , FOREIGN KEY (code_id)     REFERENCES codes(code_id) ON DELETE CASCADE  ON UPDATE CASCADE
      , FOREIGN KEY (lng_of_name) REFERENCES codes(code_id) ON DELETE RESTRICT ON UPDATE CASCADE
      , FOREIGN KEY (entity)      REFERENCES codes(code_id) ON DELETE RESTRICT ON UPDATE CASCADE
) INHERITS (named_in_languages)
  TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

-------------------------------------

\echo NOTICE >>>>> structure.init.sql [END]

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

\i functions.init.sql

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

ALTER TABLE codes_names ALTER COLUMN entity SET DEFAULT code_id_of_entity('code');

ALTER TABLE names
        ADD CONSTRAINT named_in_languages__entity_codekey
                CHECK (code_belongs_to_codifier(
                                FALSE
                              , make_acodekeyl(
                                          make_codekey_null()
                                        , make_codekey_bystr('Named entities')
                                        , make_codekey_byid(entity)
                      )         )       );

ALTER TABLE named_in_languages
        ADD CONSTRAINT named_in_languages__lng_codekey
                CHECK (code_belongs_to_codifier(
                                FALSE
                              , make_acodekeyl(
                                          make_codekey_null()
                                        , make_codekey_bystr('Languages')
                                        , make_codekey_byid(lng_of_name)
                      )         )       );

-------------------------------------

GRANT USAGE ON SEQUENCE codifiers_ids_seq   TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT USAGE ON SEQUENCE plain_codes_ids_seq TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT USAGE ON SEQUENCE languages_ids_seq   TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT USAGE ON SEQUENCE namentities_ids_seq TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE codes              TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE codes_names        TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE codes_tree         TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE named_in_languages TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE codes_names        TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE names              TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;

GRANT SELECT                         ON TABLE codes              TO user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT SELECT                         ON TABLE codes_names        TO user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT SELECT                         ON TABLE codes_tree         TO user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT SELECT                         ON TABLE named_in_languages TO user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT SELECT                         ON TABLE codes_names        TO user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT SELECT                         ON TABLE names              TO user_db<<$db_name$>>_app<<$app_name$>>_data_reader;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Sometimes we want to insert some data, before creating triggers.

\i triggers.init.sql
\i ../data/data.init.sql