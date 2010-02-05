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
SELECT remove_codifier_bystr(TRUE, 'Complex codes');
SELECT remove_codifier_bystr(TRUE, 'Common nominal codes sets');

ALTER SEQUENCE codifiers_ids_seq   MINVALUE 1 INCREMENT BY 1 RESTART WITH 1;
ALTER SEQUENCE plain_codes_ids_seq MINVALUE 1 INCREMENT BY 1 RESTART WITH 50;

SELECT new_codifier_w_subcodes(
          'Root'                                  :: varchar                   -- parent of codifier
        , ROW ('Usual codifiers', 'metacodifier' :: code_type) :: code_construction_input
        , NULL                                    :: varchar                   -- default code
        , VARIADIC ARRAY[]                        :: code_construction_input[] -- subcodes
        );

SELECT new_codifier_w_subcodes(
          'Root'                                :: varchar                   -- parent of codifier
        , ROW ('Statuses sets', 'metacodifier' :: code_type) :: code_construction_input   -- new codifier
        , NULL                                  :: varchar                   -- default code
        , VARIADIC ARRAY[]                      :: code_construction_input[] -- subcodes
        );

SELECT new_codifier_w_subcodes(
          'Root'                                :: varchar                   -- parent of codifier
        , ROW ('Complex codes', 'metacodifier' :: code_type) :: code_construction_input   -- new codifier
        , NULL                                  :: varchar                   -- default code
        , VARIADIC ARRAY[]                      :: code_construction_input[] -- subcodes
        );

SELECT new_codifier_w_subcodes(
          'Usual codifiers'  :: varchar                   -- parent of codifier
        , ROW ('System codifiers', 'metacodifier' :: code_type) :: code_construction_input   -- new codifier
        , NULL               :: varchar                   -- default code
        , VARIADIC ARRAY[]   :: code_construction_input[] -- subcodes
        );

SELECT new_codifier_w_subcodes(
          'System codifiers' :: varchar                   -- parent of codifier
        , ROW ('Common nominal codes set', 'codifier' :: code_type) :: code_construction_input   -- new codifier
        , NULL               :: varchar                   -- default code
        , VARIADIC ARRAY[ ROW ('undefined'   , 'plain code' :: code_type) :: code_construction_input
                        , ROW ('unclassified', 'plain code' :: code_type) :: code_construction_input
                        , ROW ('error'       , 'plain code' :: code_type) :: code_construction_input
                        , ROW ('ambiguous'   , 'plain code' :: code_type) :: code_construction_input
	                ]    :: code_construction_input[] -- subcodes
        );

ALTER SEQUENCE plain_codes_ids_seq MINVALUE 9000 INCREMENT BY 1 RESTART WITH 9000;

SELECT new_codifier_w_subcodes(
          'System codifiers'  :: varchar                   -- parent of codifier
        , ROW ('Languages', 'codifier' :: code_type) :: code_construction_input   -- new codifier
        , NULL                :: varchar                   -- default code
        , VARIADIC ARRAY[ ROW ('eng', 'plain code' :: code_type) :: code_construction_input
                        , ROW ('rus', 'plain code' :: code_type) :: code_construction_input
                        , ROW ('spa', 'plain code' :: code_type) :: code_construction_input
                        , ROW ('fra', 'plain code' :: code_type) :: code_construction_input
                        , ROW ('deu', 'plain code' :: code_type) :: code_construction_input
	                ]     :: code_construction_input[] -- subcodes
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
        (0,    'metacodifier' , language_code('eng'), 'Root'                     , 'A root codifier of all codes and codifiers.')
      , (1,    'metacodifier' , language_code('eng'), 'Usual codifiers'          , 'Directory of usual codifiers.')
      , (2,    'metacodifier' , language_code('eng'), 'Statuses sets'            , 'Directory of statuses sets.')
      , (3,    'metacodifier' , language_code('eng'), 'Complex codes'            , 'Directory of other types of codifiers (not statuses sets, nor usual codifiers).')
      , (4,    'metacodifier' , language_code('eng'), 'System codifiers'         , 'Directory of system codifiers - ones used by package itself.')
      , (5,    'codifier'     , language_code('eng'), 'Common nominal codes sets', 'Codifier of codes generally shared by lots of different codifiers.')
      , (6,    'codifier'     , language_code('eng'), 'Languages'                , 'Codifier of languages. Originally thought to be filled with ISO 639-3 codes, but not constrainted to. Nonnatural languages it is recommended to put in a subdirectory (create it yourself).')
      , (50,   'code'         , language_code('eng'), 'undefined'                , 'To be usable in codifiers, that allow users not to determine code.')
      , (51,   'code'         , language_code('eng'), 'unclassified'             , 'To be usable in codifiers, that do not cover all possible codes, and allow not covered cases.')
      , (52,   'code'         , language_code('eng'), 'error'                    , 'To be usable in codifiers, that allow errors in the determination of codes.')
      , (53,   'code'         , language_code('eng'), 'ambiguous'                , 'To be usable in codifiers, that allow ambiguousity in the determination of codes.')
      , (9000, 'language code', language_code('eng'), 'eng'                      , 'English language code from ISO 639-3.')
      , (9001, 'language code', language_code('eng'), 'rus'                      , 'Russian language code from ISO 639-3.')
      , (9002, 'language code', language_code('eng'), 'spa'                      , 'Spanish language code from ISO 639-3.')
      , (9003, 'language code', language_code('eng'), 'fra'                      , 'French language code from ISO 639-3.')
      , (9003, 'language code', language_code('eng'), 'deu'                      , 'German language code from ISO 639-3.')
      ;
