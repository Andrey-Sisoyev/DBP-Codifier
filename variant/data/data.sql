-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
-- 
-- All rights reserved.
-- 
-- For information about license see COPYING file in the root directory of current nominal package

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\c <<$db_name$>> user_<<$app_name$>>_owner
SET search_path TO sch_<<$app_name$>>, public; 

-- INSERT INTO ...

-- root codifier                       : 0
-- codifier of usual codifiers         : 1
-- codifier of status sets             : 2
-- codifier of other types of codifiers: 3

\set ECHO queries

SELECT remove_codifier_bystr(TRUE, 'Usual codifiers');
SELECT remove_codifier_bystr(TRUE, 'Statuses sets');
SELECT remove_codifier_bystr(TRUE, 'Other types of codifiers');
SELECT remove_codifier_bystr(TRUE, 'Common nominal codes');

ALTER SEQUENCE codifiers_ids_seq   MINVALUE 1 INCREMENT BY 1 RESTART WITH 1;
ALTER SEQUENCE plain_codes_ids_seq MINVALUE 1 INCREMENT BY 1 RESTART WITH 50;

SELECT new_codifier_w_subcodes(
          'Root codifier'                         :: varchar                   -- parent of codifier
        , ROW ('Usual codifiers', 'metacodifier' :: code_type) :: code_construction_input
        , NULL                                    :: varchar                   -- default code
        , VARIADIC ARRAY[]                        :: code_construction_input[] -- subcodes
        );

SELECT new_codifier_w_subcodes(
          'Root codifier'                       :: varchar                   -- parent of codifier
        , ROW ('Statuses sets', 'metacodifier' :: code_type) :: code_construction_input   -- new codifier
        , NULL                                  :: varchar                   -- default code
        , VARIADIC ARRAY[]                      :: code_construction_input[] -- subcodes
        );

SELECT new_codifier_w_subcodes(
          'Root codifier'                       :: varchar                   -- parent of codifier
        , ROW ('Complex codes', 'metacodifier' :: code_type) :: code_construction_input   -- new codifier
        , NULL                                  :: varchar                   -- default code
        , VARIADIC ARRAY[]                      :: code_construction_input[] -- subcodes
        );

SELECT new_codifier_w_subcodes(
          'Usual codifiers' :: varchar                   -- parent of codifier
        , ROW ('Common nominal codes', 'codifier' :: code_type) :: code_construction_input   -- new codifier
        , NULL              :: varchar                   -- default code
        , VARIADIC ARRAY[ ROW ('undefined'   , 'plain code' :: code_type) :: code_construction_input
                        , ROW ('unclassified', 'plain code' :: code_type) :: code_construction_input
                        , ROW ('error'       , 'plain code' :: code_type) :: code_construction_input
                        , ROW ('ambiguous'   , 'plain code' :: code_type) :: code_construction_input
	                ]   :: code_construction_input[] -- subcodes
        );

ALTER SEQUENCE codifiers_ids_seq   MINVALUE 100   INCREMENT BY 10 RESTART WITH 100;
ALTER SEQUENCE plain_codes_ids_seq MINVALUE 10000 INCREMENT BY 10 RESTART WITH 10000;

INSERT INTO codes_names (
        code_id
      , entity
      , lng_of_name
      , name
      , description
) VALUES 
        (0,  'metacodifier', 'eng', 'Root codifier'                  , 'Root codifier of all codifiers. Known codes: 0, 1, 2, 3.')
      , (1,  'metacodifier', 'eng', 'Metacodifier of usual codifiers', 'Codifier of usual codifiers.')
      , (2,  'metacodifier', 'eng', 'Metacodifier of statuses sets'  , 'Codifier of statuses sets.')
      , (3,  'metacodifier', 'eng', 'Metacodifier of complex codes'  , 'Codifier of other types of codifiers (not statuses sets, nor usual codifiers).')
      , (4,  'codifier'    , 'eng', 'Common nominal codes'           , 'Codifier of codes generally shared by lots of different codifiers.')
      , (50, 'code'        , 'eng', 'Undefined'                      , 'To be usable in codifiers, that allow users not to determine code.')
      , (51, 'code'        , 'eng', 'Unclassified'                   , 'To be usable in codifiers, that do not cover all possible codes, and allow not covered cases.')
      , (52, 'code'        , 'eng', 'Error'                          , 'To be usable in codifiers, that allow errors in the determination of codes.')
      , (53, 'code'        , 'eng', 'Ambiguous'                      , 'To be usable in codifiers, that allow ambiguousity in the determination of codes.')
      ;
