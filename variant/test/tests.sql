-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
-- 
-- All rights reserved.
-- 
-- For information about license see COPYING file in the root directory of current nominal package

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\c <<$db_name$>> user_<<$app_name$>>_owner

SET search_path TO sch_<<$app_name$>>, public; -- sets only for current session
\set ECHO queries

SELECT * FROM codes;
SELECT * FROM codes_tree;
SELECT * FROM codes_names;

SELECT get_code_by_codeid(2);
SELECT get_nonplaincode_by_codestr('Statuses sets');
SELECT type_of_code(2);
SELECT get_codified_view_by_codestr('Root codifier', 'Statuses sets');

--------

SELECT new_codifier(ROW('test codifier', 'codifier'), (get_nonplaincode_by_codestr('Root codifier')).code_id );

SELECT new_code(ROW('test code 1', 'plain code'), (get_nonplaincode_by_codestr('test codifier')).code_id);
SELECT new_code(ROW('test code 2', 'codifier')  , (get_nonplaincode_by_codestr('test codifier')).code_id);
SELECT new_codifier(ROW('test code 3', 'metacodifier'), (get_nonplaincode_by_codestr('test code 2')).code_id);
\echo ---Tester: following command should rise an error.---
SELECT new_codifier(ROW('test code 4', 'plain code')  , (get_nonplaincode_by_codestr('test code 2')).code_id);
SELECT new_code(ROW('test code 5', 'plain code'), (get_nonplaincode_by_codestr('test code 2')).code_id );
SELECT new_code(ROW('test code 6', 'plain code'), (get_nonplaincode_by_codestr('test code 2')).code_id );
SELECT new_code(ROW('test code 7', 'plain code'), (get_nonplaincode_by_codestr('test code 2')).code_id );
SELECT new_code(ROW('test code 8', 'plain code'), (get_nonplaincode_by_codestr('test code 2')).code_id );

SELECT * FROM codes;
SELECT * FROM codes_tree;

-----------

SELECT make_codifier_from_plaincode(TRUE, (get_nonplaincode_by_codestr('test code 6')).code_id, 'metacodifier');
SELECT bind_code_to_codifier((get_codified_view_by_codestr('test code 2', 'test code 6')).subcode_id, (get_nonplaincode_by_codestr('Root codifier')).code_id, TRUE);
SELECT bind_code_to_codifier((get_nonplaincode_by_codestr('test codifier')).code_id, (get_codified_view_by_codestr('test code 2', 'test code 6')).subcode_id, TRUE);

SELECT * FROM codes;
SELECT * FROM codes_tree;

SELECT * FROM get_alldepths_subcodes_of_codifier((get_nonplaincode_by_codestr('test code 6')).code_id);
SELECT * FROM get_alldepths_subcodes_of_codifier((get_nonplaincode_by_codestr('test codifier')).code_id);

SELECT * FROM get_codes_of_codifier_byid((get_nonplaincode_by_codestr('test code 2')).code_id);
SELECT * FROM get_codes_of_codifier_bystr('test code 2');
SELECT * FROM get_codifiers_of_code_byid((get_nonplaincode_by_codestr('test code 6')).code_id);

\echo ---Tester: following command should rise an error.---
SELECT make_codifier_from_plaincode(TRUE, (get_codified_view_by_codestr('test code 2', 'test code 3')).subcode_id, 'codifier');

\echo ---Tester: following command should rise an error.---
SELECT add_subcodes_under_codifier_byid(
                (get_nonplaincode_by_codestr('test code 3')).code_id
              , 'test code 3.3' :: varchar
              , VARIADIC ARRAY[ ROW('test code 3.0', 'plain code')
                              , ROW('test code 3.100', 'plain code')
                              , ROW('test code 3.300', 'plain code')
                              ] :: code_construction_input[]
              );
SELECT add_subcodes_under_codifier_byid(
                (get_nonplaincode_by_codestr('test code 3')).code_id
              , 'test code 3.3' :: varchar
              , VARIADIC ARRAY[ ROW('test code 3.1', 'plain code')
                              , ROW('test code 3.2', 'plain code')
                              , ROW('test code 3.3', 'plain code')
                              ] :: code_construction_input[]
              );
\echo ---Tester: following command should rise an error.---
SELECT add_subcodes_under_codifier_bystr(
                'test code 3'   :: varchar
              , NULL            :: varchar
              , VARIADIC ARRAY[ ROW('test code 3.3', 'plain code')
                              , ROW('test code 3.4', 'plain code')
                              , ROW('test code 3.5', 'plain code')
                              ] :: code_construction_input[]
              );
\echo ---Tester: following command should rise an error.---
SELECT add_subcodes_under_codifier_bystr(
                'test code 3'   :: varchar
              , 'test code 3.4' :: varchar
              , VARIADIC ARRAY[ ROW('test code 3.4', 'plain code')
                              , ROW('test code 3.5', 'plain code')
                              ] :: code_construction_input[]
              );
SELECT add_subcodes_under_codifier_bystr(
                'test code 3'   :: varchar
              , NULL            :: varchar
              , VARIADIC ARRAY[ ROW('test code 3.6', 'codifier')
                              , ROW('test code 3.7', 'plain code')
                              ] :: code_construction_input[]
              );
\echo ---Tester: following command should rise an error.---
SELECT add_subcodes_under_codifier_bystr(
                'test code 100' :: varchar
              , NULL            :: varchar
              , VARIADIC ARRAY[ ROW('test code 3.6', 'codifier')
                              , ROW('test code 3.7', 'plain code')
                              ] :: code_construction_input[]
              );

\echo ---Tester: following command should rise an error.---
SELECT new_codifier(ROW('test code 3.6', 'codifier'), (get_nonplaincode_by_codestr('test code 2')).code_id);

\echo ---Tester: following command should rise an error.---
SELECT new_codifier_w_subcodes(
                'test code 3.6' :: varchar
              , ROW('test code 3.6.1', 'plain code') :: code_construction_input
              , NULL            :: varchar
              , VARIADIC ARRAY[ ROW('test code 3.6.1.1', 'plain code')
                              , ROW('test code 3.6.1.1', 'plain code')
                              ] :: code_construction_input[]
              );
SELECT new_codifier_w_subcodes(
                'test code 3.6' :: varchar
              , ROW('test code 3.6.1', 'codifier') :: code_construction_input
              , NULL            :: varchar
              , VARIADIC ARRAY[ ROW('test code 3.6.1.1', 'plain code')
                              , ROW('test code 3.6.1.2', 'plain code')
                              ] :: code_construction_input[]
              );

SELECT * FROM codes;
SELECT * FROM codes_tree;

SELECT make_codifier_from_plaincode_w_values(
          FALSE
        , (get_codified_view_by_codestr('test code 3', 'test code 3.3')).subcode_id
        , 'statuses-set'    :: code_type
        , 'test code 3.3.d' :: varchar
        , VARIADIC ARRAY[ ROW('test code 3.3.d', 'plain code')
                        , ROW('test code 3.3.a', 'plain code')
                        ]   :: code_construction_input[]
        );

SELECT new_code(ROW('test code 3.3.d', 'plain code'), (get_nonplaincode_by_codestr('test code 2')).code_id );
\echo ---Tester: following command should rise an error.---
SELECT bind_code_to_codifier((get_codified_view_by_codestr('test code 2', 'test code 3.3.d')).subcode_id, (get_nonplaincode_by_codestr('test code 3.3')).code_id, FALSE);

SELECT new_code(ROW('test code 3.3.c', 'plain code'), (get_nonplaincode_by_codestr('test code 2')).code_id );
\echo ---Tester: following command should rise an error.---
SELECT bind_code_to_codifier((get_codified_view_by_codestr('test code 2', 'test code 3.3.c')).subcode_id, (get_nonplaincode_by_codestr('test code 3.3')).code_id, TRUE);

SELECT codifier_default_code_byid(FALSE, (get_nonplaincode_by_codestr('test code 3.3')).code_id);
SELECT codifier_default_code_bystr(TRUE, 'test code 3.3');

SELECT * FROM codes;
SELECT * FROM codes_tree;

SELECT remove_code_byid((get_codified_view_by_codestr('test code 2', 'test code 3.3.c')).subcode_id);
\echo ---Tester: following command should rise an error.---
SELECT remove_code_bystr(FALSE, 'test code 2', 'test code 3.3.c');
SELECT remove_code_bystr(FALSE, 'test code 3.3', 'test code 3.3.d');

SELECT codifier_default_code_byid(TRUE, (get_nonplaincode_by_codestr('test code 3.3')).code_id);
SELECT codifier_default_code_bystr(FALSE, 'test code 3.3');

SELECT add_subcodes_under_codifier_byid(
                (get_nonplaincode_by_codestr('test code 3.3')).code_id
              , 'test code 3.3.g' :: varchar
              , VARIADIC ARRAY[ ROW('test code 3.3.g', 'plain code')
                              , ROW('test code 3.3.e', 'plain code')
                              ] :: code_construction_input[]
              );
SELECT codifier_default_code_bystr(FALSE, 'test code 3.3');
SELECT codifier_default_code_byid(FALSE, (get_nonplaincode_by_codestr('test code 3.3')).code_id);

SELECT make_codifier_from_plaincode_w_values(
          TRUE
        , (get_codified_view_by_codestr('test code 3.3', 'test code 3.3.g')).subcode_id
        , 'statuses-set'      :: code_type
        , 'test code 3.3.g.1' :: varchar
        , VARIADIC ARRAY[ ROW('test code 3.3.g.1', 'plain code')
                        , ROW('test code 3.3.g.2', 'plain code')
                        ]     :: code_construction_input[]
        );

SELECT bind_code_to_codifier((get_nonplaincode_by_codestr('test code 3.3')).code_id, (get_nonplaincode_by_codestr('test code 3.3.g')).code_id, FALSE);
SELECT unbind_code_from_codifier(TRUE, (get_nonplaincode_by_codestr('test code 3.3')).code_id, (get_nonplaincode_by_codestr('test code 3.3.g')).code_id);
\echo ---Tester: following command should rise an error.---
SELECT unbind_code_from_codifier(TRUE, (get_nonplaincode_by_codestr('test code 3.3')).code_id, (get_nonplaincode_by_codestr('test code 3.3.g')).code_id);
SELECT bind_code_to_codifier((get_nonplaincode_by_codestr('test code 3.3')).code_id, (get_nonplaincode_by_codestr('test code 3.3.g')).code_id, FALSE);

SELECT * FROM codes;
SELECT * FROM codes_tree;

SELECT * FROM get_alldepths_subcodes_of_codifier((get_nonplaincode_by_codestr('test code 3')).code_id);


\echo ---Tester: following command should rise an error.---
SELECT remove_subcodes_by_codifierid((get_nonplaincode_by_codestr('test code 3')).code_id, FALSE, FALSE);

SELECT remove_subcodes_by_codifierid((get_nonplaincode_by_codestr('test code 3')).code_id, TRUE, FALSE);
SELECT bind_code_to_codifier((get_codified_view_by_codestr('test code 2', 'test code 3.3.d')).subcode_id, (get_nonplaincode_by_codestr('test code 3')).code_id, TRUE);

\echo ---Tester: following command should rise an error.---
SELECT remove_code_bystr(FALSE, 'test code 2', 'test code 3.3.dz');
SELECT remove_code_bystr(TRUE, 'test code 2', 'test code 3.3.dz');
SELECT remove_code_bystr(FALSE, 'test code 2', 'test code 3.3.d');

SELECT remove_codifier_w_subcodes_byid((get_nonplaincode_by_codestr('test codifier')).code_id, TRUE, TRUE);

--------

ALTER SEQUENCE codifiers_ids_seq RESTART WITH 100;
ALTER SEQUENCE plain_codes_ids_seq RESTART WITH 10000;

SELECT * FROM codes;
SELECT * FROM codes_tree;
