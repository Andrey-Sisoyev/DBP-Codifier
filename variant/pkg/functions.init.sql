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

-- CREATE TYPE ...
-- CREATE OR REPLACE FUNCTION ...

CREATE OR REPLACE FUNCTION code_belongs_to_codifier(par_code_id integer, par_codifier_text varchar) RETURNS boolean AS $$
DECLARE
        e boolean;
	cnt integer;
BEGIN
        SELECT TRUE
        INTO e
        FROM sch_<<$app_name$>>.codes_tree AS ct, sch_<<$app_name$>>.codes AS c
        WHERE c.code_text     = par_codifier_text
	  AND ct.supercode_id = c.code_id
	  AND ct.subcode_id   = par_code_id;
        
        GET DIAGNOSTICS cnt = ROW_COUNT;

        IF cnt = 0 THEN
                RETURN FALSE; 
        ELSIF cnt > 1 THEN
                RAISE EXCEPTION 'Data inconsistecy error detected, when trying to check, if code {ID:%} belongs to codifier "%"! Multiple belongings are found, but only one must have been.', par_code_id, par_codifier_text;
                RETURN FALSE; 
	ELSE 
		RETURN TRUE; 
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TYPE codified_view AS (
        subcode_id            integer 
      , subcode_text          varchar 
      , subcode_type          code_type
      , supercode_id          integer 
      , supercode_text        varchar 
      , supercode_type        code_type 
      , default_subcode_isit  boolean 
);

CREATE OR REPLACE FUNCTION get_codified_view_by_codestr(par_codifier varchar, par_code varchar) RETURNS codified_view AS $$
DECLARE
        cv codified_view%ROWTYPE;
        cnt integer;
BEGIN
        SELECT c_sub.code_id        AS subcode_id
             , c_sub.code_text      AS subcode_text
             , c_sub.code_type      AS subcode_type
             , c_super.code_id      AS supercode_id
             , c_super.code_text    AS supercode_text
             , c_super.code_type    AS supercode_type
             , ct.dflt_subcode_isit AS default_subcode_isit
        INTO cv
        FROM sch_<<$app_name$>>.codes AS c_sub, sch_<<$app_name$>>.codes_tree AS ct, sch_<<$app_name$>>.codes AS c_super
        WHERE   c_sub.code_text = par_code
          AND c_super.code_text = par_codifier
          AND ct.supercode_id   = c_super.code_id
          AND ct.subcode_id     =   c_sub.code_id;
        
        GET DIAGNOSTICS cnt = ROW_COUNT;

        IF cnt = 0 THEN
                RETURN NULL; 
        ELSIF cnt > 1 THEN
                RAISE EXCEPTION 'Data inconsistecy error detected, when trying to read a code "%" from codifier "%"! Multiple codes has such names (which is illegal), can not decide, which one to return.', par_code, par_codifier;
                RETURN NULL; 
        END IF;

        RETURN cv;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_nonplaincode_by_codestr(par_codifier varchar) RETURNS sch_<<$app_name$>>.codes AS $$
DECLARE
        ccc sch_<<$app_name$>>.codes%ROWTYPE;
        cnt integer;
BEGIN
        SELECT c.*
        INTO ccc
        FROM sch_<<$app_name$>>.codes AS c
        WHERE c.code_text = $1;
        
        GET DIAGNOSTICS cnt = ROW_COUNT;

        IF cnt = 0 THEN
                RETURN NULL; 
        ELSIF cnt > 1 THEN
                RAISE EXCEPTION 'Data inconsistecy error detected, when trying to read a codifier "%"! Multiple nonplain codes has such names (which is illegal), can not decide, which one to return.', par_codifier;
                RETURN NULL; 
        END IF;

        RETURN ccc;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION type_of_code(par_code_id integer) RETURNS code_type AS $$
        SELECT c.code_type
        FROM sch_<<$app_name$>>.codes AS c
        WHERE c.code_id = $1;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_code_by_codeid(par_code_id integer) RETURNS sch_<<$app_name$>>.codes AS $$
        SELECT c.* 
        FROM sch_<<$app_name$>>.codes AS c
        WHERE c.code_id=$1;
$$ LANGUAGE SQL;

---------------------------------------

CREATE OR REPLACE FUNCTION get_codes_of_codifier_byid(par_codifier_id integer) RETURNS SETOF sch_<<$app_name$>>.codes AS $$ 
        SELECT c.*
        FROM sch_<<$app_name$>>.codes AS c, sch_<<$app_name$>>.codes_tree AS ct
        WHERE c.code_id = ct.subcode_id
          AND ct.supercode_id = $1;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_codes_of_codifier_bystr(par_codifier_name varchar) RETURNS SETOF sch_<<$app_name$>>.codes AS $$ 
        SELECT c_sub.*
        FROM sch_<<$app_name$>>.codes AS c_sub, sch_<<$app_name$>>.codes_tree AS ct, sch_<<$app_name$>>.codes AS c_super
        WHERE c_sub.code_id = ct.subcode_id
          AND ct.supercode_id = c_super.code_id
          AND c_super.code_text = $1;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_codifiers_of_code_byid(par_code_id integer) RETURNS SETOF sch_<<$app_name$>>.codes AS $$ 
        SELECT c_super.*
        FROM sch_<<$app_name$>>.codes AS c_super, sch_<<$app_name$>>.codes_tree AS ct
        WHERE c_super.code_id = ct.supercode_id
          AND ct.subcode_id = $1;
$$ LANGUAGE SQL;

---------------------------------------

CREATE OR REPLACE FUNCTION remove_code_bystr(if_exists boolean, par_cf varchar, par_c varchar) RETURNS integer AS $$ -- must return at least 1 (for the codifier), orelse an error occurred
DECLARE
        cv codified_view;
        cnt integer;
BEGIN
        cv := get_codified_view_by_codestr(par_cf, par_c);

        IF cv IS NULL AND (NOT if_exists) THEN
                RAISE EXCEPTION 'An error occurred, when trying to delete a code "%" from codifier "%"! Not found.', par_c, par_cf;
                RETURN 0; 
        ELSIF cv IS NULL THEN
                RETURN 0; 
        END IF;

        DELETE FROM sch_<<$app_name$>>.codes WHERE code_id = cv.subcode_id;

        GET DIAGNOSTICS cnt = ROW_COUNT;

        RETURN cnt;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION remove_code_byid(par_c integer) RETURNS integer AS $$ -- must return at least 1 (for the codifier), orelse an error occurred
DECLARE
        cnt integer;
BEGIN
        DELETE FROM sch_<<$app_name$>>.codes WHERE code_id = par_c;

        GET DIAGNOSTICS cnt = ROW_COUNT;

        RETURN cnt;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION remove_codifier_bystr(if_exists boolean, par_cf varchar) RETURNS integer AS $$ -- must return at least 1 (for the codifier), orelse an error occurred
DECLARE 
        c sch_<<$app_name$>>.codes%ROWTYPE;
        cnt integer;
BEGIN
        c:= get_nonplaincode_by_codestr(par_cf);

        IF c IS NULL AND (NOT if_exists) THEN
                RAISE EXCEPTION 'An error occurred, when trying to delete a codifier "%"! Not found.', par_cf;
                RETURN 0; 
        ELSIF c IS NULL THEN
                RETURN 0; 
        END IF;

        DELETE FROM sch_<<$app_name$>>.codes WHERE code_id = c.code_id;

        GET DIAGNOSTICS cnt = ROW_COUNT;

        RETURN cnt;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_alldepths_subcodes_of_codifier(par_cf_id integer) RETURNS SETOF integer AS $$ 
        WITH RECURSIVE subcodes(r_supercode_id) AS (
            VALUES ($1)
          UNION
            SELECT subcode_id 
            FROM sch_<<$app_name$>>.codes_tree AS ct, subcodes AS sc
            WHERE ct.supercode_id = sc.r_supercode_id
        )
        SELECT r_supercode_id FROM subcodes;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION remove_subcodes_by_codifierid(par_c integer, par_cascade boolean, par_greedy boolean) RETURNS integer AS $$ -- must return at least 1 (for the codifier), orelse an error occurred
DECLARE
        cnt integer;
        subcodes integer[];
        heavyused_subcodes integer[];
BEGIN
        IF par_cascade = FALSE THEN
                SELECT count(*) INTO cnt
                FROM sch_<<$app_name$>>.codes_tree AS ct_super, sch_<<$app_name$>>.codes_tree AS ct_sub
                WHERE par_c = ct_super.supercode_id
                  AND ct_super.subcode_id = ct_sub.supercode_id;
                
                IF cnt > 0 THEN
                        RAISE EXCEPTION 'An error occurred, when trying to delete subcodes of the codifier {ID:"%"}! Subcodes has their own subcodes, but cascade option is "false".', par_c;
                        RETURN 0; 
                END IF;
        END IF;
        
        subcodes := ARRAY (SELECT * FROM get_alldepths_subcodes_of_codifier(par_c));

        IF NOT par_greedy THEN
                heavyused_subcodes := 
                     ARRAY(
                         SELECT subcode_id
                         FROM sch_<<$app_name$>>.codes_tree
                         WHERE     subcodes @> ARRAY[subcode_id]
                           AND NOT subcodes @> ARRAY[supercode_id]
                           AND supercode_id != par_c
                     );
                subcodes := 
                     ARRAY (
                        SELECT * 
                        FROM unnest(subcodes) AS sc(sc_id)
                        WHERE NOT (ARRAY[sc_id] <@ heavyused_subcodes)
                     );
        END IF;
        
        DELETE FROM sch_<<$app_name$>>.codes WHERE ARRAY[code_id] <@ subcodes AND code_id != par_c;

        GET DIAGNOSTICS cnt = ROW_COUNT;

        RETURN cnt;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION remove_codifier_w_subcodes_byid(par_c integer, par_cascade boolean, par_greedy boolean) RETURNS integer AS $$ -- must return at least 1 (for the codifier), orelse an error occurred
DECLARE
        cnt integer;
        sc_id integer;
        subcodes integer[];
BEGIN
        cnt := remove_subcodes_by_codifierid(par_c, par_cascade, par_greedy);
        DELETE FROM sch_<<$app_name$>>.codes WHERE code_id = par_c;

        RETURN (cnt+1);
END;
$$ LANGUAGE plpgsql;

-----------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION bind_code_to_codifier(par_code_id integer, par_codifier_id integer, par_dflt boolean) RETURNS boolean AS $$ 
BEGIN
        INSERT INTO sch_<<$app_name$>>.codes_tree (supercode_id, subcode_id, dflt_subcode_isit) 
        VALUES (par_codifier_id, par_code_id, COALESCE(par_dflt, FALSE));
        
        RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION unbind_code_from_codifier(if_exists boolean, par_code_id integer, par_codifier_id integer) RETURNS integer AS $$ 
DECLARE 
        cnt integer:= 0;
BEGIN
        DELETE FROM sch_<<$app_name$>>.codes_tree WHERE supercode_id = par_codifier_id AND subcode_id = par_code_id;

        GET DIAGNOSTICS cnt = ROW_COUNT;

        IF (cnt IS NULL OR cnt != 1) AND (NOT if_exists) THEN
                RAISE EXCEPTION 'An error occurred, when trying to unbind code {ID:%} from codifier {ID:%}! Bad count (%) of rows modified.', par_code_id, par_codifier_id, cnt;
                RETURN cnt; 
        END IF;

        RETURN cnt;
END;
$$ LANGUAGE plpgsql;

CREATE TYPE code_construction_input AS (code_text varchar, code_type code_type);

CREATE OR REPLACE FUNCTION new_code(par_code_construct code_construction_input, par_super_code_id integer) RETURNS integer AS $$ -- returns code_id
DECLARE
        c_id integer;
        success boolean;
BEGIN
        IF par_code_construct.code_type = 'plain code' THEN
                c_id := nextval('sch_<<$app_name$>>.plain_codes_ids_seq');
        ELSE
                c_id := nextval('sch_<<$app_name$>>.codifiers_ids_seq');
        END IF;

        INSERT INTO sch_<<$app_name$>>.codes (code_id, code_text, code_type) 
        VALUES (c_id, par_code_construct.code_text, par_code_construct.code_type);

        IF NOT (par_super_code_id IS NULL) THEN
                success:= bind_code_to_codifier(c_id, par_super_code_id, FALSE);
        END IF;

        RETURN c_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION new_codifier(par_code_construct code_construction_input, par_super_code_id integer) RETURNS integer AS $$ -- returns code_id
DECLARE
        c_id integer;
        success boolean;
BEGIN
        IF par_code_construct.code_type = 'plain code' THEN
                RAISE EXCEPTION 'An error occurred, in the function "new_codifier", with an input to register codifier "%"! The code of codifier should not be of "plain code" type.', par_code_construct.code_text;
                RETURN 0;         
        END IF;

        INSERT INTO sch_<<$app_name$>>.codes (code_id, code_text, code_type) 
        VALUES (nextval('sch_<<$app_name$>>.codifiers_ids_seq'), par_code_construct.code_text, par_code_construct.code_type)
        RETURNING code_id INTO c_id;

        IF NOT (par_super_code_id IS NULL) THEN
                success:= bind_code_to_codifier(c_id, par_super_code_id, FALSE);
        END IF;

        RETURN c_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION new_code(par_code_construct code_construction_input, par_super_code_id integer)  
        IS 'The parameter - a "code_construction_input" element: if "code_type" field of it is "plain code", then "plain_codes_ids_seq" sequence is used to generate ID for new code, else "codifiers_ids_seq" sequence is used.';

CREATE OR REPLACE FUNCTION add_subcodes_under_codifier_byid(
          par_cf_id integer
        , par_cf_dflt_codestr varchar
        , VARIADIC par_codes_array code_construction_input[] -- par_cf_dflt_codestr must persist in this array
        ) 
RETURNS integer AS $$ 
DECLARE
        cnt integer;
        dflt_pers boolean;
        i integer;
        cf_id integer;
        c_id integer;
        sc sch_<<$app_name$>>.codes;
        s boolean;
BEGIN
        cf_id:= par_cf_id;
        dflt_pers := (par_cf_dflt_codestr IS NULL) OR (par_cf_dflt_codestr = '');

        FOR i IN 1..COALESCE(array_upper(par_codes_array, 1), 0) LOOP
                dflt_pers := dflt_pers OR ((par_codes_array[i]).code_text = par_cf_dflt_codestr);
        END LOOP;

        IF NOT dflt_pers THEN
                RAISE EXCEPTION 'An error occurred, when trying to add subcodes under a codifier with ID "%"! The default code is specified to = "%", but it is not in the lists codes.', par_cf_id, par_cf_dflt_codestr;
                RETURN 0; 
        END IF;

        cnt:= 0;

        FOR i IN 1..COALESCE(array_upper(par_codes_array, 1), 0) LOOP
                c_id := new_code(par_codes_array[i], NULL :: integer);
                s:= bind_code_to_codifier(c_id, cf_id, par_cf_dflt_codestr = (par_codes_array[i]).code_text);
                cnt:= cnt + 1;
        END LOOP;

        RETURN cf_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION add_subcodes_under_codifier_bystr(
          par_cf_name varchar
        , par_cf_dflt_codestr varchar
        , VARIADIC par_codes_array code_construction_input[] -- par_cf_dflt_codestr must persist in this array
        ) 
RETURNS integer AS $$ 
DECLARE
        sc sch_<<$app_name$>>.codes;
BEGIN
        sc:= get_nonplaincode_by_codestr(par_cf_name);
        
        IF sc IS NULL THEN
                RAISE EXCEPTION 'An error occurred, when trying to add subcodes under a codifier with the name "%"! Specified codifier not found.', par_cf_name;
                RETURN 0; 
        END IF;
        
        RETURN add_subcodes_under_codifier_byid (sc.code_id, par_cf_dflt_codestr, VARIADIC par_codes_array);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION new_codifier_w_subcodes(
          par_supercf_name varchar
        , par_cf_construct code_construction_input
        , par_cf_dflt_codestr varchar
        , VARIADIC par_codes_array code_construction_input[] -- par_cf_dflt_codestr must persist in this array
        ) 
RETURNS integer AS $$ 
DECLARE
        cnt integer;
        dflt_pers boolean;
        i integer;
        supercf_id integer;
        cf_id integer;
        c_id integer;
        sc sch_<<$app_name$>>.codes;
BEGIN
        supercf_id:= add_subcodes_under_codifier_bystr(par_supercf_name, NULL :: varchar, VARIADIC ARRAY[par_cf_construct]);

        sc:= get_nonplaincode_by_codestr(par_cf_construct.code_text);
        
        cnt:= add_subcodes_under_codifier_byid(sc.code_id, par_cf_dflt_codestr, VARIADIC par_codes_array);

        RETURN sc.code_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION make_codifier_from_plaincode(
          par_reidentify boolean
        , par_cf_id integer
        , par_cf_new_type code_type
        ) 
RETURNS integer AS $$
DECLARE
        cnt integer;
        dflt_pers boolean;
        no_bad_code_isthere boolean;
        i integer;
        supercf_id integer;
        cf_id integer;
        c_id integer;
        sc sch_<<$app_name$>>.codes%ROWTYPE;
BEGIN
        -- validate input data
        IF par_cf_new_type = 'plain code' THEN
                RAISE EXCEPTION 'An error occurred, in the function "make_codifier_from_plaincode", code ID "%"! The new type of code can not be "plain code".', par_cf_id;
                RETURN 0; 
        END IF;

        IF type_of_code(par_cf_id) != 'plain code' THEN
                RAISE EXCEPTION 'An error occurred, in the function "make_codifier_from_plaincode", code ID "%"! The old type of code must be "plain code".', par_cf_id;
                RETURN 0; 
        END IF;
        
        IF par_reidentify THEN
                UPDATE sch_<<$app_name$>>.codes SET code_id = nextval('sch_<<$app_name$>>.codifiers_ids_seq') WHERE code_id = par_cf_id
                RETURNING code_id INTO cf_id;
        ELSE 
                cf_id:= par_cf_id;
        END IF;
        
        UPDATE sch_<<$app_name$>>.codes SET code_type = par_cf_new_type WHERE code_id = cf_id;

        RETURN cf_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION make_codifier_from_plaincode_w_values(
          par_reidentify boolean
        , par_cf_id integer
        , par_cf_new_type code_type
        , par_cf_dflt_codestr varchar
        , VARIADIC par_codes_array code_construction_input[] -- par_cf_dflt_codestr must persist in this array
        ) 
RETURNS integer AS $$
DECLARE
        cnt integer;
        cf_id integer;
BEGIN
        cf_id:= make_codifier_from_plaincode(par_reidentify, par_cf_id, VARIADIC par_cf_new_type);

        cnt:= add_subcodes_under_codifier_byid(cf_id, par_cf_dflt_codestr, VARIADIC par_codes_array);

        RETURN cf_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION codifier_default_code_byid(par_if_exists boolean, par_cf_id integer) 
RETURNS integer AS $$
DECLARE
        d integer;
        cnt integer;
BEGIN
        SELECT subcode_id INTO d
        FROM sch_<<$app_name$>>.codes_tree 
        WHERE supercode_id = par_cf_id
          AND dflt_subcode_isit;

        GET DIAGNOSTICS cnt = ROW_COUNT;

        IF cnt = 0 OR d IS NULL THEN
                IF NOT par_if_exists THEN
                        RAISE EXCEPTION 'An error occurred, when trying get a default code ID for codifier with ID: %! Default not found.', par_cf_id;
                END IF;
                RETURN NULL; 
        ELSIF cnt > 1 THEN
                RAISE EXCEPTION 'An error occurred, when trying get a default code ID for codifier with ID: %! More then one default, which is illegal.', par_cf_id;
                RETURN NULL; 
        END IF;

        RETURN d;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION codifier_default_code_bystr(par_if_exists boolean, par_cf_name varchar) 
RETURNS integer AS $$
DECLARE
        d integer;
        cnt integer;
BEGIN
        SELECT subcode_id 
        INTO d
        FROM sch_<<$app_name$>>.codes_tree AS ct, sch_<<$app_name$>>.codes AS super_c 
        WHERE super_c.code_text = par_cf_name
          AND ct.supercode_id = super_c.code_id
          AND dflt_subcode_isit;

        GET DIAGNOSTICS cnt = ROW_COUNT;

        IF cnt = 0 OR d IS NULL THEN
                IF NOT par_if_exists THEN
                        RAISE EXCEPTION 'An error occurred, when trying get a default code ID for codifier named "%"! Default not found.', par_cf_name;
                END IF;
                RETURN NULL; 
        ELSIF cnt > 1 THEN
                RAISE EXCEPTION 'An error occurred, when trying get a default code ID for codifier named "%"! More then one default, which is illegal.', par_cf_name;
                RETURN NULL; 
        END IF;

        RETURN d;
END;
$$ LANGUAGE plpgsql;

---------------------------------------

GRANT EXECUTE ON FUNCTION make_codifier_from_plaincode_w_values(
          par_reidentify boolean
        , par_cf_id integer
        , par_cf_new_type code_type
        , par_cf_dflt_codestr varchar
        , VARIADIC par_codes_array code_construction_input[] -- par_cf_dflt_codestr must persist in this array
        ) TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_codifier_from_plaincode(
          par_reidentify boolean
        , par_cf_id integer
        , par_cf_new_type code_type
        ) TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION new_codifier_w_subcodes(
          par_supercf_name varchar
        , par_cf_construct code_construction_input
        , par_cf_dflt_codestr varchar
        , VARIADIC par_codes_array code_construction_input[] -- par_cf_dflt_codestr must persist in this array
        ) TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION add_subcodes_under_codifier_bystr(
          par_cf_name varchar
        , par_cf_dflt_codestr varchar
        , VARIADIC par_codes_array code_construction_input[] -- par_cf_dflt_codestr must persist in this array
        ) TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION add_subcodes_under_codifier_byid(
          par_cf_id integer
        , par_cf_dflt_codestr varchar
        , VARIADIC par_codes_array code_construction_input[] -- par_cf_dflt_codestr must persist in this array
        ) TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION bind_code_to_codifier(par_code_id integer, par_codifier_id integer, par_dflt boolean) TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION unbind_code_from_codifier(if_exists boolean, par_code_id integer, par_codifier_id integer) TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION new_code(par_code_construct code_construction_input, par_super_code_id integer)       TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION new_codifier(par_code_construct code_construction_input, par_super_code_id integer)   TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION remove_subcodes_by_codifierid(par_c integer, par_cascade boolean, par_greedy boolean) TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION remove_codifier_w_subcodes_byid(par_c integer, par_cascade boolean, par_greedy boolean) TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION remove_codifier_bystr(if_exists boolean, par_cf varchar)                              TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION remove_code_byid(par_c integer)                                                       TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION remove_code_bystr(if_exists boolean, par_cf varchar, par_c varchar)                   TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_alldepths_subcodes_of_codifier(par_cf_id integer)                                 TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_codes_of_codifier_byid(par_codifier_id integer)                                   TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_codes_of_codifier_bystr(par_codifier_name varchar)                                TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_codifiers_of_code_byid(par_code_id integer)                                       TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION type_of_code(par_code_id integer)                                                     TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_code_by_codeid(par_code_id integer)                                               TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_nonplaincode_by_codestr(par_codifier varchar)                                     TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_codified_view_by_codestr(par_codifier varchar, par_code varchar)                  TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION codifier_default_code_byid(par_if_exists boolean, par_cf_id integer)                  TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION codifier_default_code_bystr(par_if_exists boolean, par_cf_name varchar)               TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION code_belongs_to_codifier(par_code_id integer, par_codifier_text varchar)              TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
