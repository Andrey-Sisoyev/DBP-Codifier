-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
-- 
-- All rights reserved.
-- 
-- For information about license see COPYING file in the root directory of current nominal package

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- (1) case sensetive (2) postgres lowercases real names
\c <<$db_name$>> user_<<$app_name$>>_owner

SET search_path TO sch_<<$app_name$>>, public; -- sets only for current session

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- DROP FUNCTION IF EXISTS ...
-- DROP TYPE     IF EXISTS ...

DROP FUNCTION IF EXISTS make_codifier_from_plaincode_w_values(
          par_reidentify boolean
        , par_cf_id integer
        , par_cf_new_type code_type
        , par_cf_dflt_codestr varchar
        , VARIADIC par_codes_array code_construction_input[] -- par_cf_dflt_codestr must persist in this array
        );
DROP FUNCTION IF EXISTS new_codifier_w_subcodes(
          par_supercf_name varchar
        , par_cf_construct code_construction_input
        , par_cf_dflt_codestr varchar
        , VARIADIC par_codes_array code_construction_input[] -- par_cf_dflt_codestr must persist in this array
        );
DROP FUNCTION IF EXISTS add_subcodes_under_codifier_byid(
          par_cf_id integer
        , par_cf_dflt_codestr varchar
        , VARIADIC par_codes_array code_construction_input[] -- par_cf_dflt_codestr must persist in this array
        );
DROP FUNCTION IF EXISTS add_subcodes_under_codifier_bystr(
          par_cf_name varchar
        , par_cf_dflt_codestr varchar
        , VARIADIC par_codes_array code_construction_input[] -- par_cf_dflt_codestr must persist in this array
        );
DROP FUNCTION IF EXISTS make_codifier_from_plaincode(
          par_reidentify boolean
        , par_cf_id integer
        , par_cf_new_type code_type
        );
DROP FUNCTION IF EXISTS bind_code_to_codifier(par_code_id integer, par_codifier_id integer, par_dflt boolean);
DROP FUNCTION IF EXISTS unbind_code_from_codifier(if_exists boolean, par_code_id integer, par_codifier_id integer);
DROP FUNCTION IF EXISTS new_code(par_code_construct code_construction_input, par_super_code_id integer)      ;
DROP FUNCTION IF EXISTS new_codifier(par_code_construct code_construction_input, par_super_code_id integer)  ;
DROP FUNCTION IF EXISTS remove_subcodes_by_codifierid(par_c integer, par_cascade boolean, par_greedy boolean);
DROP FUNCTION IF EXISTS remove_codifier_w_subcodes_byid(par_c integer, par_cascade boolean, par_greedy boolean);
DROP FUNCTION IF EXISTS remove_codifier_bystr(if_exists boolean, par_cf varchar)                             ;
DROP FUNCTION IF EXISTS remove_code_byid(par_c integer)                                                      ;
DROP FUNCTION IF EXISTS remove_code_bystr(if_exists boolean, par_cf varchar, par_c varchar)                  ;
DROP FUNCTION IF EXISTS get_alldepths_subcodes_of_codifier(par_cf_id integer)                                ;
DROP FUNCTION IF EXISTS get_codes_of_codifier_byid(par_codifier_id integer)                                  ;
DROP FUNCTION IF EXISTS get_codes_of_codifier_bystr(par_codifier_name varchar)                               ;
DROP FUNCTION IF EXISTS get_codifiers_of_code_byid(par_code_id integer)                                      ;
DROP FUNCTION IF EXISTS type_of_code(par_code_id integer)                                                    ;
DROP FUNCTION IF EXISTS get_code_by_codeid(par_code_id integer)                                              ;
DROP FUNCTION IF EXISTS get_nonplaincode_by_codestr(par_codifier varchar)                                    ;
DROP FUNCTION IF EXISTS get_codified_view_by_codestr(par_codifier varchar, par_code varchar)                 ;
DROP FUNCTION IF EXISTS codifier_default_code_byid(par_if_exists boolean, par_cf_id integer)                 ;
DROP FUNCTION IF EXISTS codifier_default_code_bystr(par_if_exists boolean, par_cf_name varchar)              ;
DROP FUNCTION IF EXISTS code_belongs_to_codifier(par_code_id integer, par_codifier_text varchar)             ;

DROP TYPE IF EXISTS codified_view;
DROP TYPE IF EXISTS code_construction_input;
