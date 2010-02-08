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

-- Referencing functions:

DROP FUNCTION IF EXISTS make_codekey(par_code_id integer, par_code_text varchar);
DROP FUNCTION IF EXISTS make_codekey_null();
DROP FUNCTION IF EXISTS make_codekey_byid(par_code_id integer);
DROP FUNCTION IF EXISTS make_codekey_bystr(par_code_text varchar);
DROP FUNCTION IF EXISTS make_acodekey(par_cf_key t_code_key, par_c_key t_code_key);
DROP FUNCTION IF EXISTS make_acodekey_null();
DROP FUNCTION IF EXISTS make_codekeyl(par_key_lng t_code_key, par_code_key t_code_key);
DROP FUNCTION IF EXISTS make_codekeyl_null();
DROP FUNCTION IF EXISTS make_codekeyl_byid(par_code_id integer);
DROP FUNCTION IF EXISTS make_codekeyl_bystr(par_code_text varchar);
DROP FUNCTION IF EXISTS make_codekeyl_bystrl(par_lng_key t_code_key, par_code_text varchar);
DROP FUNCTION IF EXISTS make_acodekeyl(par_key_lng t_code_key, par_cf_key t_code_key, par_c_key t_code_key);
DROP FUNCTION IF EXISTS make_acodekeyl_null();
DROP FUNCTION IF EXISTS make_acodekeyl_byid(par_code_id integer);
DROP FUNCTION IF EXISTS make_acodekeyl_bystr1(par_code_text varchar);
DROP FUNCTION IF EXISTS make_acodekeyl_bystr2(par_codifier_text varchar, par_code_text varchar);
DROP FUNCTION IF EXISTS show_codekey(par_key t_code_key);
DROP FUNCTION IF EXISTS show_acodekey(par_key t_addressed_code_key);
DROP FUNCTION IF EXISTS show_codekeyl(par_key t_code_key_by_lng);
DROP FUNCTION IF EXISTS show_acodekeyl(par_key t_addressed_code_key_by_lng);
DROP FUNCTION IF EXISTS generalize_codekey(par_key t_code_key);
DROP FUNCTION IF EXISTS generalize_codekeyl(par_key t_code_key_by_lng);
DROP FUNCTION IF EXISTS generalize_acodekey(par_key t_addressed_code_key);
DROP FUNCTION IF EXISTS generalize_codekey_wcf(par_cf_codekey t_code_key, par_key t_code_key);
DROP FUNCTION IF EXISTS generalize_codekeyl_wcf(par_cf_codekey t_code_key, par_key t_code_key_by_lng);
DROP FUNCTION IF EXISTS codekey_type(par_key t_code_key);
DROP FUNCTION IF EXISTS acodekey_type(par_key t_addressed_code_key);
DROP FUNCTION IF EXISTS codekeyl_type(par_key t_code_key_by_lng);
DROP FUNCTION IF EXISTS acodekeyl_type(par_key t_addressed_code_key_by_lng);
DROP FUNCTION IF EXISTS mk_name_construction_input(par_lng t_code_key_by_lng, par_name varchar, par_entity t_code_key_by_lng, par_description varchar);

-- Lookup functions:

DROP FUNCTION IF EXISTS optimize_acodekeyl(par_acodekeyl t_addressed_code_key_by_lng, par_determine_mask integer);
DROP FUNCTION IF EXISTS code_id_of(par_if_exists boolean, par_acodekeyl t_addressed_code_key_by_lng);
DROP FUNCTION IF EXISTS code_id_of_undefined();
DROP FUNCTION IF EXISTS code_id_of_unclassified();
DROP FUNCTION IF EXISTS code_id_of_error();
DROP FUNCTION IF EXISTS code_id_of_ambiguous();
DROP FUNCTION IF EXISTS code_id_of_language(varchar);
DROP FUNCTION IF EXISTS code_id_of_entity(entity_code_text varchar);
DROP FUNCTION IF EXISTS codifier_id_of(par_if_exists boolean, par_cf_keyl t_code_key_by_lng);
DROP FUNCTION IF EXISTS code_belongs_to_codifier(par_if_cf_exists boolean, par_acodekeyl t_addressed_code_key_by_lng);
DROP FUNCTION IF EXISTS get_code(par_if_exists boolean, par_key t_addressed_code_key_by_lng);
DROP FUNCTION IF EXISTS codifier_default_code(par_if_exists boolean, par_cf_keyl t_code_key_by_lng);
DROP FUNCTION IF EXISTS get_codes_l(par_key t_code_key_by_lng);
DROP FUNCTION IF EXISTS get_nonplaincode_by_str(par_codifier varchar);
DROP FUNCTION IF EXISTS get_code_by_str(par_codifier varchar, par_code varchar);
DROP FUNCTION IF EXISTS get_codes_of_codifier(par_acodekeyl t_addressed_code_key_by_lng);
DROP FUNCTION IF EXISTS get_codifiers_of_code(par_acodekeyl t_addressed_code_key_by_lng);
DROP FUNCTION IF EXISTS find_subcodes(par_if_exists boolean, par_cf_key t_addressed_code_key_by_lng, par_include_code_itself boolean, par_only_ones_not_reachable_from_elsewhere boolean);

-- Administration functions:

DROP FUNCTION IF EXISTS remove_code(par_if_exists boolean, par_acodekeyl t_addressed_code_key_by_lng, par_remove_code boolean, par_cascade_remove_subcodes boolean, par_if_cascade__only_ones_not_reachable_from_elsewhere boolean);
DROP FUNCTION IF EXISTS bind_code_to_codifier(par_c_acodekeyl t_addressed_code_key_by_lng, par_cf_codekeyl t_code_key_by_lng, par_dflt boolean);
DROP FUNCTION IF EXISTS unbind_code_from_codifier(par_if_exists boolean, par_c_acodekeyl t_addressed_code_key_by_lng);
DROP FUNCTION IF EXISTS new_code_by_userseqs(par_code_construct code_construction_input, par_super_code t_code_key_by_lng, par_dflt_isit boolean, par_codifier_ids_seq_name varchar, par_plaincode_ids_seq_name varchar);
DROP FUNCTION IF EXISTS new_code(par_code_construct code_construction_input, par_super_code t_code_key_by_lng, par_dflt_isit boolean);
DROP FUNCTION IF EXISTS add_subcodes_under_codifier(par_cf t_code_key_by_lng, par_cf_dflt_codestr varchar, VARIADIC par_codes_array code_construction_input[]);
DROP FUNCTION IF EXISTS new_codifier_w_subcodes(par_super_cf t_code_key_by_lng, par_cf_construct code_construction_input, par_cf_dflt_codestr varchar, VARIADIC par_codes_array code_construction_input[]);
DROP FUNCTION IF EXISTS make_codifier_from_plaincode(par_if_exists boolean, par_reidentify boolean, par_cf t_code_key_by_lng, par_cf_new_type code_type);
DROP FUNCTION IF EXISTS make_codifier_from_plaincode_w_values(par_if_exists boolean, par_reidentify boolean, par_c t_code_key_by_lng, par_cf_new_type code_type, par_cf_dflt_codestr varchar, VARIADIC par_codes_array code_construction_input[]);
DROP FUNCTION IF EXISTS add_code_lng_names(par_if_exists boolean, par_c t_addressed_code_key_by_lng, VARIADIC par_codesnames_array name_construction_input[]);


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

DROP TYPE IF EXISTS name_construction_input;
DROP TYPE IF EXISTS result_of_making_new_codifier_w_subcodes;
DROP TYPE IF EXISTS code_construction_input;
DROP TYPE IF EXISTS codes_tree_node;
DROP TYPE IF EXISTS t_code_key_type;
DROP TYPE IF EXISTS t_addressed_code_key_by_lng;
DROP TYPE IF EXISTS t_code_key_by_lng;
DROP TYPE IF EXISTS t_addressed_code_key;
DROP TYPE IF EXISTS t_code_key;




