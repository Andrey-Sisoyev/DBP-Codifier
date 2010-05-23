-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\c <<$db_name$>> user_db<<$db_name$>>_app<<$app_name$>>_owner

SELECT set_config('client_min_messages', 'NOTICE', FALSE);

\echo NOTICE >>>>>> tests.sql [BEGIN]
\echo WARNING!!! This tester is not guaranteed to be safe for user data (if not said otherwise in package info file) - do not apply it where user already defined it's codes!!

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo --------------------------------------------------------------
\echo NOTICE >>>>>> Just in case... if anything is lost, at least one will be able to recover it from log...

SELECT * FROM codes;
SELECT * FROM codes_tree;
SELECT * FROM codes_names;

---------

\echo =======Testing referencing functions=========================

\echo >>>>>Show code_key
SELECT show_codekey(make_codekey_null());
SELECT show_codekey(make_codekey_byid(777));
SELECT show_codekey(make_codekey_bystr('Hello!'));

\echo >>>>>Show addressed_code_key
SELECT show_acodekey(make_acodekey_null());
SELECT show_acodekey(make_acodekey(make_codekey_bystr('Codifier key!'), make_codekey_bystr('Code key!')));

\echo >>>>>Show code_key_by_language
SELECT show_codekeyl(make_codekeyl(make_codekey_bystr('Language key!'), make_codekey_bystr('Code key!')));
SELECT show_codekeyl(make_codekeyl_null());
SELECT show_codekeyl(make_codekeyl_byid(777));
SELECT show_codekeyl(make_codekeyl_bystr('Code key!'));
SELECT show_codekeyl(make_codekeyl_bystrl(make_codekey_bystr('Language key!'), 'Code key!'));

\echo >>>>>Show addressed_code_key_by_language
SELECT show_acodekeyl(make_acodekeyl_null());
SELECT show_acodekeyl(make_acodekeyl(make_codekey_bystr('Language key!'), make_codekey_bystr('Codifier key!'), make_codekey_bystr('Code key!')));
SELECT show_acodekeyl(make_acodekeyl_byid(777));
SELECT show_acodekeyl(make_acodekeyl_bystr1('Code key!'));
SELECT show_acodekeyl(make_acodekeyl_bystr2('Codifier key!', 'Code key!'));

\echo >>>>>Generalize code keys
SELECT show_acodekeyl(generalize_codekey(make_codekey_null()));
SELECT show_acodekeyl(generalize_codekey(make_codekey_byid(777)));
SELECT show_acodekeyl(generalize_codekey(make_codekey_bystr('Hello!')));
SELECT show_acodekeyl(generalize_acodekey(make_acodekey_null()));
SELECT show_acodekeyl(generalize_acodekey(make_acodekey(make_codekey_bystr('Codifier key!'), make_codekey_bystr('Code key!'))));
SELECT show_acodekeyl(generalize_codekeyl(make_codekeyl_null()));
SELECT show_acodekeyl(generalize_codekeyl(make_codekeyl(make_codekey_bystr('Language key!'), make_codekey_bystr('Code key!'))));
SELECT show_acodekeyl(generalize_codekey_wcf(make_codekey_bystr('Languages'), make_codekey_bystr('eng')));
SELECT show_acodekeyl(generalize_codekeyl_wcf(make_codekey_bystr('Languages'), make_codekeyl_bystr('eng')));

\echo >>>>>Type of code_key
SELECT 'undef'            = codekey_type(make_codekey_null());
SELECT 'c_id'             = codekey_type(make_codekey_byid(777));
SELECT 'c_nm (-l,-cf)'    = codekey_type(make_codekey_bystr('Hello!'));

\echo >>>>>Type of addressed_code_key
SELECT 'undef'            = acodekey_type(make_acodekey_null());
SELECT 'c_id'             = acodekey_type(make_acodekey(make_codekey_null(), make_codekey_byid(777)));
SELECT 'c_nm (-l,-cf)'    = acodekey_type(make_acodekey(make_codekey_null(), make_codekey_bystr('Code key!')));
SELECT 'c_nm (-l,+cf_id)' = acodekey_type(make_acodekey(make_codekey_byid(777), make_codekey_bystr('Code key!')));
SELECT 'c_nm (-l,+cf_nm)' = acodekey_type(make_acodekey(make_codekey_bystr('Codifier key!'), make_codekey_bystr('Code key!')));
SELECT 'cf_id'            = acodekey_type(make_acodekey(make_codekey_byid(777), make_codekey_null()));
SELECT 'cf_nm (-l)'       = acodekey_type(make_acodekey(make_codekey_bystr('Codifier key!'), make_codekey_null()));

\echo >>>>>Type of code_key_by_language
SELECT 'undef'            = codekeyl_type(make_codekeyl_null());
SELECT 'c_id'             = codekeyl_type(make_codekeyl_byid(777));
SELECT 'c_nm (-l,-cf)'    = codekeyl_type(make_codekeyl_bystr('Code key!'));
SELECT 'c_nm (+l_id,-cf)' = codekeyl_type(make_codekeyl_bystrl(make_codekey_byid(777), 'Code key!'));
SELECT 'c_nm (+l_nm,-cf)' = codekeyl_type(make_codekeyl_bystrl(make_codekey_bystr('Language key!'), 'Code key!'));

\echo >>>>>Type of addressed_code_key_by_language
SELECT 'undef'               = acodekeyl_type(make_acodekeyl_null());
SELECT 'c_id'                = acodekeyl_type(make_acodekeyl_byid(777));
SELECT 'c_nm (-l,-cf)'       = acodekeyl_type(make_acodekeyl_bystr1('Code key!'));
SELECT 'c_nm (-l,+cf_id)'    = acodekeyl_type(make_acodekeyl(make_codekey_null()                , make_codekey_byid(777)             , make_codekey_bystr('Code key!')));
SELECT 'c_nm (-l,+cf_nm)'    = acodekeyl_type(make_acodekeyl(make_codekey_null()                , make_codekey_bystr('Codifier key!'), make_codekey_bystr('Code key!')));
SELECT 'c_nm (+l_id,-cf)'    = acodekeyl_type(make_acodekeyl(make_codekey_byid(777)             , make_codekey_null()                , make_codekey_bystr('Code key!')));
SELECT 'c_nm (+l_id,+cf_id)' = acodekeyl_type(make_acodekeyl(make_codekey_byid(777)             , make_codekey_byid(777)             , make_codekey_bystr('Code key!')));
SELECT 'c_nm (+l_id,+cf_nm)' = acodekeyl_type(make_acodekeyl(make_codekey_byid(777)             , make_codekey_bystr('Codifier key!'), make_codekey_bystr('Code key!')));
SELECT 'c_nm (+l_nm,-cf)'    = acodekeyl_type(make_acodekeyl(make_codekey_bystr('Language key!'), make_codekey_null()                , make_codekey_bystr('Code key!')));
SELECT 'c_nm (+l_nm,+cf_id)' = acodekeyl_type(make_acodekeyl(make_codekey_bystr('Language key!'), make_codekey_byid(777)             , make_codekey_bystr('Code key!')));
SELECT 'c_nm (+l_nm,+cf_nm)' = acodekeyl_type(make_acodekeyl(make_codekey_bystr('Language key!'), make_codekey_bystr('Codifier key!'), make_codekey_bystr('Code key!')));
SELECT 'cf_id'               = acodekeyl_type(make_acodekeyl(make_codekey_null()                , make_codekey_byid(777)             , make_codekey_null()            ));
SELECT 'cf_nm (-l)'          = acodekeyl_type(make_acodekeyl(make_codekey_null()                , make_codekey_bystr('Codifier key!'), make_codekey_null()            ));
SELECT 'cf_nm (+l_id)'       = acodekeyl_type(make_acodekeyl(make_codekey_byid(777)             , make_codekey_bystr('Codifier key!'), make_codekey_null()            ));
SELECT 'cf_nm (+l_nm)'       = acodekeyl_type(make_acodekeyl(make_codekey_bystr('Language key!'), make_codekey_bystr('Codifier key!'), make_codekey_null()            ));

\echo =======Referencing functions tested==========================

\echo =======Testing administration and lookup functions===========

\c <<$db_name$>> user_db<<$db_name$>>_app<<$app_name$>>_owner

\set ECHO queries
SELECT set_config('client_min_messages', 'NOTICE', FALSE);

\set ECHO none
CREATE OR REPLACE FUNCTION remove_test_set() RETURNS integer
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        out_r RECORD;
BEGIN
        SELECT remove_code(TRUE, make_acodekeyl_bystr1('test codifier'), TRUE, TRUE, TRUE)
        INTO out_r; RAISE NOTICE 'Output(remove_test_set): %', out_r;

        DELETE FROM codes WHERE code_id in (SELECT lost.code_id FROM get_codes_l(make_codekeyl_bystr('306')) AS lost);

        RETURN NULL;
END;
$$;

\echo >>File: docs/models/Testing.CodesStructure.ver.odg

CREATE OR REPLACE FUNCTION create_test_set() RETURNS integer
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        out_r RECORD;
BEGIN
        PERFORM sch_<<$app_name$>>.remove_test_set();

        SELECT new_codifier_w_subcodes(
                        make_codekeyl_bystr('Root')
                      , ROW('test codifier', 'codifier') :: code_construction_input
                      , '101'
                      , VARIADIC ARRAY[
                                ROW('101', 'plain code')
                              , ROW('999', 'plain code')
                              ] :: code_construction_input[]
                      )
        INTO out_r; RAISE NOTICE 'Output(create_test_set): %', out_r;

        SELECT make_codifier_from_plaincode_w_values(
                        TRUE
                      , TRUE
                      , make_codekeyl_bystr('101')
                      , 'codifier'
                      , '201'
                      , VARIADIC ARRAY[
                                ROW('201', 'codifier')
                              , ROW('202', 'codifier')
                              , ROW('203', 'codifier')
                              , ROW('204', 'codifier')
                              , ROW('205', 'codifier')
                              , ROW('206', 'codifier')
                              , ROW('207', 'codifier')
                              , ROW('208', 'codifier')
                              , ROW('209', 'codifier')
                              ] :: code_construction_input[]
                      )
        INTO out_r; RAISE NOTICE 'Output(create_test_set): %', out_r;

        SELECT add_subcodes_under_codifier(
                        make_codekeyl_bystr('201')
                      , '301'
                      , VARIADIC ARRAY[
                                ROW('301', 'codifier')
                              , ROW('302', 'codifier')
                              , ROW('303', 'codifier')
                              , ROW('304', 'codifier')
                              ] :: code_construction_input[]
                      )
             , add_subcodes_under_codifier(
                        make_codekeyl_bystr('203')
                      , '305'
                      , VARIADIC ARRAY[
                                ROW('305', 'codifier')
                              , ROW('306', 'plain code')
                              ] :: code_construction_input[]
                      )
             , add_subcodes_under_codifier(
                        make_codekeyl_bystr('204')
                      , '307'
                      , VARIADIC ARRAY[
                                ROW('307', 'codifier')
                              , ROW('308', 'codifier')
                              ] :: code_construction_input[]
                      )
             , add_subcodes_under_codifier(
                        make_codekeyl_bystr('205')
                      , '309'
                      , VARIADIC ARRAY[
                                ROW('309', 'codifier')
                              , ROW('310', 'codifier')
                              ] :: code_construction_input[]
                      )
             , add_subcodes_under_codifier(
                        make_codekeyl_bystr('206')
                      , '312'
                      , VARIADIC ARRAY[
                                ROW('311', 'codifier')
                              , ROW('312', 'codifier')
                              ] :: code_construction_input[]
                      )
             , add_subcodes_under_codifier(
                        make_codekeyl_bystr('207')
                      , '313'
                      , VARIADIC ARRAY[
                                ROW('313', 'codifier')
                              , ROW('314', 'codifier')
                              ] :: code_construction_input[]
                      )
             , add_subcodes_under_codifier(
                        make_codekeyl_bystr('208')
                      , '315'
                      , VARIADIC ARRAY[
                                ROW('315', 'codifier')
                              , ROW('316', 'codifier')
                              ] :: code_construction_input[]
                      )
             , add_subcodes_under_codifier(
                        make_codekeyl_bystr('209')
                      , '306'
                      , VARIADIC ARRAY[
                                ROW('306', 'codifier')
                              ] :: code_construction_input[]
                      )
        INTO out_r; RAISE NOTICE 'Output(create_test_set): %', out_r;

        SELECT new_code( ROW('306', 'plain code') :: code_construction_input
                       , make_codekeyl_null()
                       , FALSE
                       )
             , new_code( ROW('404', 'plain code') :: code_construction_input
                       , make_codekeyl_bystr('306')
                       , FALSE
                       )
        INTO out_r; RAISE NOTICE 'Output(create_test_set): %', out_r;

        SELECT bind_code_to_codifier(
                        make_acodekeyl_bystr1('304')
                      , make_codekeyl_bystr('202')
                      , FALSE
                      )
             , bind_code_to_codifier(
                        make_acodekeyl_bystr1('305')
                      , make_codekeyl_bystr('202')
                      , FALSE
                      )
        INTO out_r; RAISE NOTICE 'Output(create_test_set): %', out_r;

        SELECT new_code(ROW('401', 'codifier') :: code_construction_input
                      , make_codekeyl_bystr('301')
                      , FALSE
                      )
             , new_codifier_w_subcodes(
                        make_codekeyl_bystr('307')
                      , ROW('402', 'codifier') :: code_construction_input
                      , '501'
                      , VARIADIC ARRAY[
                                ROW('501', 'plain code')
                              ] :: code_construction_input[]
                      )
             , new_codifier_w_subcodes(
                        make_codekeyl_bystr('311')
                      , ROW('403', 'codifier') :: code_construction_input
                      , '502'
                      , VARIADIC ARRAY[
                                ROW('502', 'plain code')
                              , ROW('503', 'plain code')
                              ] :: code_construction_input[]
                      )
        INTO out_r; RAISE NOTICE 'Output(create_test_set): %', out_r;

        SELECT make_codifier_from_plaincode(TRUE, TRUE, make_codekeyl_bystr('999'), 'codifier')
        INTO out_r; RAISE NOTICE 'Output(create_test_set): %', out_r;

        SELECT bind_code_to_codifier(
                        make_acodekeyl_bystr2('301', '401')
                      , make_codekeyl_bystr('309')
                      , FALSE
                      )
             , bind_code_to_codifier(
                        make_acodekeyl_bystr1('205')
                      , make_codekeyl_bystr('999')
                      , FALSE
                      )
             , bind_code_to_codifier(
                        make_acodekeyl_bystr2('403', '503')
                      , make_codekeyl_bystr('999')
                      , FALSE
                      )
             , bind_code_to_codifier(
                        make_acodekeyl_bystr2('208', '316')
                      , make_codekeyl_bystr('999')
                      , FALSE
                      )
        INTO out_r; RAISE NOTICE 'Output(create_test_set): %', out_r;

        --------

        SELECT add_code_lng_names(
                        TRUE
                      , make_acodekeyl_bystr1('101')
                      , VARIADIC ARRAY[
                                mk_name_construction_input(make_codekeyl_bystr('eng'), 'code 101', make_codekeyl_null(), 'Description od code 101.')
                              , mk_name_construction_input(make_codekeyl_bystr('rus'), 'код 101' , make_codekeyl_null(), 'Описание кода 101.')
                              ]
                      )
             , add_code_lng_names(
                        TRUE
                      , make_acodekeyl_bystr1('test codifier')
                      , VARIADIC ARRAY[
                                mk_name_construction_input(make_codekeyl_bystr('eng'), 'test codifier (eng)', make_codekeyl_null(), 'Description od code "test code".')
                              , mk_name_construction_input(make_codekeyl_bystr('rus'), 'тестовый кодификатор' , make_codekeyl_null(), 'Описание тестового кодификатора.')
                              ]
                      )
             , add_code_lng_names(
                        TRUE
                      , make_acodekeyl_bystr1('306')
                      , VARIADIC ARRAY[
                                mk_name_construction_input(make_codekeyl_bystr('rus'), 'код 306' , make_codekeyl_null(), 'Описание кодификатора 306.')
                              ]
                      )
             , add_code_lng_names(
                        TRUE
                      , make_acodekeyl_bystr2('203', '306')
                      , VARIADIC ARRAY[
                                mk_name_construction_input(make_codekeyl_bystr('rus'), 'код 306' , make_codekeyl_null(), 'Описание кода 306.')
                              ]
                      )
        INTO out_r; RAISE NOTICE 'Output(create_test_set): %', out_r;

        SELECT bind_code_to_codifier(
                        make_acodekeyl_bystr1('101')
                      , make_codekeyl_bystr('402')
                      , FALSE
                      )
             , bind_code_to_codifier(
                        make_acodekeyl_bystr1('201')
                      , make_codekeyl_bystr('401')
                      , FALSE
                      )
        INTO out_r; RAISE NOTICE 'Output(create_test_set): %', out_r;

        RETURN NULL;
END;
$$;
GRANT EXECUTE ON FUNCTION create_test_set() TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION remove_test_set() TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;

\set ECHO queries
\c <<$db_name$>> user_db<<$db_name$>>_app<<$app_name$>>_data_admin

\set ECHO queries
SELECT set_config('client_min_messages', 'NOTICE', FALSE);

SELECT create_test_set();

SELECT * FROM codes;
SELECT * FROM codes_tree;
SELECT '"' || name || '"', code_id, lng_of_name FROM codes_names;

\echo >>>>Testing "optimize_acodekeyl" function
\echo >>All must return TRUE
\echo >>File: docs/models/Optimizer.TestSet.ver.odg

SELECT optimized_codekey_isit(make_codekey(NULL :: integer, 'a'));
SELECT optimized_codekey_isit(make_codekey(1, 'a'));
SELECT optimized_acodekey_isit(make_acodekey(make_codekey(NULL :: integer, 'a'), make_codekey(NULL :: integer, 'a')), 1);
SELECT optimized_acodekey_isit(make_acodekey(make_codekey(NULL :: integer, 'a'), make_codekey(1, 'a')),1);
SELECT optimized_acodekey_isit(make_acodekey(make_codekey(1, 'a'), make_codekey(NULL :: integer, 'a')),1);
SELECT optimized_codekeyl_isit(make_codekeyl(make_codekey(NULL :: integer, 'a'), make_codekey(NULL :: integer, 'a')),1);
SELECT optimized_codekeyl_isit(make_codekeyl(make_codekey(NULL :: integer, 'a'), make_codekey(1, 'a')),1);
SELECT optimized_codekeyl_isit(make_codekeyl(make_codekey(1, 'a'), make_codekey(NULL :: integer, 'a')),1);
SELECT optimized_acodekey_isit(make_acodekey(make_codekey(NULL :: integer, 'a'), make_codekey(NULL :: integer, 'a')), 2);
SELECT optimized_acodekey_isit(make_acodekey(make_codekey(NULL :: integer, 'a'), make_codekey(1, 'a')),2);
SELECT optimized_acodekey_isit(make_acodekey(make_codekey(1, 'a'), make_codekey(NULL :: integer, 'a')),2);
SELECT optimized_codekeyl_isit(make_codekeyl(make_codekey(NULL :: integer, 'a'), make_codekey(NULL :: integer, 'a')),2);
SELECT optimized_codekeyl_isit(make_codekeyl(make_codekey(NULL :: integer, 'a'), make_codekey(1, 'a')),2);
SELECT optimized_codekeyl_isit(make_codekeyl(make_codekey(1, 'a'), make_codekey(NULL :: integer, 'a')),2);
SELECT optimized_acodekey_isit(make_acodekey(make_codekey(NULL :: integer, 'a'), make_codekey(NULL :: integer, 'a')), 3);
SELECT optimized_acodekey_isit(make_acodekey(make_codekey(NULL :: integer, 'a'), make_codekey(1, 'a')),3);
SELECT optimized_acodekey_isit(make_acodekey(make_codekey(1, 'a'), make_codekey(NULL :: integer, 'a')),3);
SELECT optimized_codekeyl_isit(make_codekeyl(make_codekey(NULL :: integer, 'a'), make_codekey(NULL :: integer, 'a')),5);
SELECT optimized_codekeyl_isit(make_codekeyl(make_codekey(NULL :: integer, 'a'), make_codekey(1, 'a')),5);
SELECT optimized_codekeyl_isit(make_codekeyl(make_codekey(1, 'a'), make_codekey(NULL :: integer, 'a')),5);

SELECT optimized_acodekeyl_isit(make_acodekeyl(make_codekey(NULL :: integer, 'a'), make_codekey(NULL :: integer, 'a'),make_codekey(NULL :: integer, 'a')),1);
SELECT optimized_acodekeyl_isit(make_acodekeyl(make_codekey(NULL :: integer, 'a'), make_codekey(NULL :: integer, 'a'),make_codekey(NULL :: integer, 'a')),2);
SELECT optimized_acodekeyl_isit(make_acodekeyl(make_codekey(NULL :: integer, 'a'), make_codekey(NULL :: integer, 'a'),make_codekey(NULL :: integer, 'a')),4);

SELECT 'c_id (-l,-cf): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_byid(110)), 0) AS x) AS s;
SELECT 'c_id (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_byid(110)), 0) AS x) AS s;
SELECT 'c_id (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_byid(110)), 0) AS x) AS s;
SELECT 'c_id (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_byid(110)), 0) AS x) AS s;
SELECT 'c_id (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_byid(110)), 0) AS x) AS s;
SELECT 'c_id (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 0) AS x) AS s;
SELECT 'c_id (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_byid(110)), 0) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_byid(110)), 0) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 0) AS x) AS s;
SELECT 'c_nm (-l,-cf): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_bystr('101')), 0) AS x) AS s;
SELECT 'c_nm (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_bystr('101')), 0) AS x) AS s;
SELECT 'c_nm (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_bystr('101')), 0) AS x) AS s;
SELECT 'c_nm (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_bystr('код 101')), 0) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_bystr('код 101')), 0) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 0) AS x) AS s;
SELECT 'c_nm (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_bystr('код 101')), 0) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_bystr('код 101')), 0) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 0) AS x) AS s;
SELECT 'cf_id (-l): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_null()), 0) AS x) AS s;
SELECT 'cf_id (+l_id): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_null()), 0) AS x) AS s;
SELECT 'cf_id (+l_nm): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_null()), 0) AS x) AS s;
SELECT 'cf_nm (-l): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_null()), 0) AS x) AS s;
SELECT 'cf_nm (+l_id): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 0) AS x) AS s;
SELECT 'cf_nm (+l_nm): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 0) AS x) AS s;
SELECT 'c_id (-l,-cf): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_byid(110)), 1) AS x) AS s;
SELECT 'c_id (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_byid(110)), 1) AS x) AS s;
SELECT 'c_id (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_byid(110)), 1) AS x) AS s;
SELECT 'c_id (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_byid(110)), 1) AS x) AS s;
SELECT 'c_id (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_byid(110)), 1) AS x) AS s;
SELECT 'c_id (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 1) AS x) AS s;
SELECT 'c_id (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_byid(110)), 1) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_byid(110)), 1) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 1) AS x) AS s;
SELECT 'c_nm (-l,-cf): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_bystr('101')), 1) AS x) AS s;
SELECT 'c_nm (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_bystr('101')), 1) AS x) AS s;
SELECT 'c_nm (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_bystr('101')), 1) AS x) AS s;
SELECT 'c_nm (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_bystr('код 101')), 1) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_bystr('код 101')), 1) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 1) AS x) AS s;
SELECT 'c_nm (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_bystr('код 101')), 1) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_bystr('код 101')), 1) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 1) AS x) AS s;
SELECT 'cf_id (-l): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_null()), 1) AS x) AS s;
SELECT 'cf_id (+l_id): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_null()), 1) AS x) AS s;
SELECT 'cf_id (+l_nm): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_null()), 1) AS x) AS s;
SELECT 'cf_nm (-l): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_null()), 1) AS x) AS s;
SELECT 'cf_nm (+l_id): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 1) AS x) AS s;
SELECT 'cf_nm (+l_nm): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 1) AS x) AS s;
SELECT 'c_id (-l,-cf): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_byid(110)), 2) AS x) AS s;
SELECT 'c_id (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_byid(110)), 2) AS x) AS s;
SELECT 'c_id (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_byid(110)), 2) AS x) AS s;
SELECT 'c_id (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_byid(110)), 2) AS x) AS s;
SELECT 'c_id (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_byid(110)), 2) AS x) AS s;
SELECT 'c_id (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 2) AS x) AS s;
SELECT 'c_id (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_byid(110)), 2) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_byid(110)), 2) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 2) AS x) AS s;
SELECT 'c_nm (-l,-cf): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_bystr('101')), 2) AS x) AS s;
SELECT 'c_nm (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_bystr('101')), 2) AS x) AS s;
SELECT 'c_nm (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_bystr('101')), 2) AS x) AS s;
SELECT 'c_nm (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_bystr('код 101')), 2) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_bystr('код 101')), 2) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 2) AS x) AS s;
SELECT 'c_nm (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_bystr('код 101')), 2) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_bystr('код 101')), 2) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 2) AS x) AS s;
SELECT 'cf_id (-l): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_null()), 2) AS x) AS s;
SELECT 'cf_id (+l_id): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_null()), 2) AS x) AS s;
SELECT 'cf_id (+l_nm): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_null()), 2) AS x) AS s;
SELECT 'cf_nm (-l): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_null()), 2) AS x) AS s;
SELECT 'cf_nm (+l_id): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 2) AS x) AS s;
SELECT 'cf_nm (+l_nm): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 2) AS x) AS s;
SELECT 'c_id (-l,-cf): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_byid(110)), 3) AS x) AS s;
SELECT 'c_id (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_byid(110)), 3) AS x) AS s;
SELECT 'c_id (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_byid(110)), 3) AS x) AS s;
SELECT 'c_id (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_byid(110)), 3) AS x) AS s;
SELECT 'c_id (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_byid(110)), 3) AS x) AS s;
SELECT 'c_id (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 3) AS x) AS s;
SELECT 'c_id (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_byid(110)), 3) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_byid(110)), 3) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 3) AS x) AS s;
SELECT 'c_nm (-l,-cf): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_bystr('101')), 3) AS x) AS s;
SELECT 'c_nm (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_bystr('101')), 3) AS x) AS s;
SELECT 'c_nm (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_bystr('101')), 3) AS x) AS s;
SELECT 'c_nm (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_bystr('код 101')), 3) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_bystr('код 101')), 3) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 3) AS x) AS s;
SELECT 'c_nm (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_bystr('код 101')), 3) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_bystr('код 101')), 3) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 3) AS x) AS s;
SELECT 'cf_id (-l): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_null()), 3) AS x) AS s;
SELECT 'cf_id (+l_id): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_null()), 3) AS x) AS s;
SELECT 'cf_id (+l_nm): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_null()), 3) AS x) AS s;
SELECT 'cf_nm (-l): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_null()), 3) AS x) AS s;
SELECT 'cf_nm (+l_id): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 3) AS x) AS s;
SELECT 'cf_nm (+l_nm): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 3) AS x) AS s;
SELECT 'c_id (-l,-cf): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_byid(110)), 4) AS x) AS s;
SELECT 'c_id (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_byid(110)), 4) AS x) AS s;
SELECT 'c_id (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_byid(110)), 4) AS x) AS s;
SELECT 'c_id (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_byid(110)), 4) AS x) AS s;
SELECT 'c_id (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_byid(110)), 4) AS x) AS s;
SELECT 'c_id (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 4) AS x) AS s;
SELECT 'c_id (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_byid(110)), 4) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_byid(110)), 4) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 4) AS x) AS s;
SELECT 'c_nm (-l,-cf): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_bystr('101')), 4) AS x) AS s;
SELECT 'c_nm (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_bystr('101')), 4) AS x) AS s;
SELECT 'c_nm (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_bystr('101')), 4) AS x) AS s;
SELECT 'c_nm (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_bystr('код 101')), 4) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_bystr('код 101')), 4) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 4) AS x) AS s;
SELECT 'c_nm (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_bystr('код 101')), 4) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_bystr('код 101')), 4) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 4) AS x) AS s;
SELECT 'cf_id (-l): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_null()), 4) AS x) AS s;
SELECT 'cf_id (+l_id): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_null()), 4) AS x) AS s;
SELECT 'cf_id (+l_nm): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_null()), 4) AS x) AS s;
SELECT 'cf_nm (-l): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_null()), 4) AS x) AS s;
SELECT 'cf_nm (+l_id): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 4) AS x) AS s;
SELECT 'cf_nm (+l_nm): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 4) AS x) AS s;
SELECT 'c_id (-l,-cf): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_byid(110)), 5) AS x) AS s;
SELECT 'c_id (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_byid(110)), 5) AS x) AS s;
SELECT 'c_id (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_byid(110)), 5) AS x) AS s;
SELECT 'c_id (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_byid(110)), 5) AS x) AS s;
SELECT 'c_id (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_byid(110)), 5) AS x) AS s;
SELECT 'c_id (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 5) AS x) AS s;
SELECT 'c_id (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_byid(110)), 5) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_byid(110)), 5) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 5) AS x) AS s;
SELECT 'c_nm (-l,-cf): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_bystr('101')), 5) AS x) AS s;
SELECT 'c_nm (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_bystr('101')), 5) AS x) AS s;
SELECT 'c_nm (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_bystr('101')), 5) AS x) AS s;
SELECT 'c_nm (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_bystr('код 101')), 5) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_bystr('код 101')), 5) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 5) AS x) AS s;
SELECT 'c_nm (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_bystr('код 101')), 5) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_bystr('код 101')), 5) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 5) AS x) AS s;
SELECT 'cf_id (-l): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_null()), 5) AS x) AS s;
SELECT 'cf_id (+l_id): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_null()), 5) AS x) AS s;
SELECT 'cf_id (+l_nm): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_null()), 5) AS x) AS s;
SELECT 'cf_nm (-l): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_null()), 5) AS x) AS s;
SELECT 'cf_nm (+l_id): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 5) AS x) AS s;
SELECT 'cf_nm (+l_nm): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 5) AS x) AS s;
SELECT 'c_id (-l,-cf): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_byid(110)), 6) AS x) AS s;
SELECT 'c_id (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_byid(110)), 6) AS x) AS s;
SELECT 'c_id (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_byid(110)), 6) AS x) AS s;
SELECT 'c_id (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_byid(110)), 6) AS x) AS s;
SELECT 'c_id (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_byid(110)), 6) AS x) AS s;
SELECT 'c_id (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 6) AS x) AS s;
SELECT 'c_id (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_byid(110)), 6) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_byid(110)), 6) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 6) AS x) AS s;
SELECT 'c_nm (-l,-cf): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_bystr('101')), 6) AS x) AS s;
SELECT 'c_nm (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_bystr('101')), 6) AS x) AS s;
SELECT 'c_nm (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_bystr('101')), 6) AS x) AS s;
SELECT 'c_nm (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_bystr('код 101')), 6) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_bystr('код 101')), 6) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 6) AS x) AS s;
SELECT 'c_nm (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_bystr('код 101')), 6) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_bystr('код 101')), 6) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 6) AS x) AS s;
SELECT 'cf_id (-l): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_null()), 6) AS x) AS s;
SELECT 'cf_id (+l_id): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_null()), 6) AS x) AS s;
SELECT 'cf_id (+l_nm): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_null()), 6) AS x) AS s;
SELECT 'cf_nm (-l): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_null()), 6) AS x) AS s;
SELECT 'cf_nm (+l_id): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 6) AS x) AS s;
SELECT 'cf_nm (+l_nm): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 6) AS x) AS s;
SELECT 'c_id (-l,-cf): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_byid(110)), 7) AS x) AS s;
SELECT 'c_id (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_byid(110)), 7) AS x) AS s;
SELECT 'c_id (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_byid(110)), 7) AS x) AS s;
SELECT 'c_id (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_byid(110)), 7) AS x) AS s;
SELECT 'c_id (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_byid(110)), 7) AS x) AS s;
SELECT 'c_id (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 7) AS x) AS s;
SELECT 'c_id (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_byid(110)), 7) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_byid(110)), 7) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 7) AS x) AS s;
SELECT 'c_nm (-l,-cf): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_bystr('101')), 7) AS x) AS s;
SELECT 'c_nm (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_bystr('101')), 7) AS x) AS s;
SELECT 'c_nm (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_bystr('101')), 7) AS x) AS s;
SELECT 'c_nm (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_bystr('код 101')), 7) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_bystr('код 101')), 7) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 7) AS x) AS s;
SELECT 'c_nm (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_bystr('код 101')), 7) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_bystr('код 101')), 7) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 7) AS x) AS s;
SELECT 'cf_id (-l): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_null()), 7) AS x) AS s;
SELECT 'cf_id (+l_id): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_null()), 7) AS x) AS s;
SELECT 'cf_id (+l_nm): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_null()), 7) AS x) AS s;
SELECT 'cf_nm (-l): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_null()), 7) AS x) AS s;
SELECT 'cf_nm (+l_id): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 7) AS x) AS s;
SELECT 'cf_nm (+l_nm): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 7) AS x) AS s;

\echo NOTICE ---------------------------- if exists: ON

SELECT 'c_id (-l,-cf): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_byid(110)), 0) AS x) AS s;
SELECT 'c_id (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_byid(110)), 0) AS x) AS s;
SELECT 'c_id (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_byid(110)), 0) AS x) AS s;
SELECT 'c_id (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_byid(110)), 0) AS x) AS s;
SELECT 'c_id (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_byid(110)), 0) AS x) AS s;
SELECT 'c_id (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 0) AS x) AS s;
SELECT 'c_id (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_byid(110)), 0) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_byid(110)), 0) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 0) AS x) AS s;
SELECT 'c_nm (-l,-cf): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_bystr('101')), 0) AS x) AS s;
SELECT 'c_nm (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_bystr('101')), 0) AS x) AS s;
SELECT 'c_nm (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_bystr('101')), 0) AS x) AS s;
SELECT 'c_nm (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_bystr('код 101')), 0) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_bystr('код 101')), 0) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 0) AS x) AS s;
SELECT 'c_nm (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_bystr('код 101')), 0) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_bystr('код 101')), 0) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 0) AS x) AS s;
SELECT 'cf_id (-l): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_null()), 0) AS x) AS s;
SELECT 'cf_id (+l_id): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_null()), 0) AS x) AS s;
SELECT 'cf_id (+l_nm): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_null()), 0) AS x) AS s;
SELECT 'cf_nm (-l): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_null()), 0) AS x) AS s;
SELECT 'cf_nm (+l_id): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 0) AS x) AS s;
SELECT 'cf_nm (+l_nm): ', optimized_acodekeyl_isit(s.x, 0), TRUE AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 0) AS x) AS s;
SELECT 'c_id (-l,-cf): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_byid(110)), 1) AS x) AS s;
SELECT 'c_id (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_byid(110)), 1) AS x) AS s;
SELECT 'c_id (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_byid(110)), 1) AS x) AS s;
SELECT 'c_id (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_byid(110)), 1) AS x) AS s;
SELECT 'c_id (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_byid(110)), 1) AS x) AS s;
SELECT 'c_id (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 1) AS x) AS s;
SELECT 'c_id (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_byid(110)), 1) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_byid(110)), 1) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 1) AS x) AS s;
SELECT 'c_nm (-l,-cf): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_bystr('101')), 1) AS x) AS s;
SELECT 'c_nm (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_bystr('101')), 1) AS x) AS s;
SELECT 'c_nm (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_bystr('101')), 1) AS x) AS s;
SELECT 'c_nm (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_bystr('код 101')), 1) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_bystr('код 101')), 1) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 1) AS x) AS s;
SELECT 'c_nm (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_bystr('код 101')), 1) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_bystr('код 101')), 1) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 1) AS x) AS s;
SELECT 'cf_id (-l): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_null()), 1) AS x) AS s;
SELECT 'cf_id (+l_id): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_null()), 1) AS x) AS s;
SELECT 'cf_id (+l_nm): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_null()), 1) AS x) AS s;
SELECT 'cf_nm (-l): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_null()), 1) AS x) AS s;
SELECT 'cf_nm (+l_id): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 1) AS x) AS s;
SELECT 'cf_nm (+l_nm): ', optimized_acodekeyl_isit(s.x, 1), TRUE AND (((s.x).code_key).code_id = 110) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 1) AS x) AS s;
SELECT 'c_id (-l,-cf): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_byid(110)), 2) AS x) AS s;
SELECT 'c_id (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_byid(110)), 2) AS x) AS s;
SELECT 'c_id (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_byid(110)), 2) AS x) AS s;
SELECT 'c_id (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_byid(110)), 2) AS x) AS s;
SELECT 'c_id (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_byid(110)), 2) AS x) AS s;
SELECT 'c_id (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 2) AS x) AS s;
SELECT 'c_id (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_byid(110)), 2) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_byid(110)), 2) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 2) AS x) AS s;
SELECT 'c_nm (-l,-cf): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_bystr('101')), 2) AS x) AS s;
SELECT 'c_nm (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_bystr('101')), 2) AS x) AS s;
SELECT 'c_nm (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_bystr('101')), 2) AS x) AS s;
SELECT 'c_nm (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_bystr('код 101')), 2) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_bystr('код 101')), 2) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 2) AS x) AS s;
SELECT 'c_nm (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_bystr('код 101')), 2) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_bystr('код 101')), 2) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 2) AS x) AS s;
SELECT 'cf_id (-l): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_null()), 2) AS x) AS s;
SELECT 'cf_id (+l_id): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_null()), 2) AS x) AS s;
SELECT 'cf_id (+l_nm): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_null()), 2) AS x) AS s;
SELECT 'cf_nm (-l): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_null()), 2) AS x) AS s;
SELECT 'cf_nm (+l_id): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 2) AS x) AS s;
SELECT 'cf_nm (+l_nm): ', optimized_acodekeyl_isit(s.x, 2), TRUE AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 2) AS x) AS s;
SELECT 'c_id (-l,-cf): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_byid(110)), 3) AS x) AS s;
SELECT 'c_id (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_byid(110)), 3) AS x) AS s;
SELECT 'c_id (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_byid(110)), 3) AS x) AS s;
SELECT 'c_id (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_byid(110)), 3) AS x) AS s;
SELECT 'c_id (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_byid(110)), 3) AS x) AS s;
SELECT 'c_id (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 3) AS x) AS s;
SELECT 'c_id (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_byid(110)), 3) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_byid(110)), 3) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 3) AS x) AS s;
SELECT 'c_nm (-l,-cf): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_bystr('101')), 3) AS x) AS s;
SELECT 'c_nm (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_bystr('101')), 3) AS x) AS s;
SELECT 'c_nm (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_bystr('101')), 3) AS x) AS s;
SELECT 'c_nm (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_bystr('код 101')), 3) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_bystr('код 101')), 3) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 3) AS x) AS s;
SELECT 'c_nm (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_bystr('код 101')), 3) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_bystr('код 101')), 3) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 3) AS x) AS s;
SELECT 'cf_id (-l): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_null()), 3) AS x) AS s;
SELECT 'cf_id (+l_id): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_null()), 3) AS x) AS s;
SELECT 'cf_id (+l_nm): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_null()), 3) AS x) AS s;
SELECT 'cf_nm (-l): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_null()), 3) AS x) AS s;
SELECT 'cf_nm (+l_id): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 3) AS x) AS s;
SELECT 'cf_nm (+l_nm): ', optimized_acodekeyl_isit(s.x, 3), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 3) AS x) AS s;
SELECT 'c_id (-l,-cf): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_byid(110)), 4) AS x) AS s;
SELECT 'c_id (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_byid(110)), 4) AS x) AS s;
SELECT 'c_id (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_byid(110)), 4) AS x) AS s;
SELECT 'c_id (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_byid(110)), 4) AS x) AS s;
SELECT 'c_id (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_byid(110)), 4) AS x) AS s;
SELECT 'c_id (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 4) AS x) AS s;
SELECT 'c_id (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_byid(110)), 4) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_byid(110)), 4) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 4) AS x) AS s;
SELECT 'c_nm (-l,-cf): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_bystr('101')), 4) AS x) AS s;
SELECT 'c_nm (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_bystr('101')), 4) AS x) AS s;
SELECT 'c_nm (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_bystr('101')), 4) AS x) AS s;
SELECT 'c_nm (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_bystr('код 101')), 4) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_bystr('код 101')), 4) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 4) AS x) AS s;
SELECT 'c_nm (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_bystr('код 101')), 4) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_bystr('код 101')), 4) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 4) AS x) AS s;
SELECT 'cf_id (-l): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_null()), 4) AS x) AS s;
SELECT 'cf_id (+l_id): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_null()), 4) AS x) AS s;
SELECT 'cf_id (+l_nm): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_null()), 4) AS x) AS s;
SELECT 'cf_nm (-l): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_null()), 4) AS x) AS s;
SELECT 'cf_nm (+l_id): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 4) AS x) AS s;
SELECT 'cf_nm (+l_nm): ', optimized_acodekeyl_isit(s.x, 4), TRUE AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 4) AS x) AS s;
SELECT 'c_id (-l,-cf): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_byid(110)), 5) AS x) AS s;
SELECT 'c_id (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_byid(110)), 5) AS x) AS s;
SELECT 'c_id (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_byid(110)), 5) AS x) AS s;
SELECT 'c_id (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_byid(110)), 5) AS x) AS s;
SELECT 'c_id (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_byid(110)), 5) AS x) AS s;
SELECT 'c_id (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 5) AS x) AS s;
SELECT 'c_id (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_byid(110)), 5) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_byid(110)), 5) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 5) AS x) AS s;
SELECT 'c_nm (-l,-cf): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_bystr('101')), 5) AS x) AS s;
SELECT 'c_nm (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_bystr('101')), 5) AS x) AS s;
SELECT 'c_nm (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_bystr('101')), 5) AS x) AS s;
SELECT 'c_nm (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_bystr('код 101')), 5) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_bystr('код 101')), 5) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 5) AS x) AS s;
SELECT 'c_nm (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_bystr('код 101')), 5) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_bystr('код 101')), 5) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 5) AS x) AS s;
SELECT 'cf_id (-l): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_null()), 5) AS x) AS s;
SELECT 'cf_id (+l_id): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_null()), 5) AS x) AS s;
SELECT 'cf_id (+l_nm): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_null()), 5) AS x) AS s;
SELECT 'cf_nm (-l): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_null()), 5) AS x) AS s;
SELECT 'cf_nm (+l_id): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 5) AS x) AS s;
SELECT 'cf_nm (+l_nm): ', optimized_acodekeyl_isit(s.x, 5), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 5) AS x) AS s;
SELECT 'c_id (-l,-cf): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_byid(110)), 6) AS x) AS s;
SELECT 'c_id (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_byid(110)), 6) AS x) AS s;
SELECT 'c_id (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_byid(110)), 6) AS x) AS s;
SELECT 'c_id (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_byid(110)), 6) AS x) AS s;
SELECT 'c_id (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_byid(110)), 6) AS x) AS s;
SELECT 'c_id (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 6) AS x) AS s;
SELECT 'c_id (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_byid(110)), 6) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_byid(110)), 6) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 6) AS x) AS s;
SELECT 'c_nm (-l,-cf): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_bystr('101')), 6) AS x) AS s;
SELECT 'c_nm (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_bystr('101')), 6) AS x) AS s;
SELECT 'c_nm (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_bystr('101')), 6) AS x) AS s;
SELECT 'c_nm (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_bystr('код 101')), 6) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_bystr('код 101')), 6) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 6) AS x) AS s;
SELECT 'c_nm (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_bystr('код 101')), 6) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_bystr('код 101')), 6) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 6) AS x) AS s;
SELECT 'cf_id (-l): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_null()), 6) AS x) AS s;
SELECT 'cf_id (+l_id): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_null()), 6) AS x) AS s;
SELECT 'cf_id (+l_nm): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_null()), 6) AS x) AS s;
SELECT 'cf_nm (-l): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_null()), 6) AS x) AS s;
SELECT 'cf_nm (+l_id): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 6) AS x) AS s;
SELECT 'cf_nm (+l_nm): ', optimized_acodekeyl_isit(s.x, 6), TRUE AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 6) AS x) AS s;
SELECT 'c_id (-l,-cf): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_byid(110)), 7) AS x) AS s;
SELECT 'c_id (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_byid(110)), 7) AS x) AS s;
SELECT 'c_id (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_byid(110)), 7) AS x) AS s;
SELECT 'c_id (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_byid(110)), 7) AS x) AS s;
SELECT 'c_id (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_byid(110)), 7) AS x) AS s;
SELECT 'c_id (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 7) AS x) AS s;
SELECT 'c_id (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_byid(110)), 7) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_byid(110)), 7) AS x) AS s;
SELECT 'c_id (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_byid(110)), 7) AS x) AS s;
SELECT 'c_nm (-l,-cf): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_null(), make_codekey_bystr('101')), 7) AS x) AS s;
SELECT 'c_nm (-l,+cf_id): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_bystr('101')), 7) AS x) AS s;
SELECT 'c_nm (-l,+cf_nm): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_bystr('101')), 7) AS x) AS s;
SELECT 'c_nm (+l_id,-cf): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_null(), make_codekey_bystr('код 101')), 7) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_id): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_bystr('код 101')), 7) AS x) AS s;
SELECT 'c_nm (+l_id,+cf_nm): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 7) AS x) AS s;
SELECT 'c_nm (+l_nm,-cf): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null(), make_codekey_bystr('код 101')), 7) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_id): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_bystr('код 101')), 7) AS x) AS s;
SELECT 'c_nm (+l_nm,+cf_nm): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')), 7) AS x) AS s;
SELECT 'cf_id (-l): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_byid(100), make_codekey_null()), 7) AS x) AS s;
SELECT 'cf_id (+l_id): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_byid(100), make_codekey_null()), 7) AS x) AS s;
SELECT 'cf_id (+l_nm): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100), make_codekey_null()), 7) AS x) AS s;
SELECT 'cf_nm (-l): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_null(), make_codekey_bystr('test codifier'), make_codekey_null()), 7) AS x) AS s;
SELECT 'cf_nm (+l_id): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_byid(9001), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 7) AS x) AS s;
SELECT 'cf_nm (+l_nm): ', optimized_acodekeyl_isit(s.x, 7), TRUE AND (((s.x).code_key).code_id = 110) AND (((s.x).codifier_key).code_id = 100) AND (((s.x).key_lng).code_id = 9001) AS ok_isit FROM (SELECT optimize_acodekeyl(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()), 7) AS x) AS s;


\echo >>>>Testing "code_id_of" functions

SELECT code_id_of_undefined()
     , code_id_of_unclassified()
     , code_id_of_error()
     , code_id_of_ambiguous();

SELECT 'undef              : ', code_id_of(TRUE , make_acodekeyl_null());
SELECT 'c_id               : ', code_id_of(TRUE , make_acodekeyl_byid(110));
SELECT 'c_nm (-l,-cf)      : ', code_id_of(TRUE , make_acodekeyl_bystr1('101'));
SELECT 'c_nm (-l,+cf_id)   : ', code_id_of(TRUE , make_acodekeyl(make_codekey_null()                , make_codekey_byid(100)                    , make_codekey_bystr('101')));
SELECT 'c_nm (-l,+cf_nm)   : ', code_id_of(TRUE , make_acodekeyl(make_codekey_null()                , make_codekey_bystr('test codifier')       , make_codekey_bystr('101')));
SELECT 'c_nm (+l_id,-cf)   : ', code_id_of(TRUE , make_acodekeyl(make_codekey_byid(9001)            , make_codekey_null()                       , make_codekey_bystr('код 101')));
SELECT 'c_nm (+l_id,+cf_id): ', code_id_of(TRUE , make_acodekeyl(make_codekey_byid(9001)            , make_codekey_byid(100)                    , make_codekey_bystr('код 101')));
SELECT 'c_nm (+l_id,+cf_nm): ', code_id_of(TRUE , make_acodekeyl(make_codekey_byid(9001)            , make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')));
SELECT 'c_nm (+l_nm,-cf)   : ', code_id_of(TRUE , make_acodekeyl(make_codekey_bystr('rus')          , make_codekey_null()                       , make_codekey_bystr('код 101')));
SELECT 'c_nm (+l_nm,+cf_id): ', code_id_of(TRUE , make_acodekeyl(make_codekey_bystr('rus')          , make_codekey_byid(100)                    , make_codekey_bystr('код 101')));
SELECT 'c_nm (+l_nm,+cf_nm): ', code_id_of(TRUE , make_acodekeyl(make_codekey_bystr('rus')          , make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')));
SELECT 'cf_id              : ', code_id_of(TRUE , make_acodekeyl(make_codekey_null()                , make_codekey_byid(100)                    , make_codekey_null()          ));
SELECT 'cf_nm (-l)         : ', code_id_of(TRUE , make_acodekeyl(make_codekey_null()                , make_codekey_bystr('test codifier')       , make_codekey_null()          ));
SELECT 'cf_nm (+l_id)      : ', code_id_of(TRUE , make_acodekeyl(make_codekey_byid(9001)            , make_codekey_bystr('тестовый кодификатор'), make_codekey_null()          ));
SELECT 'cf_nm (+l_nm)      : ', code_id_of(TRUE , make_acodekeyl(make_codekey_bystr('rus')          , make_codekey_bystr('тестовый кодификатор'), make_codekey_null()          ));

SELECT 'undef              : ', code_id_of(FALSE, make_acodekeyl_null());
SELECT 'c_id               : ', code_id_of(FALSE, make_acodekeyl_byid(110));
SELECT 'c_nm (-l,-cf)      : ', code_id_of(FALSE, make_acodekeyl_bystr1('101'));
SELECT 'c_nm (-l,+cf_id)   : ', code_id_of(FALSE, make_acodekeyl(make_codekey_null()                , make_codekey_byid(100)                    , make_codekey_bystr('101')));
SELECT 'c_nm (-l,+cf_nm)   : ', code_id_of(FALSE, make_acodekeyl(make_codekey_null()                , make_codekey_bystr('test codifier')       , make_codekey_bystr('101')));
SELECT 'c_nm (+l_id,-cf)   : ', code_id_of(FALSE, make_acodekeyl(make_codekey_byid(9001)            , make_codekey_null()                       , make_codekey_bystr('код 101')));
SELECT 'c_nm (+l_id,+cf_id): ', code_id_of(FALSE, make_acodekeyl(make_codekey_byid(9001)            , make_codekey_byid(100)                    , make_codekey_bystr('код 101')));
SELECT 'c_nm (+l_id,+cf_nm): ', code_id_of(FALSE, make_acodekeyl(make_codekey_byid(9001)            , make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')));
SELECT 'c_nm (+l_nm,-cf)   : ', code_id_of(FALSE, make_acodekeyl(make_codekey_bystr('rus')          , make_codekey_null()                       , make_codekey_bystr('код 101')));
SELECT 'c_nm (+l_nm,+cf_id): ', code_id_of(FALSE, make_acodekeyl(make_codekey_bystr('rus')          , make_codekey_byid(100)                    , make_codekey_bystr('код 101')));
SELECT 'c_nm (+l_nm,+cf_nm): ', code_id_of(FALSE, make_acodekeyl(make_codekey_bystr('rus')          , make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')));
SELECT 'cf_id              : ', code_id_of(FALSE, make_acodekeyl(make_codekey_null()                , make_codekey_byid(100)                    , make_codekey_null()          ));
SELECT 'cf_nm (-l)         : ', code_id_of(FALSE, make_acodekeyl(make_codekey_null()                , make_codekey_bystr('test codifier')       , make_codekey_null()          ));
SELECT 'cf_nm (+l_id)      : ', code_id_of(FALSE, make_acodekeyl(make_codekey_byid(9001)            , make_codekey_bystr('тестовый кодификатор'), make_codekey_null()          ));
SELECT 'cf_nm (+l_nm)      : ', code_id_of(FALSE, make_acodekeyl(make_codekey_bystr('rus')          , make_codekey_bystr('тестовый кодификатор'), make_codekey_null()          ));

SELECT 'c_id               : ', code_id_of(TRUE , make_acodekeyl_byid(-1));
SELECT 'c_nm (-l,-cf)      : ', code_id_of(TRUE , make_acodekeyl_bystr1('-1'));
SELECT 'c_nm (-l,+cf_id)   : ', code_id_of(TRUE , make_acodekeyl(make_codekey_null()      , make_codekey_byid(-1)   , make_codekey_bystr('-1')));
SELECT 'c_nm (-l,+cf_nm)   : ', code_id_of(TRUE , make_acodekeyl(make_codekey_null()      , make_codekey_bystr('-1'), make_codekey_bystr('-1')));
SELECT 'c_nm (+l_id,-cf)   : ', code_id_of(TRUE , make_acodekeyl(make_codekey_byid(9001)  , make_codekey_null()     , make_codekey_bystr('-1')));
SELECT 'c_nm (+l_id,+cf_id): ', code_id_of(TRUE , make_acodekeyl(make_codekey_byid(9001)  , make_codekey_byid(-1)   , make_codekey_bystr('-1')));
SELECT 'c_nm (+l_id,+cf_nm): ', code_id_of(TRUE , make_acodekeyl(make_codekey_byid(9001)  , make_codekey_bystr('-1'), make_codekey_bystr('-1')));
SELECT 'c_nm (+l_nm,-cf)   : ', code_id_of(TRUE , make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null()     , make_codekey_bystr('-1')));
SELECT 'c_nm (+l_nm,+cf_id): ', code_id_of(TRUE , make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(-1)   , make_codekey_bystr('-1')));
SELECT 'c_nm (+l_nm,+cf_nm): ', code_id_of(TRUE , make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('-1'), make_codekey_bystr('-1')));
SELECT 'cf_id              : ', code_id_of(TRUE , make_acodekeyl(make_codekey_null()      , make_codekey_byid(-1)   , make_codekey_null()     ));
SELECT 'cf_nm (-l)         : ', code_id_of(TRUE , make_acodekeyl(make_codekey_null()      , make_codekey_bystr('-1'), make_codekey_null()     ));
SELECT 'cf_nm (+l_id)      : ', code_id_of(TRUE , make_acodekeyl(make_codekey_byid(9001)  , make_codekey_bystr('-1'), make_codekey_null()     ));
SELECT 'cf_nm (+l_nm)      : ', code_id_of(TRUE , make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('-1'), make_codekey_null()     ));

\echo >>>>These shoulde raise exceptions:
SELECT 'c_id               : ', code_id_of(FALSE, make_acodekeyl_byid(-1));
SELECT 'c_nm (-l,-cf)      : ', code_id_of(FALSE, make_acodekeyl_bystr1('-1'));
SELECT 'c_nm (-l,+cf_id)   : ', code_id_of(FALSE, make_acodekeyl(make_codekey_null()      , make_codekey_byid(-1)   , make_codekey_bystr('-1')));
SELECT 'c_nm (-l,+cf_nm)   : ', code_id_of(FALSE, make_acodekeyl(make_codekey_null()      , make_codekey_bystr('-1'), make_codekey_bystr('-1')));
SELECT 'c_nm (+l_id,-cf)   : ', code_id_of(FALSE, make_acodekeyl(make_codekey_byid(9001)  , make_codekey_null()     , make_codekey_bystr('-1')));
SELECT 'c_nm (+l_id,+cf_id): ', code_id_of(FALSE, make_acodekeyl(make_codekey_byid(9001)  , make_codekey_byid(-1)   , make_codekey_bystr('-1')));
SELECT 'c_nm (+l_id,+cf_nm): ', code_id_of(FALSE, make_acodekeyl(make_codekey_byid(9001)  , make_codekey_bystr('-1'), make_codekey_bystr('-1')));
SELECT 'c_nm (+l_nm,-cf)   : ', code_id_of(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null()     , make_codekey_bystr('-1')));
SELECT 'c_nm (+l_nm,+cf_id): ', code_id_of(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(-1)   , make_codekey_bystr('-1')));
SELECT 'c_nm (+l_nm,+cf_nm): ', code_id_of(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('-1'), make_codekey_bystr('-1')));
SELECT 'cf_id              : ', code_id_of(FALSE, make_acodekeyl(make_codekey_null()      , make_codekey_byid(-1)   , make_codekey_null()     ));
SELECT 'cf_nm (-l)         : ', code_id_of(FALSE, make_acodekeyl(make_codekey_null()      , make_codekey_bystr('-1'), make_codekey_null()     ));
SELECT 'cf_nm (+l_id)      : ', code_id_of(FALSE, make_acodekeyl(make_codekey_byid(9001)  , make_codekey_bystr('-1'), make_codekey_null()     ));
SELECT 'cf_nm (+l_nm)      : ', code_id_of(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('-1'), make_codekey_null()     ));

\echo >>>>"code_id_of" functions tested

\echo >>>>Testing "code_belongs_to_codifier" function

\echo >>> trues
SELECT 'undef              : ', code_belongs_to_codifier(FALSE, make_acodekeyl_null());
SELECT 'c_id               : ', code_belongs_to_codifier(FALSE, make_acodekeyl_byid(110));
SELECT 'c_nm (-l,-cf)      : ', code_belongs_to_codifier(FALSE, make_acodekeyl_bystr1('101'));
SELECT 'c_nm (-l,+cf_id)   : ', code_belongs_to_codifier(FALSE, make_acodekeyl(make_codekey_null()                , make_codekey_byid(100)                    , make_codekey_bystr('101')));
SELECT 'c_nm (-l,+cf_nm)   : ', code_belongs_to_codifier(FALSE, make_acodekeyl(make_codekey_null()                , make_codekey_bystr('test codifier')       , make_codekey_bystr('101')));
SELECT 'c_nm (+l_id,-cf)   : ', code_belongs_to_codifier(FALSE, make_acodekeyl(make_codekey_byid(9001)            , make_codekey_null()                       , make_codekey_bystr('код 101')));
SELECT 'c_nm (+l_id,+cf_id): ', code_belongs_to_codifier(FALSE, make_acodekeyl(make_codekey_byid(9001)            , make_codekey_byid(100)                    , make_codekey_bystr('код 101')));
SELECT 'c_nm (+l_id,+cf_nm): ', code_belongs_to_codifier(FALSE, make_acodekeyl(make_codekey_byid(9001)            , make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')));
SELECT 'c_nm (+l_nm,-cf)   : ', code_belongs_to_codifier(FALSE, make_acodekeyl(make_codekey_bystr('rus')          , make_codekey_null()                       , make_codekey_bystr('код 101')));
SELECT 'c_nm (+l_nm,+cf_id): ', code_belongs_to_codifier(FALSE, make_acodekeyl(make_codekey_bystr('rus')          , make_codekey_byid(100)                    , make_codekey_bystr('код 101')));
SELECT 'c_nm (+l_nm,+cf_nm): ', code_belongs_to_codifier(FALSE, make_acodekeyl(make_codekey_bystr('rus')          , make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')));
SELECT 'cf_id              : ', code_belongs_to_codifier(FALSE, make_acodekeyl(make_codekey_null()                , make_codekey_byid(100)                    , make_codekey_null()          ));
SELECT 'cf_nm (-l)         : ', code_belongs_to_codifier(FALSE, make_acodekeyl(make_codekey_null()                , make_codekey_bystr('test codifier')       , make_codekey_null()          ));
SELECT 'cf_nm (+l_id)      : ', code_belongs_to_codifier(FALSE, make_acodekeyl(make_codekey_byid(9001)            , make_codekey_bystr('тестовый кодификатор'), make_codekey_null()          ));
SELECT 'cf_nm (+l_nm)      : ', code_belongs_to_codifier(FALSE, make_acodekeyl(make_codekey_bystr('rus')          , make_codekey_bystr('тестовый кодификатор'), make_codekey_null()          ));
SELECT bind_code_to_codifier(
                        make_acodekeyl_bystr2('Common nominal codes set', 'undefined')
                      , make_codekeyl_bystr('test codifier')
                      , FALSE
                      );
SELECT 'cf_id              : ', code_belongs_to_codifier(FALSE, make_acodekeyl(make_codekey_null()                , make_codekey_byid(100)                    , make_codekey_null()          ));
SELECT 'cf_nm (-l)         : ', code_belongs_to_codifier(FALSE, make_acodekeyl(make_codekey_null()                , make_codekey_bystr('test codifier')       , make_codekey_null()          ));
SELECT 'cf_nm (+l_id)      : ', code_belongs_to_codifier(FALSE, make_acodekeyl(make_codekey_byid(9001)            , make_codekey_bystr('тестовый кодификатор'), make_codekey_null()          ));
SELECT 'cf_nm (+l_nm)      : ', code_belongs_to_codifier(FALSE, make_acodekeyl(make_codekey_bystr('rus')          , make_codekey_bystr('тестовый кодификатор'), make_codekey_null()          ));
SELECT unbind_code_from_codifier(FALSE, make_acodekeyl_bystr2('test codifier', 'undefined'));

\echo >>> falses
SELECT 'undef              : ', code_belongs_to_codifier(TRUE, make_acodekeyl_null());
SELECT 'c_id               : ', code_belongs_to_codifier(TRUE, make_acodekeyl_byid(110));
SELECT 'c_nm (-l,-cf)      : ', code_belongs_to_codifier(TRUE, make_acodekeyl_bystr1('101'));
SELECT 'c_nm (-l,+cf_id)   : ', code_belongs_to_codifier(TRUE, make_acodekeyl(make_codekey_null()                , make_codekey_byid(100)                    , make_codekey_bystr('test codifier')));
SELECT 'c_nm (-l,+cf_nm)   : ', code_belongs_to_codifier(TRUE, make_acodekeyl(make_codekey_null()                , make_codekey_bystr('test codifier')       , make_codekey_bystr('test codifier')));
SELECT 'c_nm (+l_id,-cf)   : ', code_belongs_to_codifier(TRUE, make_acodekeyl(make_codekey_byid(9001)            , make_codekey_null()                       , make_codekey_bystr('тестовый кодификатор')));
SELECT 'c_nm (+l_id,+cf_id): ', code_belongs_to_codifier(TRUE, make_acodekeyl(make_codekey_byid(9001)            , make_codekey_byid(100)                    , make_codekey_bystr('тестовый кодификатор')));
SELECT 'c_nm (+l_id,+cf_nm): ', code_belongs_to_codifier(TRUE, make_acodekeyl(make_codekey_byid(9001)            , make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('тестовый кодификатор')));
SELECT 'c_nm (+l_nm,-cf)   : ', code_belongs_to_codifier(TRUE, make_acodekeyl(make_codekey_bystr('rus')          , make_codekey_null()                       , make_codekey_bystr('тестовый кодификатор')));
SELECT 'c_nm (+l_nm,+cf_id): ', code_belongs_to_codifier(TRUE, make_acodekeyl(make_codekey_bystr('rus')          , make_codekey_byid(100)                    , make_codekey_bystr('тестовый кодификатор')));
SELECT 'c_nm (+l_nm,+cf_nm): ', code_belongs_to_codifier(TRUE, make_acodekeyl(make_codekey_bystr('rus')          , make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('тестовый кодификатор')));
SELECT 'cf_id              : ', code_belongs_to_codifier(TRUE, make_acodekeyl(make_codekey_null()                , make_codekey_byid(100)                    , make_codekey_null()          ));
SELECT 'cf_nm (-l)         : ', code_belongs_to_codifier(TRUE, make_acodekeyl(make_codekey_null()                , make_codekey_bystr('test codifier')       , make_codekey_null()          ));
SELECT 'cf_nm (+l_id)      : ', code_belongs_to_codifier(TRUE, make_acodekeyl(make_codekey_byid(9001)            , make_codekey_bystr('тестовый кодификатор'), make_codekey_null()          ));
SELECT 'cf_nm (+l_nm)      : ', code_belongs_to_codifier(TRUE, make_acodekeyl(make_codekey_bystr('rus')          , make_codekey_bystr('тестовый кодификатор'), make_codekey_null()          ));

\echo >>>>These shoulde raise exceptions:
SELECT 'undef              : ', code_belongs_to_codifier(FALSE, make_acodekeyl_null());
SELECT 'c_id               : ', code_belongs_to_codifier(FALSE, make_acodekeyl_byid(110));
SELECT 'c_nm (-l,-cf)      : ', code_belongs_to_codifier(FALSE, make_acodekeyl_bystr1('101'));
SELECT 'c_nm (-l,+cf_id)   : ', code_belongs_to_codifier(FALSE, make_acodekeyl(make_codekey_null()                , make_codekey_byid(-1)   , make_codekey_bystr('test codifier')));
SELECT 'c_nm (-l,+cf_nm)   : ', code_belongs_to_codifier(FALSE, make_acodekeyl(make_codekey_null()                , make_codekey_bystr('-1'), make_codekey_bystr('test codifier')));
SELECT 'c_nm (+l_id,-cf)   : ', code_belongs_to_codifier(FALSE, make_acodekeyl(make_codekey_byid(9001)            , make_codekey_null()     , make_codekey_bystr('тестовый кодификатор')));
SELECT 'c_nm (+l_id,+cf_id): ', code_belongs_to_codifier(FALSE, make_acodekeyl(make_codekey_byid(9001)            , make_codekey_byid(-1)   , make_codekey_bystr('тестовый кодификатор')));
SELECT 'c_nm (+l_id,+cf_nm): ', code_belongs_to_codifier(FALSE, make_acodekeyl(make_codekey_byid(9001)            , make_codekey_bystr('-1'), make_codekey_bystr('тестовый кодификатор')));
SELECT 'c_nm (+l_nm,-cf)   : ', code_belongs_to_codifier(FALSE, make_acodekeyl(make_codekey_bystr('rus')          , make_codekey_null()     , make_codekey_bystr('тестовый кодификатор')));
SELECT 'c_nm (+l_nm,+cf_id): ', code_belongs_to_codifier(FALSE, make_acodekeyl(make_codekey_bystr('rus')          , make_codekey_byid(-1)   , make_codekey_bystr('тестовый кодификатор')));
SELECT 'c_nm (+l_nm,+cf_nm): ', code_belongs_to_codifier(FALSE, make_acodekeyl(make_codekey_bystr('rus')          , make_codekey_bystr('-1'), make_codekey_bystr('тестовый кодификатор')));
SELECT 'cf_id              : ', code_belongs_to_codifier(FALSE, make_acodekeyl(make_codekey_null()                , make_codekey_byid(-1)   , make_codekey_null()          ));
SELECT 'cf_nm (-l)         : ', code_belongs_to_codifier(FALSE, make_acodekeyl(make_codekey_null()                , make_codekey_bystr('-1'), make_codekey_null()          ));
SELECT 'cf_nm (+l_id)      : ', code_belongs_to_codifier(FALSE, make_acodekeyl(make_codekey_byid(9001)            , make_codekey_bystr('-1'), make_codekey_null()          ));
SELECT 'cf_nm (+l_nm)      : ', code_belongs_to_codifier(FALSE, make_acodekeyl(make_codekey_bystr('rus')          , make_codekey_bystr('-1'), make_codekey_null()          ));

\echo >>>>"code_belongs_to_codifier" functions tested

\echo >>>>Testing "codifier_default_code" function

\echo >>> 120
SELECT 'undef           : ', codifier_default_code(TRUE, make_codekeyl_null());
SELECT 'c_id            : ', codifier_default_code(TRUE, make_codekeyl_byid(110));
SELECT 'c_nm (-l,-cf)   : ', codifier_default_code(TRUE, make_codekeyl_bystr('101'));
SELECT 'c_nm (+l_id,-cf): ', codifier_default_code(TRUE, make_codekeyl(make_codekey_byid(9001)  , make_codekey_bystr('код 101')));
SELECT 'c_nm (+l_nm,-cf): ', codifier_default_code(TRUE, make_codekeyl(make_codekey_bystr('rus'), make_codekey_bystr('код 101')));

\echo >>> 120
SELECT 'undef           : ', codifier_default_code(FALSE, make_codekeyl_null());
SELECT 'c_id            : ', codifier_default_code(FALSE, make_codekeyl_byid(110));
SELECT 'c_nm (-l,-cf)   : ', codifier_default_code(FALSE, make_codekeyl_bystr('101'));
SELECT 'c_nm (+l_id,-cf): ', codifier_default_code(FALSE, make_codekeyl_bystrl(make_codekey_byid(9001)  , 'код 101'));
SELECT 'c_nm (+l_nm,-cf): ', codifier_default_code(FALSE, make_codekeyl_bystrl(make_codekey_bystr('rus'), 'код 101'));

\echo >>> not found
SELECT 'undef           : ', codifier_default_code(TRUE, make_codekeyl_null());
SELECT 'c_id            : ', codifier_default_code(TRUE, make_codekeyl_byid(-1));
SELECT 'c_nm (-l,-cf)   : ', codifier_default_code(TRUE, make_codekeyl_bystr('-1'));
SELECT 'c_nm (+l_id,-cf): ', codifier_default_code(TRUE, make_codekeyl_bystrl(make_codekey_byid(9001)  , '-1'));
SELECT 'c_nm (+l_nm,-cf): ', codifier_default_code(TRUE, make_codekeyl_bystrl(make_codekey_bystr('rus'), '-1'));

\echo >>> not found
\echo >>> These shoulde raise exceptions:
SELECT 'undef           : ', codifier_default_code(FALSE, make_codekeyl_null());
SELECT 'c_id            : ', codifier_default_code(FALSE, make_codekeyl_byid(-1));
SELECT 'c_nm (-l,-cf)   : ', codifier_default_code(FALSE, make_codekeyl_bystr('-1'));
SELECT 'c_nm (+l_id,-cf): ', codifier_default_code(FALSE, make_codekeyl_bystrl(make_codekey_byid(9001)  , '-1'));
SELECT 'c_nm (+l_nm,-cf): ', codifier_default_code(FALSE, make_codekeyl_bystrl(make_codekey_bystr('rus'), '-1'));

\echo >>>>"codifier_default_code" functions tested

\echo >>>>Testing "get_code" function

\echo >>> found
SELECT 'undef              : ', get_code(TRUE, make_acodekeyl_null());
SELECT 'c_id               : ', get_code(TRUE, make_acodekeyl_byid(110));
SELECT 'c_nm (-l,-cf)      : ', get_code(TRUE, make_acodekeyl_bystr1('101'));
SELECT 'c_nm (-l,+cf_id)   : ', get_code(TRUE, make_acodekeyl(make_codekey_null()      , make_codekey_byid(100)                    , make_codekey_bystr('101')));
SELECT 'c_nm (-l,+cf_nm)   : ', get_code(TRUE, make_acodekeyl(make_codekey_null()      , make_codekey_bystr('test codifier')       , make_codekey_bystr('101')));
SELECT 'c_nm (+l_id,-cf)   : ', get_code(TRUE, make_acodekeyl(make_codekey_byid(9001)  , make_codekey_null()                       , make_codekey_bystr('код 101')));
SELECT 'c_nm (+l_id,+cf_id): ', get_code(TRUE, make_acodekeyl(make_codekey_byid(9001)  , make_codekey_byid(100)                    , make_codekey_bystr('код 101')));
SELECT 'c_nm (+l_id,+cf_nm): ', get_code(TRUE, make_acodekeyl(make_codekey_byid(9001)  , make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')));
SELECT 'c_nm (+l_nm,-cf)   : ', get_code(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null()                       , make_codekey_bystr('код 101')));
SELECT 'c_nm (+l_nm,+cf_id): ', get_code(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(100)                    , make_codekey_bystr('код 101')));
SELECT 'c_nm (+l_nm,+cf_nm): ', get_code(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_bystr('код 101')));
SELECT 'cf_id              : ', get_code(TRUE, make_acodekeyl(make_codekey_null()      , make_codekey_byid(100)                    , make_codekey_null()          ));
SELECT 'cf_nm (-l)         : ', get_code(TRUE, make_acodekeyl(make_codekey_null()      , make_codekey_bystr('test codifier')       , make_codekey_null()          ));
SELECT 'cf_nm (+l_id)      : ', get_code(TRUE, make_acodekeyl(make_codekey_byid(9001)  , make_codekey_bystr('тестовый кодификатор'), make_codekey_null()          ));
SELECT 'cf_nm (+l_nm)      : ', get_code(TRUE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('тестовый кодификатор'), make_codekey_null()          ));

\echo >>> not found
SELECT 'undef              : ', get_code(FALSE, make_acodekeyl_null());
SELECT 'c_id               : ', get_code(FALSE, make_acodekeyl_byid(-1));
SELECT 'c_nm (-l,-cf)      : ', get_code(FALSE, make_acodekeyl_bystr1('502'));
SELECT 'c_nm (-l,+cf_id)   : ', get_code(FALSE, make_acodekeyl(make_codekey_null()      , make_codekey_byid(-1)   , make_codekey_bystr('101')    ));
SELECT 'c_nm (-l,+cf_nm)   : ', get_code(FALSE, make_acodekeyl(make_codekey_null()      , make_codekey_bystr('-1'), make_codekey_bystr('101')    ));
SELECT 'c_nm (+l_id,-cf)   : ', get_code(FALSE, make_acodekeyl(make_codekey_byid(9001)  , make_codekey_null()     , make_codekey_bystr('502')     ));
SELECT 'c_nm (+l_id,+cf_id): ', get_code(FALSE, make_acodekeyl(make_codekey_byid(9001)  , make_codekey_byid(-1)   , make_codekey_bystr('код 101')));
SELECT 'c_nm (+l_id,+cf_nm): ', get_code(FALSE, make_acodekeyl(make_codekey_byid(9001)  , make_codekey_bystr('-1'), make_codekey_bystr('код 101')));
SELECT 'c_nm (+l_nm,-cf)   : ', get_code(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_null()     , make_codekey_bystr('502')     ));
SELECT 'c_nm (+l_nm,+cf_id): ', get_code(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_byid(-1)   , make_codekey_bystr('код 101')));
SELECT 'c_nm (+l_nm,+cf_nm): ', get_code(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('-1'), make_codekey_bystr('код 101')));
SELECT 'cf_id              : ', get_code(FALSE, make_acodekeyl(make_codekey_null()      , make_codekey_byid(-1)   , make_codekey_null()          ));
SELECT 'cf_nm (-l)         : ', get_code(FALSE, make_acodekeyl(make_codekey_null()      , make_codekey_bystr('-1'), make_codekey_null()          ));
SELECT 'cf_nm (+l_id)      : ', get_code(FALSE, make_acodekeyl(make_codekey_byid(9001)  , make_codekey_bystr('-1'), make_codekey_null()          ));
SELECT 'cf_nm (+l_nm)      : ', get_code(FALSE, make_acodekeyl(make_codekey_bystr('rus'), make_codekey_bystr('-1'), make_codekey_null()          ));

\echo >>>>"get_code" functions tested

\echo >>>>Testing "get_codes_l" function

SELECT 'undef           : ', a.* FROM get_codes_l(make_codekeyl_null()) AS a;
SELECT 'c_id            : ', a.* FROM get_codes_l(make_codekeyl_byid(360)) AS a;
SELECT 'c_nm (-l,-cf)   : ', a.* FROM get_codes_l(make_codekeyl_bystr('306')) AS a;
SELECT 'c_nm (+l_id,-cf): ', a.* FROM get_codes_l(make_codekeyl_bystrl(make_codekey_byid(9001)  , 'код 306')) AS a;
SELECT 'c_nm (+l_nm,-cf): ', a.* FROM get_codes_l(make_codekeyl_bystrl(make_codekey_bystr('rus'), 'код 306')) AS a;


\echo >>>>"get_codes_l" functions tested


\echo >>>>Testing "get_nonplaincode_by_str" function

SELECT get_nonplaincode_by_str('306');
SELECT get_nonplaincode_by_str('-1');

\echo >>>>"get_nonplaincode_by_str" functions tested

\echo >>>>Testing "get_code_by_str" function

SELECT get_code_by_str('203', '306');
SELECT get_code_by_str('-1', '306');
SELECT get_code_by_str('203', '-1');

\echo >>>>"get_code_by_str" functions tested


\echo >>>>Testing "get_codes_of_codifier" function

SELECT get_codes_of_codifier(make_acodekeyl_bystr1('101'));
SELECT get_codes_of_codifier(make_acodekeyl_bystr2('203', '306'));
SELECT get_codes_of_codifier(make_acodekeyl_null());

\echo >>>>"get_codes_of_codifier" functions tested

\echo >>>>Testing "get_codifiers_of_code" function

SELECT get_codifiers_of_code(make_acodekeyl_bystr2('309', '401'));
SELECT get_codifiers_of_code(make_acodekeyl_bystr2('309', '309'));
SELECT get_codifiers_of_code(make_acodekeyl_null());

\echo >>>>"get_codifiers_of_code" functions tested
\echo
\echo
SELECT c_from.code_text || '->' || c_to.code_text
FROM sch_<<$app_name$>>.codes as c_from
   , sch_<<$app_name$>>.codes as c_to
   , sch_<<$app_name$>>.codes_tree as ct
WHERE c_to.code_id = ct.subcode_id
  AND c_from.code_id = ct.supercode_id;
\echo
\echo
\echo >>>>Testing "find_subcodes" function

SELECT code_text AS c_text, code_id AS c_id, code_type AS c_type, tree_depth AS depth, nodes_path, path_terminated_with_cycle AS c FROM find_subcodes(TRUE,  make_acodekeyl_bystr1('101'), TRUE , FALSE) AS fc;
SELECT code_text AS c_text, code_id AS c_id, code_type AS c_type, tree_depth AS depth, nodes_path, path_terminated_with_cycle AS c FROM find_subcodes(TRUE,  make_acodekeyl_bystr1('101'), TRUE , TRUE ) AS fc;
SELECT code_text AS c_text, code_id AS c_id, code_type AS c_type, tree_depth AS depth, nodes_path, path_terminated_with_cycle AS c FROM find_subcodes(FALSE, make_acodekeyl_bystr1('101'), FALSE, FALSE) AS fc;
SELECT code_text AS c_text, code_id AS c_id, code_type AS c_type, tree_depth AS depth, nodes_path, path_terminated_with_cycle AS c FROM find_subcodes(FALSE, make_acodekeyl_bystr1('101'), FALSE, TRUE ) AS fc;

SELECT code_text AS c_text, code_id AS c_id, code_type AS c_type, tree_depth AS depth, nodes_path, path_terminated_with_cycle AS c FROM find_subcodes(FALSE, make_acodekeyl_bystr2('403', '502'), TRUE, FALSE) AS fc;

SELECT code_text AS c_text, code_id AS c_id, code_type AS c_type, tree_depth AS depth, nodes_path, path_terminated_with_cycle AS c FROM find_subcodes(TRUE,  make_acodekeyl_bystr1('-1'), FALSE, FALSE) AS fc;
SELECT code_text AS c_text, code_id AS c_id, code_type AS c_type, tree_depth AS depth, nodes_path, path_terminated_with_cycle AS c FROM find_subcodes(TRUE,  make_acodekeyl_bystr1('-1'), TRUE , FALSE) AS fc;
SELECT code_text AS c_text, code_id AS c_id, code_type AS c_type, tree_depth AS depth, nodes_path, path_terminated_with_cycle AS c FROM find_subcodes(FALSE, make_acodekeyl_bystr1('-1'), FALSE, FALSE) AS fc;
SELECT code_text AS c_text, code_id AS c_id, code_type AS c_type, tree_depth AS depth, nodes_path, path_terminated_with_cycle AS c FROM find_subcodes(FALSE, make_acodekeyl_bystr1('-1'), TRUE , FALSE) AS fc;

\echo >>>>"find_subcodes" functions tested

\echo >>>>Testing "remove_code" function

select remove_code(FALSE, make_acodekeyl_bystr1('101'), TRUE, TRUE, TRUE);
SELECT c_from.code_text || '->' || c_to.code_text AS x
FROM sch_<<$app_name$>>.codes as c_from
   , sch_<<$app_name$>>.codes as c_to
   , sch_<<$app_name$>>.codes_tree as ct
WHERE c_to.code_id = ct.subcode_id
  AND c_from.code_id = ct.supercode_id
ORDER BY x;
SELECT code_text FROM sch_<<$app_name$>>.codes ORDER BY code_text;
SELECT create_test_set();

select remove_code(FALSE, make_acodekeyl_bystr1('101'), FALSE, TRUE, TRUE);
SELECT c_from.code_text || '->' || c_to.code_text AS x
FROM sch_<<$app_name$>>.codes as c_from
   , sch_<<$app_name$>>.codes as c_to
   , sch_<<$app_name$>>.codes_tree as ct
WHERE c_to.code_id = ct.subcode_id
  AND c_from.code_id = ct.supercode_id
ORDER BY x;
SELECT code_text FROM sch_<<$app_name$>>.codes ORDER BY code_text;
SELECT create_test_set();

select remove_code(FALSE, make_acodekeyl_bystr1('101'), FALSE, FALSE, TRUE);
SELECT c_from.code_text || '->' || c_to.code_text AS x
FROM sch_<<$app_name$>>.codes as c_from
   , sch_<<$app_name$>>.codes as c_to
   , sch_<<$app_name$>>.codes_tree as ct
WHERE c_to.code_id = ct.subcode_id
  AND c_from.code_id = ct.supercode_id
ORDER BY x;
SELECT code_text FROM sch_<<$app_name$>>.codes ORDER BY code_text;
SELECT create_test_set();

select remove_code(FALSE, make_acodekeyl_bystr1('101'), FALSE, TRUE, FALSE);
SELECT c_from.code_text || '->' || c_to.code_text AS x
FROM sch_<<$app_name$>>.codes as c_from
   , sch_<<$app_name$>>.codes as c_to
   , sch_<<$app_name$>>.codes_tree as ct
WHERE c_to.code_id = ct.subcode_id
  AND c_from.code_id = ct.supercode_id
ORDER BY x;
SELECT code_text FROM sch_<<$app_name$>>.codes ORDER BY code_text;
SELECT create_test_set();

\echo >>>>"remove_code" functions tested

\echo >>>>Testing triggers

\echo >>> These shoulde raise exceptions:
SELECT new_code(
          ROW('201', 'plain code') :: code_construction_input
        , make_codekeyl_bystr('101')
        , FALSE
        );
SELECT new_code(
          ROW('501', 'plain code') :: code_construction_input
        , make_codekeyl_bystr('402')
        , FALSE
        );
SELECT new_code(
          ROW('210', 'plain code') :: code_construction_input
        , make_codekeyl_bystr('101')
        , TRUE
        );
SELECT add_subcodes_under_codifier(
          make_codekeyl_bystr('501')
        , '601'
        , VARIADIC ARRAY[
                  ROW('601', 'codifier')
                , ROW('602', 'codifier')
                ] :: code_construction_input[]
        );
SELECT make_codifier_from_plaincode_w_values(
          TRUE
        , TRUE
        , make_codekeyl_bystr('501')
        , 'codifier'
        , '602'
        , VARIADIC ARRAY[
                  ROW('601', 'codifier')
                , ROW('603', 'codifier')
                ] :: code_construction_input[]
        );
SELECT add_code_lng_names(
          TRUE
        , make_acodekeyl_bystr1('304')
        , VARIADIC ARRAY[
                  mk_name_construction_input(make_codekeyl_bystr('rus'), 'код 306' , make_codekeyl_null(), 'Описание кодификатора 306.')
                , mk_name_construction_input(make_codekeyl_bystr('eng'), 'code 304' , make_codekeyl_null(), 'Description of 304.')
                ] :: name_construction_input[]
        );
SELECT add_code_lng_names(
          TRUE
        , make_acodekeyl_bystr1('303')
        , VARIADIC ARRAY[
                  mk_name_construction_input(make_codekeyl_bystr('rus'), 'код 306' , make_codekeyl_null(), 'Описание кодификатора 306.')
                , mk_name_construction_input(make_codekeyl_bystr('eng'), 'code 304' , make_codekeyl_null(), 'Description of 304.')
                ] :: name_construction_input[]
        );
SELECT add_code_lng_names(
          TRUE
        , make_acodekeyl_bystr1('305')
        , VARIADIC ARRAY[
                  mk_name_construction_input(make_codekeyl_bystr('rus'), 'код 306' , make_codekeyl_null(), 'Описание кодификатора 306.')
                , mk_name_construction_input(make_codekeyl_bystr('eng'), 'code 304' , make_codekeyl_null(), 'Description of 304.')
                ] :: name_construction_input[]
        );

\echo >>>>Triggers tested

SELECT   remove_code(TRUE, make_acodekeyl_bystr1('999'), TRUE, TRUE, TRUE);
SELECT find_subcodes(TRUE, make_acodekeyl_bystr1('101'), TRUE, FALSE);

--------------------

\echo >>>>Testing dedicated codifier-tables

SELECT new_codifier_w_subcodes(
                make_codekeyl_bystr('Root')
              , ROW('DCT test cf', 'codifier') :: code_construction_input
              , 'aaa'
              , VARIADIC ARRAY[
                        ROW('aaa', 'plain code')
                      , ROW('bbb', 'plain code')
                      , ROW('ccc', 'plain code')
                      , ROW('ddd', 'plain code')
                      ] :: code_construction_input[]
              );

\echo >>>>NOTICE: should raise error (dct not found)
SELECT new_dedicated_codifiertable(
                make_codekeyl_bystr('DCT test cf')
              , 'dct_test_cf'
              , TRUE
              , TRUE
              );
\c <<$db_name$>> user_db<<$db_name$>>_app<<$app_name$>>_owner
SELECT new_dedicated_codifiertable(
                make_codekeyl_bystr('DCT test cf')
              , 'dct_test_cf'
              , FALSE
              , TRUE
              );
\c <<$db_name$>> user_db<<$db_name$>>_app<<$app_name$>>_data_admin
SELECT * FROM dct_test_cf;

SELECT code_id_of(FALSE, make_acodekeyl_bystr2('DCT test cf', 'aaa'));
UPDATE codes SET code_text = 'aaa1' WHERE code_id IN (SELECT code_id_of(FALSE, make_acodekeyl_bystr2('DCT test cf', 'aaa')));
UPDATE codes SET code_text = 'DCT test codifier' WHERE code_id IN (SELECT code_id_of(FALSE, make_acodekeyl_bystr1('DCT test cf')));
SELECT * FROM dedicated_codifiertables;
SELECT * FROM dct_test_cf;
DELETE FROM codes WHERE code_id IN (SELECT code_id_of(FALSE, make_acodekeyl_bystr2('DCT test codifier', 'aaa1')));
SELECT * FROM dct_test_cf;
INSERT INTO codes (code_id, code_text, code_type) VALUES (-1000, 'aaa_reborn', 'plain code');
INSERT INTO codes_tree (supercode_id, subcode_id) VALUES (code_id_of(FALSE, make_acodekeyl_bystr1('DCT test codifier')), -1000);
SELECT * FROM dct_test_cf;
UPDATE dedicated_codifiertables SET full_indexing = FALSE WHERE codifier_text = 'DCT test codifier';
INSERT INTO codes (code_id, code_text, code_type) VALUES (-1001, 'aaa_reborn2', 'plain code');
INSERT INTO codes_tree (supercode_id, subcode_id) VALUES (code_id_of(FALSE, make_acodekeyl_bystr1('DCT test codifier')), -1001);
SELECT * FROM dct_test_cf;
INSERT INTO dct_test_cf(code_id, code_text) VALUES (-1001, 'aaa_reborn2');
SELECT * FROM dct_test_cf;

SELECT remove_dedicated_codifiertable(make_codekeyl_bystr('DCT test codifier'), 'dct_test_cf', FALSE);
\c <<$db_name$>> user_db<<$db_name$>>_app<<$app_name$>>_owner
SELECT remove_dedicated_codifiertable(make_codekeyl_bystr('DCT test codifier'), 'dct_test_cf', TRUE);
\c <<$db_name$>> user_db<<$db_name$>>_app<<$app_name$>>_data_admin
SELECT * FROM dedicated_codifiertables;
SELECT remove_code(TRUE, make_acodekeyl_bystr1('DCT test codifier'), TRUE, TRUE, TRUE);

\echo >>>>Testing dedicated codifier-tables FINISHED

--------------------

SELECT * FROM codes;
SELECT * FROM codes_tree;
SELECT * FROM codes_names;

SELECT remove_test_set();

\echo WARNING!
\echo WARNING!
\echo WARNING!
\echo This test MUST return TRUE, orelse some initial data is corrupted by tests.
SELECT code_belongs_to_codifier(FALSE, make_acodekeyl_bystr2('Common nominal codes set', 'undefined'));

\echo =======Administration and lookup functions tested============

\echo =======Cleaning up after testing=============================

\c <<$db_name$>> user_db<<$db_name$>>_app<<$app_name$>>_owner
\set ECHO queries
SELECT set_config('client_min_messages', 'NOTICE', FALSE);

DROP FUNCTION remove_test_set();
DROP FUNCTION create_test_set();

ALTER SEQUENCE codifiers_ids_seq   MINVALUE   1000 RESTART WITH   1000 INCREMENT BY 10;
ALTER SEQUENCE plain_codes_ids_seq MINVALUE 100000 RESTART WITH 100000 INCREMENT BY 10;

SELECT * FROM codes;
SELECT * FROM codes_tree;
SELECT * FROM codes_names;

\echo =======Clean up after testing finished=======================

\echo --------------------------------------------------------------

\echo NOTICE >>>>>> tests.sql [END]