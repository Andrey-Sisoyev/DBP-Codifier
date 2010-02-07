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

SELECT remove_code(TRUE, make_acodekeyl_bystr1('Root'), TRUE, TRUE, FALSE);

INSERT INTO codes (code_id, code_type, code_text) VALUES (0, 'metacodifier', 'Root');

ALTER SEQUENCE codifiers_ids_seq   MINVALUE 1 INCREMENT BY 1 RESTART WITH 1;
ALTER SEQUENCE plain_codes_ids_seq MINVALUE 1 INCREMENT BY 1 RESTART WITH 50;

SELECT new_codifier_w_subcodes(
          make_codekeyl_bystr('Root')                   -- parent of codifier
        , ROW ('Usual codifiers', 'metacodifier' :: code_type) :: code_construction_input
        , NULL             :: varchar                   -- default code
        , VARIADIC ARRAY[] :: code_construction_input[] -- subcodes
        );

SELECT new_codifier_w_subcodes(
          make_codekeyl_bystr('Root')                              -- parent of codifier
        , ROW ('Statuses sets', 'metacodifier' :: code_type) :: code_construction_input   -- new codifier
        , NULL             :: varchar                   -- default code
        , VARIADIC ARRAY[] :: code_construction_input[] -- subcodes
        );

SELECT new_codifier_w_subcodes(
          make_codekeyl_bystr('Root')                   -- parent of codifier
        , ROW ('Complex codes', 'metacodifier' :: code_type) :: code_construction_input   -- new codifier
        , NULL             :: varchar                   -- default code
        , VARIADIC ARRAY[] :: code_construction_input[] -- subcodes
        );

SELECT new_codifier_w_subcodes(
          make_codekeyl_bystr('Root')                   -- parent of codifier
        , ROW ('System codifiers', 'metacodifier' :: code_type) :: code_construction_input   -- new codifier
        , NULL             :: varchar                   -- default code
        , VARIADIC ARRAY[] :: code_construction_input[] -- subcodes
        );

SELECT new_codifier_w_subcodes(
          make_codekeyl_bystr('System codifiers')      -- parent of codifier
        , ROW ('Common nominal codes set', 'codifier' :: code_type) :: code_construction_input   -- new codifier
        , NULL            :: varchar                   -- default code
        , VARIADIC ARRAY[ ROW ('undefined'   , 'plain code' :: code_type) :: code_construction_input
                        , ROW ('unclassified', 'plain code' :: code_type) :: code_construction_input
                        , ROW ('error'       , 'plain code' :: code_type) :: code_construction_input
                        , ROW ('ambiguous'   , 'plain code' :: code_type) :: code_construction_input
	                ] :: code_construction_input[] -- subcodes
        );

SELECT new_codifier_w_subcodes(
          make_codekeyl_bystr('System codifiers')      -- parent of codifier
        , ROW ('Languages', 'codifier' :: code_type) :: code_construction_input   -- new codifier
        , NULL            :: varchar                   -- default code
        , VARIADIC ARRAY[
                        ] :: code_construction_input[] -- subcodes
        );

SELECT new_codifier_w_subcodes(
          make_codekeyl_bystr('System codifiers')      -- parent of codifier
        , ROW ('Entities', 'codifier' :: code_type) :: code_construction_input   -- new codifier
        , NULL            :: varchar                   -- default code
        , VARIADIC ARRAY[
	                ] :: code_construction_input[] -- subcodes
        );

ALTER SEQUENCE codifiers_ids_seq   MINVALUE 100   INCREMENT BY 10 RESTART WITH 100;
ALTER SEQUENCE plain_codes_ids_seq MINVALUE 10000 INCREMENT BY 10 RESTART WITH 10000;

SELECT new_code_by_userseqs(ROW ('eng', 'plain code' :: code_type) :: code_construction_input, make_codekeyl_bystr('Languages'), TRUE , '', 'languages_ids_seq') AS eng_id
     , new_code_by_userseqs(ROW ('rus', 'plain code' :: code_type) :: code_construction_input, make_codekeyl_bystr('Languages'), FALSE, '', 'languages_ids_seq') AS rus_id
     , new_code_by_userseqs(ROW ('spa', 'plain code' :: code_type) :: code_construction_input, make_codekeyl_bystr('Languages'), FALSE, '', 'languages_ids_seq') AS spa_id
     , new_code_by_userseqs(ROW ('fra', 'plain code' :: code_type) :: code_construction_input, make_codekeyl_bystr('Languages'), FALSE, '', 'languages_ids_seq') AS fra_id
     , new_code_by_userseqs(ROW ('deu', 'plain code' :: code_type) :: code_construction_input, make_codekeyl_bystr('Languages'), FALSE, '', 'languages_ids_seq') AS deu_id
     ;
SELECT bind_code_to_codifier(
                make_acodekeyl_bystr2('Common nominal codes set', 'undefined')
              , make_codekeyl_bystr('Languages')
              , FALSE
              )
     , bind_code_to_codifier(
                make_acodekeyl_bystr2('Common nominal codes set', 'unclassified')
              , make_codekeyl_bystr('Languages')
              , FALSE
              );

SELECT new_code_by_userseqs(ROW ('code', 'plain code' :: code_type) :: code_construction_input, make_codekeyl_bystr('Entities'), FALSE, '', 'entities_ids_seq') AS code_entity_id;

SELECT add_code_lng_names(FALSE, make_acodekeyl_bystr1('Root')                                         , VARIADIC ARRAY[ mk_name_construction_input(make_codekeyl_bystr('eng'), 'Root'                     , make_codekeyl_null(), 'The root codifier of all codes and codifiers.') ] )
     , add_code_lng_names(FALSE, make_acodekeyl_bystr2('Root', 'Usual codifiers')                      , VARIADIC ARRAY[ mk_name_construction_input(make_codekeyl_bystr('eng'), 'Usual codifiers'          , make_codekeyl_null(), 'Directory of usual codifiers.') ] )
     , add_code_lng_names(FALSE, make_acodekeyl_bystr2('Root', 'Statuses sets')                        , VARIADIC ARRAY[ mk_name_construction_input(make_codekeyl_bystr('eng'), 'Statuses sets'            , make_codekeyl_null(), 'Directory of statuses sets.') ] )
     , add_code_lng_names(FALSE, make_acodekeyl_bystr2('Root', 'Complex codes')                        , VARIADIC ARRAY[ mk_name_construction_input(make_codekeyl_bystr('eng'), 'Complex codes'            , make_codekeyl_null(), 'Directory of other types of codifiers (not statuses sets, nor usual codifiers).') ] )
     , add_code_lng_names(FALSE, make_acodekeyl_bystr2('Root', 'System codifiers')                     , VARIADIC ARRAY[ mk_name_construction_input(make_codekeyl_bystr('eng'), 'System codifiers'         , make_codekeyl_null(), 'Directory of system codifiers - ones used by package itself. These codifiers are welcome to be used for user needs, the only constraint tht implies from being anything in this "directory": do not delete anything here, if you don''t want to have unpleasant surprises from package functions.') ] )

     , add_code_lng_names(FALSE, make_acodekeyl_bystr2('System codifiers', 'Common nominal codes set') , VARIADIC ARRAY[ mk_name_construction_input(make_codekeyl_bystr('eng'), 'Common nominal codes set' , make_codekeyl_null(), 'Codifier of codes generally shared by lots of different codifiers.') ] )
     , add_code_lng_names(FALSE, make_acodekeyl_bystr2('System codifiers', 'Languages')                , VARIADIC ARRAY[ mk_name_construction_input(make_codekeyl_bystr('eng'), 'Languages'                , make_codekeyl_null(), E'Codifier of languages. Originally thought to be filled with ISO 639-3 codes, but not constrainted to. Nonnatural languages it is recommended to put in a subdirectory (create it yourself). However (es for v0.5 of Codifier package), the function is not yet provided that would check, if code belongs to codifier across more than 1 level, but it will be written soon.\nTo add new language use following function call template: "SELECT new_code_by_userseqs(ROW (''<your_language>'', ''plain code'' :: code_type) :: code_construction_input, make_codekeyl_bystr(''Languages''), FALSE, '''', ''languages_ids_seq'') AS new_language_id";') ] )
     , add_code_lng_names(FALSE, make_acodekeyl_bystr2('System codifiers', 'Entities')                 , VARIADIC ARRAY[ mk_name_construction_input(make_codekeyl_bystr('eng'), 'Entities'                 , make_codekeyl_null(), E'Codifier of entities. Used in table "names" and by it''s ancestors.To add new language use following function call template: "SELECT new_code_by_userseqs(ROW (''<your_entity>'', ''plain code'' :: code_type) :: code_construction_input, make_codekeyl_bystr(''Entities''), FALSE, '''', ''entities_ids_seq'') AS new_entity_id;"') ] )

     , add_code_lng_names(FALSE, make_acodekeyl_bystr2('Common nominal codes set', 'undefined')        , VARIADIC ARRAY[ mk_name_construction_input(make_codekeyl_bystr('eng'), 'undefined'                , make_codekeyl_null(), 'To be usable in codifiers, that allow users not to determine code.') ] )
     , add_code_lng_names(FALSE, make_acodekeyl_bystr2('Common nominal codes set', 'unclassified')     , VARIADIC ARRAY[ mk_name_construction_input(make_codekeyl_bystr('eng'), 'unclassified'             , make_codekeyl_null(), 'To be usable in codifiers, that do not cover all possible codes, and allow not covered cases. Usage of such codes shows up cases, when better classification of domain area objects could be performed.') ] )
     , add_code_lng_names(FALSE, make_acodekeyl_bystr2('Common nominal codes set', 'error')            , VARIADIC ARRAY[ mk_name_construction_input(make_codekeyl_bystr('eng'), 'error'                    , make_codekeyl_null(), 'To be usable in codifiers, that allow errors in the determination of codes.') ] )
     , add_code_lng_names(FALSE, make_acodekeyl_bystr2('Common nominal codes set', 'ambiguous')        , VARIADIC ARRAY[ mk_name_construction_input(make_codekeyl_bystr('eng'), 'ambiguous'                , make_codekeyl_null(), 'To be usable in codifiers, that allow ambiguousity in the determination of codes. Usage of such codes usually means, that a better normalization could be performed on user DB.') ] )

     , add_code_lng_names(FALSE, make_acodekeyl_bystr2('Languages', 'eng')                             , VARIADIC ARRAY[ mk_name_construction_input(make_codekeyl_bystr('eng'), 'eng'                      , make_codekeyl_null(), 'English language code from ISO 639-3.')
                                                                                                                       , mk_name_construction_input(make_codekeyl_bystr('rus'), 'анг'                      , make_codekeyl_null(), 'Код-аббревиатура английского языка.'  ) ] )
     , add_code_lng_names(FALSE, make_acodekeyl_bystr2('Languages', 'rus')                             , VARIADIC ARRAY[ mk_name_construction_input(make_codekeyl_bystr('eng'), 'rus'                      , make_codekeyl_null(), 'Russian language code from ISO 639-3.')
                                                                                                                       , mk_name_construction_input(make_codekeyl_bystr('rus'), 'рус'                      , make_codekeyl_null(), 'Код-аббревиатура русского языка.'     ) ] )
     , add_code_lng_names(FALSE, make_acodekeyl_bystr2('Languages', 'spa')                             , VARIADIC ARRAY[ mk_name_construction_input(make_codekeyl_bystr('eng'), 'spa'                      , make_codekeyl_null(), 'Spanish language code from ISO 639-3.')
                                                                                                                       , mk_name_construction_input(make_codekeyl_bystr('rus'), 'исп'                      , make_codekeyl_null(), 'Код-аббревиатура испанского языка.'   ) ] )
     , add_code_lng_names(FALSE, make_acodekeyl_bystr2('Languages', 'fra')                             , VARIADIC ARRAY[ mk_name_construction_input(make_codekeyl_bystr('eng'), 'fra'                      , make_codekeyl_null(), 'French language code from ISO 639-3.' )
                                                                                                                       , mk_name_construction_input(make_codekeyl_bystr('rus'), 'фра'                      , make_codekeyl_null(), 'Код-аббревиатура французского языка.' ) ] )
     , add_code_lng_names(FALSE, make_acodekeyl_bystr2('Languages', 'deu')                             , VARIADIC ARRAY[ mk_name_construction_input(make_codekeyl_bystr('eng'), 'deu'                      , make_codekeyl_null(), 'German language code from ISO 639-3.' )
                                                                                                                       , mk_name_construction_input(make_codekeyl_bystr('rus'), 'нем'                      , make_codekeyl_null(), 'Код-аббревиатура немецкого языка.'    ) ] )

     , add_code_lng_names(FALSE, make_acodekeyl_bystr2('Entities', 'code')                             , VARIADIC ARRAY[ mk_name_construction_input(make_codekeyl_bystr('eng'), 'code'                     , make_codekeyl_null(), 'Code is an entity of this DB used for making tree-like graphs of constants. The branch that has leafs and other subbranches is called codifier, the code that has only subbranches and no lefs - metacodifier, the code that can''t have any substructures is called "plain code".') ] )
     ;

