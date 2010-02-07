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
SELECT set_config('client_min_messages', 'NOTICE', FALSE);

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Service functions:

CREATE TYPE t_namespace_info AS (prev_search_path varchar, sp_changed boolean);

CREATE OR REPLACE FUNCTION enter_schema_namespace() RETURNS sch_<<$app_name$>>.t_namespace_info AS $$
DECLARE
        prev_search_path varchar;
        sp_changed boolean:= FALSE;
        r sch_<<$app_name$>>.t_namespace_info;
BEGIN
        SELECT current_setting('search_path') INTO prev_search_path;
        IF prev_search_path NOT LIKE 'sch_<<$app_name$>>%' THEN
                PERFORM set_config('search_path', 'sch_<<$app_name$>>,' || prev_search_path, TRUE);
                sp_changed:= TRUE;
        END IF;
        r.prev_search_path:= prev_search_path; r.sp_changed:= sp_changed;
        RETURN r;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION leave_schema_namespace(par_prev_state sch_<<$app_name$>>.t_namespace_info) RETURNS VOID AS $$
BEGIN
        IF par_prev_state.sp_changed THEN
                PERFORM set_config('search_path', par_prev_state.prev_search_path, TRUE);
        END IF;
        RETURN;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION __watch(par_str varchar) RETURNS integer AS $$
BEGIN
        RAISE WARNING '__watch: %', par_str;
        RETURN 0;
END;
$$ LANGUAGE plpgsql;


--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Referencing functions:


CREATE TYPE t_code_key                  AS (code_id integer, code_text varchar);
CREATE TYPE t_addressed_code_key        AS (codifier_key t_code_key, code_key t_code_key);
CREATE TYPE t_code_key_by_lng           AS (key_lng t_code_key,                          code_key t_code_key);
CREATE TYPE t_addressed_code_key_by_lng AS (key_lng t_code_key, codifier_key t_code_key, code_key t_code_key);

--------------------------------------------------------------------------

COMMENT ON TYPE t_code_key IS
'Field code_id alone is enough to determine identify code - this way of identification provides best (fastest) performance of code_key consumer-functions.
However, user may prefer to use a more user-friendly identification method - by code_text.
This method is not always sufficient. It is enough for identification of nonplain codes, or for identification of plain codes under *known* codifier. If codifier is unknown, then one can''t identify any plain code by code_text.
The problem of the second id method is solved in t_addressed_code_key type (see it''s comment).
Code key reading algorithm:
(1) code_id   is null? if not, terminate (identification task is solved), else -> (2)
(2) code_text is null? if not, terminate (identification task is solved (given it''s a codifier, of context codifier is known)), else -> (3)
(3) this is a NULL key.
';

COMMENT ON TYPE t_addressed_code_key IS
'Extension of t_code_key - sufficient to address (also) any plain code.
If t_addressed_code_key.code_key is NULL, then key points on whole codifier.
';

COMMENT ON TYPE t_code_key_by_lng IS
'Extended version of t_code_key - for identifying keys with possibility to use any (supported) language.
The languaged identification method is the third method and it is considered to be the slowest identification method.
Code key reading algorithm:
(1) code_key.code_id       is null? if not, terminate (identification task is solved), else -> (2)
(2) code_key.code_text     is null? if  so, terminate (this is a NULL key), else -> (3)
(3) code_key_lng.code_id   is null? if not, terminate (associate code_key.code_text with table field codes_names.name, where code_key_lng.code_id = codes_names.lng_of_name), else -> (4)
(4) code_key_lng.code_text is null? if not, terminate (associate code_key.code_text with table field codes_names.name, where codes_names.lng_of_name = code_id of code under "Language" codifier having codes.code_text = code_key_lng.code_text), else -> (5).
(5) code_key_lng is NULL, so associate code_key.code_text with table field codes.code_text
Notice: this type still supports 1st and (partially, - same as t_code_key) 2nd identification methods.
Which method will be used depends only on how user fills the fields.
';

COMMENT ON TYPE t_addressed_code_key_by_lng IS
'Extension of t_code_key_by_lng - sufficient to address (also) any plain code.
From another point of view, an extension of t_addressed_code_key - if key_lng is NULL, then t_addressed_code_key_by_lng is theated as t_addressed_code_key.
Since t_addressed_code_key_by_lng is able to simulate all simplier code_key types, it is used everywhere in the API.
';

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION make_codekey(par_code_id integer, par_code_text varchar) RETURNS t_code_key AS $$
        SELECT ROW($1, $2) :: sch_<<$app_name$>>.t_code_key;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION make_codekey_null() RETURNS t_code_key AS $$
        SELECT sch_<<$app_name$>>.make_codekey(NULL :: integer, NULL :: varchar);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION make_codekey_byid(par_code_id integer) RETURNS t_code_key AS $$
        SELECT sch_<<$app_name$>>.make_codekey($1, NULL :: varchar);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION make_codekey_bystr(par_code_text varchar) RETURNS t_code_key AS $$
        SELECT sch_<<$app_name$>>.make_codekey(NULL :: integer, $1);
$$ LANGUAGE SQL;

------------------

CREATE OR REPLACE FUNCTION make_acodekey(par_cf_key t_code_key, par_c_key t_code_key) RETURNS t_addressed_code_key AS $$
DECLARE
        r sch_<<$app_name$>>.t_addressed_code_key;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        r.codifier_key:= par_cf_key; r.code_key:= par_c_key;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN r;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION make_acodekey_null() RETURNS t_addressed_code_key AS $$
        SELECT sch_<<$app_name$>>.make_acodekey(
                        sch_<<$app_name$>>.make_codekey_null()
                      , sch_<<$app_name$>>.make_codekey_null()
                      );
$$ LANGUAGE SQL;

------------------

CREATE OR REPLACE FUNCTION make_codekeyl(par_key_lng t_code_key, par_code_key t_code_key) RETURNS t_code_key_by_lng AS $$
DECLARE
        r sch_<<$app_name$>>.t_code_key_by_lng;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        r.key_lng:= par_key_lng; r.code_key:= par_code_key;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN r;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION make_codekeyl_null() RETURNS t_code_key_by_lng AS $$
        SELECT sch_<<$app_name$>>.make_codekeyl(
                        sch_<<$app_name$>>.make_codekey_null()
                      , sch_<<$app_name$>>.make_codekey_null()
                      );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION make_codekeyl_byid(par_code_id integer) RETURNS t_code_key_by_lng AS $$
        SELECT sch_<<$app_name$>>.make_codekeyl(
                        sch_<<$app_name$>>.make_codekey_null()
                      , sch_<<$app_name$>>.make_codekey_byid($1)
                      );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION make_codekeyl_bystr(par_code_text varchar) RETURNS t_code_key_by_lng AS $$
        SELECT sch_<<$app_name$>>.make_codekeyl(
                        sch_<<$app_name$>>.make_codekey_null()
                      , sch_<<$app_name$>>.make_codekey_bystr($1)
                      );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION make_codekeyl_bystrl(par_lng_key t_code_key, par_code_text varchar) RETURNS t_code_key_by_lng AS $$
        SELECT sch_<<$app_name$>>.make_codekeyl(
                        $1
                      , sch_<<$app_name$>>.make_codekey_bystr($2)
                      );
$$ LANGUAGE SQL;

------------------

CREATE OR REPLACE FUNCTION make_acodekeyl(par_key_lng t_code_key, par_cf_key t_code_key, par_c_key t_code_key) RETURNS t_addressed_code_key_by_lng AS $$
DECLARE
        r sch_<<$app_name$>>.t_addressed_code_key_by_lng;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        r.key_lng:= par_key_lng; r.codifier_key:= par_cf_key; r.code_key:= par_c_key;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN r;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION make_acodekeyl_null() RETURNS t_addressed_code_key_by_lng AS $$
        SELECT sch_<<$app_name$>>.make_acodekeyl(
                        sch_<<$app_name$>>.make_codekey_null()
                      , sch_<<$app_name$>>.make_codekey_null()
                      , sch_<<$app_name$>>.make_codekey_null()
                      );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION make_acodekeyl_byid(par_code_id integer) RETURNS t_addressed_code_key_by_lng AS $$
        SELECT sch_<<$app_name$>>.make_acodekeyl(
                        sch_<<$app_name$>>.make_codekey_null()
                      , sch_<<$app_name$>>.make_codekey_null()
                      , sch_<<$app_name$>>.make_codekey_byid($1)
                      );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION make_acodekeyl_bystr1(par_code_text varchar) RETURNS t_addressed_code_key_by_lng AS $$
        SELECT sch_<<$app_name$>>.make_acodekeyl(
                        sch_<<$app_name$>>.make_codekey_null()
                      , sch_<<$app_name$>>.make_codekey_null()
                      , sch_<<$app_name$>>.make_codekey_bystr($1)
                      );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION make_acodekeyl_bystr2(par_codifier_text varchar, par_code_text varchar) RETURNS t_addressed_code_key_by_lng AS $$
        SELECT sch_<<$app_name$>>.make_acodekeyl(
                        sch_<<$app_name$>>.make_codekey_null()
                      , sch_<<$app_name$>>.make_codekey_bystr($1)
                      , sch_<<$app_name$>>.make_codekey_bystr($2)
                      );
$$ LANGUAGE SQL;

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION generalize_codekey(par_key t_code_key) RETURNS t_addressed_code_key_by_lng AS $$
        SELECT sch_<<$app_name$>>.make_acodekeyl(
                        sch_<<$app_name$>>.make_codekey_null()
                      , sch_<<$app_name$>>.make_codekey_null()
                      , $1
                      );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION generalize_codekeyl(par_key t_code_key_by_lng) RETURNS t_addressed_code_key_by_lng AS $$
        SELECT sch_<<$app_name$>>.make_acodekeyl(
                        ($1).key_lng
                      , sch_<<$app_name$>>.make_codekey_null()
                      , ($1).code_key
                      );
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION generalize_acodekey(par_key t_addressed_code_key) RETURNS t_addressed_code_key_by_lng AS $$
        SELECT sch_<<$app_name$>>.make_acodekeyl(
                        sch_<<$app_name$>>.make_codekey_null()
                      , ($1).codifier_key
                      , ($1).code_key
                      );
$$ LANGUAGE SQL;

--------------------------------------------------------------------------

CREATE TYPE t_code_key_type AS ENUM (
        'undef'
      , 'c_id'
      , 'c_nm (-l,-cf)'
      , 'c_nm (-l,+cf_id)'
      , 'c_nm (-l,+cf_nm)'
      , 'c_nm (+l_id,-cf)'
      , 'c_nm (+l_id,+cf_id)'
      , 'c_nm (+l_id,+cf_nm)'
      , 'c_nm (+l_nm,-cf)'
      , 'c_nm (+l_nm,+cf_id)'
      , 'c_nm (+l_nm,+cf_nm)'
      , 'cf_id'
      , 'cf_nm (-l)'
      , 'cf_nm (+l_id)'
      , 'cf_nm (+l_nm)'
      );

CREATE OR REPLACE FUNCTION codekey_type(par_key t_code_key) RETURNS t_code_key_type AS $$
DECLARE
        ct sch_<<$app_name$>>.t_code_key_type;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        IF par_key IS NULL THEN
                ct:= 'undef';
        ELSIF par_key.code_id IS NOT NULL THEN
                ct:= 'c_id';
        ELSIF par_key.code_text IS NOT NULL THEN
                ct:= 'c_nm (-l,-cf)';
        ELSE
                ct:= 'undef';
        END IF;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN ct;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION codekey_type(par_key t_code_key) IS
'May return 3 types
: "undef"
, "c_id"
, "c_nm (-l,-cf)"
.
Doesn''t return NULL.
';

CREATE OR REPLACE FUNCTION acodekey_type(par_key t_addressed_code_key) RETURNS t_code_key_type AS $$
DECLARE
        ct  sch_<<$app_name$>>.t_code_key_type;
        ct2 sch_<<$app_name$>>.t_code_key_type;
        ct3 sch_<<$app_name$>>.t_code_key_type;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        IF par_key IS NULL THEN
                ct:= 'undef' :: t_code_key_type;
        ELSE
                ct2:= codekey_type(par_key.code_key);

                IF ct2 = 'c_id' THEN
                        ct:= ct2;
                ELSIF ct2 = 'undef' THEN
                        ct3:= codekey_type(par_key.codifier_key);

                        IF ct3 = 'c_id' THEN
                                ct:= 'cf_id';
                        ELSIF ct3 = 'c_nm (-l,-cf)' THEN
                                ct:= 'cf_nm (-l)';
                        ELSIF ct3 = 'undef' THEN
                                ct:= ct2;
                        ELSE
                                RAISE EXCEPTION 'An error occurred in function "acodekey_type"! Unexpected "codekey_type(par_key.codifier_key)" output!';
                        END IF;
                ELSIF ct2 = 'c_nm (-l,-cf)' THEN
                        ct3:= codekey_type(par_key.codifier_key);

                        IF ct3 = 'c_id' THEN
                                ct:= 'c_nm (-l,+cf_id)';
                        ELSIF ct3 = 'c_nm (-l,-cf)' THEN
                                ct:= 'c_nm (-l,+cf_nm)';
                        ELSIF ct3 = 'undef' THEN
                                ct:= ct2;
                        ELSE
                                RAISE EXCEPTION 'An error occurred in function "acodekey_type"! Unexpected "codekey_type(par_key.codifier_key)" output!';
                        END IF;
                ELSE
                        RAISE EXCEPTION 'An error occurred in function "acodekey_type"! Unexpected "codekey_type(par_key.code_key)" output!';
                END IF;
        END IF;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN ct;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION acodekey_type(par_key t_addressed_code_key) IS
'May return 7 types
: "undef"
, "c_id"
, "c_nm (-l,-cf)"
, "c_nm (-l,+cf_id)"
, "c_nm (-l,+cf_nm)"
, "cf_id"
, "cf_nm (-l)"
.
Doesn''t return NULL.
';

CREATE OR REPLACE FUNCTION codekeyl_type(par_key t_code_key_by_lng) RETURNS t_code_key_type AS $$
DECLARE
        ct  sch_<<$app_name$>>.t_code_key_type;
        ct2 sch_<<$app_name$>>.t_code_key_type;
        ct3 sch_<<$app_name$>>.t_code_key_type;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();
        IF par_key IS NULL THEN
                ct:= 'undef';
        ELSE
                ct2:= codekey_type(par_key.code_key);

                IF ct2 = 'c_id' THEN
                        ct:= ct2;
                ELSIF ct2 = 'c_nm (-l,-cf)' THEN
                        ct3:= codekey_type(par_key.key_lng);

                        IF ct3 = 'c_id' THEN
                                ct:= 'c_nm (+l_id,-cf)';
                        ELSIF ct3 = 'c_nm (-l,-cf)' THEN
                                ct:= 'c_nm (+l_nm,-cf)';
                        ELSIF ct3 = 'undef' THEN
                                ct:= ct2;
                        ELSE
                                RAISE EXCEPTION 'An error occurred in function "codekeyl_type"! Unexpected "codekey_type(par_key.key_lng)" output!';
                        END IF;
                ELSIF ct2 = 'undef' THEN
                        ct:= ct2;
                ELSE
                        RAISE EXCEPTION 'An error occurred in function "codekeyl_type"! Unexpected "codekey_type(par_key.code_key)" output!';
                END IF;
        END IF;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN ct;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION codekeyl_type(par_key t_code_key_by_lng) IS
'May return 5 types
: "undef"
, "c_id"
, "c_nm (-l,-cf)"
, "c_nm (+l_id,-cf)"
, "c_nm (+l_nm,-cf)"
.
Doesn''t return NULL.
';

CREATE OR REPLACE FUNCTION acodekeyl_type(par_key t_addressed_code_key_by_lng) RETURNS t_code_key_type AS $$
DECLARE
        ct  sch_<<$app_name$>>.t_code_key_type;
        ct2 sch_<<$app_name$>>.t_code_key_type;
        ct3 sch_<<$app_name$>>.t_code_key_type;
        ct4 sch_<<$app_name$>>.t_code_key_type;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        IF par_key IS NULL THEN
                ct:= 'undef';
        ELSE
                ct2:= codekey_type(par_key.code_key);

                IF ct2 = 'c_id' THEN
                        ct:= ct2;
                ELSIF ct2 = 'undef' THEN
                        ct3:= codekey_type(par_key.codifier_key);

                        IF ct3 = 'c_id' THEN
                                ct:= 'cf_id';
                        ELSIF ct3 = 'c_nm (-l,-cf)' THEN
                                ct4:= codekey_type(par_key.key_lng);

                                IF ct4 = 'c_id' THEN
                                        ct:= 'cf_nm (+l_id)';
                                ELSIF ct4 = 'c_nm (-l,-cf)' THEN
                                        ct:= 'cf_nm (+l_nm)';
                                ELSIF ct4 = 'undef' THEN
                                        ct:= 'cf_nm (-l)';
                                ELSE
                                        RAISE EXCEPTION 'An error occurred in function "acodekeyl_type"! Unexpected "codekey_type(par_key.key_lng)" output!';
                                END IF;
                        ELSIF ct3 = 'undef' THEN
                                ct:= ct3;
                        ELSE
                                RAISE EXCEPTION 'An error occurred in function "acodekey_type"! Unexpected "codekey_type(par_key.codifier_key)" output!';
                        END IF;
                ELSIF ct2 = 'c_nm (-l,-cf)' THEN
                        ct3:= codekey_type(par_key.codifier_key);
                        ct4:= codekey_type(par_key.key_lng);

                        IF ct3 = 'c_id' THEN
                                IF ct4 = 'c_id' THEN
                                        ct:= 'c_nm (+l_id,+cf_id)';
                                ELSIF ct4 = 'c_nm (-l,-cf)' THEN
                                        ct:= 'c_nm (+l_nm,+cf_id)';
                                ELSIF ct4 = 'undef' THEN
                                        ct:= 'c_nm (-l,+cf_id)';
                                ELSE
                                        RAISE EXCEPTION 'An error occurred in function "acodekeyl_type"! Unexpected "codekey_type(par_key.key_lng)" output!';
                                END IF;
                        ELSIF ct3 = 'c_nm (-l,-cf)' THEN
                                IF ct4 = 'c_id' THEN
                                        ct:= 'c_nm (+l_id,+cf_nm)';
                                ELSIF ct4 = 'c_nm (-l,-cf)' THEN
                                        ct:= 'c_nm (+l_nm,+cf_nm)';
                                ELSIF ct4 = 'undef' THEN
                                        ct:= 'c_nm (-l,+cf_nm)';
                                ELSE
                                        RAISE EXCEPTION 'An error occurred in function "acodekeyl_type"! Unexpected "codekey_type(par_key.key_lng)" output!';
                                END IF;
                        ELSIF ct3 = 'undef' THEN
                                IF ct4 = 'c_id' THEN
                                        ct:= 'c_nm (+l_id,-cf)';
                                ELSIF ct4 = 'c_nm (-l,-cf)' THEN
                                        ct:= 'c_nm (+l_nm,-cf)';
                                ELSIF ct4 = 'undef' THEN
                                        ct:= 'c_nm (-l,-cf)';
                                ELSE
                                        RAISE EXCEPTION 'An error occurred in function "acodekeyl_type"! Unexpected "codekey_type(par_key.key_lng)" output!';
                                END IF;
                        ELSE
                                RAISE EXCEPTION 'An error occurred in function "acodekey_type"! Unexpected "codekey_type(par_key.codifier_key)" output!';
                        END IF;
                ELSE
                        RAISE EXCEPTION 'An error occurred in function "acodekey_type"! Unexpected "codekey_type(par_key.code_key)" output!';
                END IF;
        END IF;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN ct;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION acodekeyl_type(par_key t_addressed_code_key_by_lng) IS
'May return 15 types
: "undef"
, "c_id"
, "c_nm (-l,-cf)"
, "c_nm (-l,+cf_id)"
, "c_nm (-l,+cf_nm)"
, "c_nm (+l_id,-cf)"
, "c_nm (+l_id,+cf_id)"
, "c_nm (+l_id,+cf_nm)"
, "c_nm (+l_nm,-cf)"
, "c_nm (+l_nm,+cf_id)"
, "c_nm (+l_nm,+cf_nm)"
, "cf_id"
, "cf_nm (-l)"
, "cf_nm (+l_id)"
, "cf_nm (+l_nm)"
.
Doesn''t return NULL.
';

--------------------------------------------------------------------------

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION show_codekey(par_key t_code_key) RETURNS varchar AS $$
        SELECT '{t_code_key | '
            || ( CASE WHEN codekey_type($1) = 'undef' THEN 'NULL'
                      ELSE (CASE WHEN ($1).code_id   IS NULL THEN ''
                                 ELSE 'code_id: ' || ($1).code_id || ';'
                            END
                           )
                        || (CASE WHEN ($1).code_text IS NULL THEN ''
                                 ELSE 'code_text: "' || ($1).code_text || '";'
                            END
                           )
                        || (CASE WHEN (($1).code_id IS NULL) AND (($1).code_text IS NULL) THEN 'NULL'
                                 ELSE ''
                            END
                           )
                      END
               )
            || '}';
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION show_acodekey(par_key t_addressed_code_key) RETURNS varchar AS $$
        SELECT '{t_addressed_code_key | '
            || ( CASE WHEN acodekey_type($1) = 'undef' THEN 'NULL'
                      ELSE (CASE WHEN codekey_type(($1).codifier_key) = 'undef'  THEN ''
                                 ELSE 'codifier_key: ' || sch_<<$app_name$>>.show_codekey(($1).codifier_key) || ';'
                            END
                           )
                        || (CASE WHEN codekey_type(($1).code_key)     = 'undef'  THEN ''
                                 ELSE 'code_key: ' || sch_<<$app_name$>>.show_codekey(($1).code_key) || ';'
                            END
                           )
                        || (CASE WHEN (codekey_type(($1).code_key)     = 'undef')
                                  AND (codekey_type(($1).codifier_key) = 'undef') THEN 'NULL'
                                 ELSE ''
                            END
                           )
                      END
               )
            || '}';
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION show_codekeyl(par_key t_code_key_by_lng) RETURNS varchar AS $$
        SELECT '{t_code_key_by_lng | '
            || ( CASE WHEN $1 IS NULL THEN 'NULL'
                      ELSE (CASE WHEN codekey_type(($1).key_lng)  = 'undef' THEN ''
                                 ELSE 'key_lng: ' || sch_<<$app_name$>>.show_codekey(($1).key_lng) || ';'
                            END
                           )
                        || (CASE WHEN codekey_type(($1).code_key) = 'undef' THEN ''
                                 ELSE 'code_key: ' || sch_<<$app_name$>>.show_codekey(($1).code_key) || ';'
                            END
                           )
                        || (CASE WHEN (codekey_type(($1).key_lng) = 'undef') AND (codekey_type(($1).code_key) = 'undef') THEN 'NULL'
                                 ELSE ''
                            END
                           )
                      END
               )
            || '}';
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION show_acodekeyl(par_key t_addressed_code_key_by_lng) RETURNS varchar AS $$
        SELECT '{t_addressed_code_key_by_lng | '
            || ( CASE WHEN $1 IS NULL THEN 'NULL'
                      ELSE (CASE WHEN codekey_type(($1).key_lng)      = 'undef' THEN ''
                                 ELSE 'key_lng: ' || sch_<<$app_name$>>.show_codekey(($1).key_lng) || ';'
                            END
                           )
                        || (CASE WHEN codekey_type(($1).codifier_key) = 'undef' THEN ''
                                 ELSE 'codifier_key: ' || sch_<<$app_name$>>.show_codekey(($1).codifier_key) || ';'
                            END
                           )
                        || (CASE WHEN codekey_type(($1).code_key)     = 'undef' THEN ''
                                 ELSE 'code_key: ' || sch_<<$app_name$>>.show_codekey(($1).code_key) || ';'
                            END
                           )
                        || (CASE WHEN (codekey_type(($1).key_lng)      = 'undef')
                                  AND (codekey_type(($1).code_key)     = 'undef')
                                  AND (codekey_type(($1).codifier_key) = 'undef') THEN 'NULL'
                                 ELSE ''
                            END
                           )
                      END
               )
            || '}';
$$ LANGUAGE SQL;

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Lookup functions:

CREATE OR REPLACE FUNCTION code_id_of(par_if_exists boolean, par_acodekeyl t_addressed_code_key_by_lng) RETURNS integer AS $$
DECLARE
        c_id integer:= NULL;
        srch_prfd boolean;
        cnt integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        -- RAISE WARNING '%', show_acodekeyl(par_acodekeyl);

        srch_prfd:= FALSE;
        cnt:= 0;
        CASE acodekeyl_type(par_acodekeyl)
            WHEN 'undef', 'cf_id', 'cf_nm (-l)', 'cf_nm (+l_id)', 'cf_nm (+l_nm)' THEN
                srch_prfd:= FALSE;
                c_id:= NULL;
                cnt:= 0;
            WHEN 'c_id' THEN
                IF par_if_exists THEN
                        srch_prfd:= FALSE;
                        c_id:= ((par_acodekeyl).code_key).code_id;
                        cnt:= 1;
                ELSE
                        srch_prfd:= TRUE;
                        SELECT code_id
                        INTO c_id
                        FROM sch_<<$app_name$>>.codes
                        WHERE code_id = ((par_acodekeyl).code_key).code_id;
                END IF;
            WHEN 'c_nm (-l,-cf)' THEN
                srch_prfd:= TRUE;

                SELECT c.code_id
                INTO c_id
                FROM sch_<<$app_name$>>.codes AS c
                WHERE c.code_type != 'plain code'
                  AND c.code_text  = ((par_acodekeyl).code_key).code_text;
            WHEN 'c_nm (+l_id,-cf)' THEN
                srch_prfd:= TRUE;

                SELECT c.code_id
                INTO c_id
                FROM sch_<<$app_name$>>.codes       AS c
                   , sch_<<$app_name$>>.codes_names AS cn
                WHERE c.code_type   != 'plain code'
                  AND c.code_id      = cn.code_id
                  AND cn.name        = ((par_acodekeyl).code_key).code_text
                  AND cn.lng_of_name = ((par_acodekeyl).key_lng).code_id;
            WHEN 'c_nm (+l_nm,-cf)' THEN
                srch_prfd:= TRUE;

                SELECT c.code_id
                INTO c_id
                FROM sch_<<$app_name$>>.codes       AS c
                   , sch_<<$app_name$>>.codes_names AS cn
                   , sch_<<$app_name$>>.codes       AS c_lng
                   , sch_<<$app_name$>>.codes       AS c_lng_cf
                   , sch_<<$app_name$>>.codes_tree  AS c_lng_ct
                WHERE c.code_type        != 'plain code'
                  AND c.code_id           = cn.code_id
                  AND cn.name             = ((par_acodekeyl).code_key).code_text
                  AND cn.lng_of_name      = c_lng.code_id
                  AND c_lng.code_text     = ((par_acodekeyl).key_lng).code_text
                  AND c_lng_ct.subcode_id = c_lng.code_id
                  AND c_lng_ct.supercode_id = c_lng_cf.code_id
                  AND c_lng_cf.code_text  = 'Languages';
            WHEN 'c_nm (-l,+cf_id)' THEN
                srch_prfd:= TRUE;

                SELECT c.code_id
                INTO c_id
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes       AS c
                WHERE ct.supercode_id  = ((par_acodekeyl).codifier_key).code_id
                  AND ct.subcode_id    = c.code_id
                  AND c.code_text      = ((par_acodekeyl).code_key).code_text;
            WHEN 'c_nm (-l,+cf_nm)' THEN
                srch_prfd:= TRUE;

                SELECT c.code_id
                INTO c_id
                FROM sch_<<$app_name$>>.codes_tree AS ct
                   , sch_<<$app_name$>>.codes      AS cf
                   , sch_<<$app_name$>>.codes      AS c
                WHERE ct.supercode_id = cf.code_id
                  AND ct.subcode_id   = c.code_id
                  AND cf.code_text    = ((par_acodekeyl).codifier_key).code_text
                  AND c.code_text     = ((par_acodekeyl).code_key).code_text;
            WHEN 'c_nm (+l_id,+cf_id)' THEN
                srch_prfd:= TRUE;

                SELECT c_n.code_id
                INTO c_id
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes_names AS c_n
                WHERE ct.supercode_id  = ((par_acodekeyl).codifier_key).code_id
                  AND ct.subcode_id    = c_n.code_id
                  AND c_n.lng_of_name  = ((par_acodekeyl).key_lng).code_id
                  AND c_n.name         = ((par_acodekeyl).code_key).code_text;
            WHEN 'c_nm (+l_id,+cf_nm)' THEN
                srch_prfd:= TRUE;

                SELECT c_n.code_id
                INTO c_id
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes_names AS cf_n
                   , sch_<<$app_name$>>.codes_names AS c_n
                WHERE ct.supercode_id  = cf_n.code_id
                  AND ct.subcode_id    = c_n.code_id
                  AND cf_n.lng_of_name = ((par_acodekeyl).key_lng).code_id
                  AND c_n.lng_of_name  = ((par_acodekeyl).key_lng).code_id
                  AND cf_n.name        = ((par_acodekeyl).codifier_key).code_text
                  AND c_n.name         = ((par_acodekeyl).code_key).code_text;
            WHEN 'c_nm (+l_nm,+cf_id)' THEN
                srch_prfd:= TRUE;

                SELECT c_n.code_id
                INTO c_id
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes_names AS c_n
                   , sch_<<$app_name$>>.codes       AS c_lng
                   , sch_<<$app_name$>>.codes       AS c_lng_cf
                   , sch_<<$app_name$>>.codes_tree  AS c_lng_ct
                WHERE ct.supercode_id  = ((par_acodekeyl).codifier_key).code_id
                  AND ct.subcode_id    = c_n.code_id
                  AND c_n.lng_of_name  = c_lng.code_id
                  AND c_lng.code_text  = ((par_acodekeyl).key_lng).code_text
                  AND c_n.name         = ((par_acodekeyl).code_key).code_text
                  AND c_lng_ct.subcode_id = c_lng.code_id
                  AND c_lng_ct.supercode_id = c_lng_cf.code_id
                  AND c_lng_cf.code_text  = 'Languages';
            WHEN 'c_nm (+l_nm,+cf_nm)' THEN
                srch_prfd:= TRUE;

                SELECT c_n.code_id
                INTO c_id
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes_names AS cf_n
                   , sch_<<$app_name$>>.codes_names AS c_n
                   , sch_<<$app_name$>>.codes       AS c_lng
                   , sch_<<$app_name$>>.codes       AS c_lng_cf
                   , sch_<<$app_name$>>.codes_tree  AS c_lng_ct
                WHERE ct.supercode_id  = cf_n.code_id
                  AND ct.subcode_id    = c_n.code_id
                  AND cf_n.lng_of_name = c_lng.code_id
                  AND c_n.lng_of_name  = c_lng.code_id
                  AND c_lng.code_text  = ((par_acodekeyl).key_lng).code_text
                  AND cf_n.name        = ((par_acodekeyl).codifier_key).code_text
                  AND c_n.name         = ((par_acodekeyl).code_key).code_text
                  AND c_lng_ct.subcode_id = c_lng.code_id
                  AND c_lng_ct.supercode_id = c_lng_cf.code_id
                  AND c_lng_cf.code_text  = 'Languages';
            ELSE
                RAISE EXCEPTION 'An error occurred in function "code_id_of"! Unexpected "acodekeyl_type(par_acodekeyl)" output for code key: %!', show_acodekeyl(par_acodekeyl);
        END CASE;

        IF srch_prfd THEN
                GET DIAGNOSTICS cnt = ROW_COUNT;
        END IF;

        IF c_id IS NULL AND NOT par_if_exists THEN
                RAISE EXCEPTION 'An error occurred in function "code_id_of"! Can not find code: %!', show_acodekeyl(par_acodekeyl);
        END IF;

        IF cnt > 1 THEN
                RAISE EXCEPTION 'An error occurred in function "code_id_of" for code %! More then one code is identified by given code_key, which should never happen!', show_acodekeyl(par_acodekeyl);
        END IF;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN c_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION code_id_of(par_if_exists boolean, par_acodekeyl t_addressed_code_key_by_lng) IS
'For keys of type "undef" and "cf_*" NULL is returned.
For keys of type "c_nm (*,-cf)" sometimes NULL might be returned - when there is no *nonplain* code with specified name. Plain codes are assumed to be nonidentifiable by keys of type "c_nm (*,-cf)".
If key not found NULL is to be returned.
For cases when NULL is to be returned: if "par_if_exists" parameter is FALSE, then an EXCEPTION gets rised (instead of returning NULL).
';

CREATE OR REPLACE FUNCTION code_id_of_undefined() RETURNS integer AS $$
        SELECT sch_<<$app_name$>>.code_id_of(FALSE, sch_<<$app_name$>>.make_acodekeyl_bystr2('Common nominal codes set', 'undefined'));
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION code_id_of_unclassified() RETURNS integer AS $$
        SELECT sch_<<$app_name$>>.code_id_of(FALSE, sch_<<$app_name$>>.make_acodekeyl_bystr2('Common nominal codes set', 'unclassified'));
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION code_id_of_error() RETURNS integer AS $$
        SELECT sch_<<$app_name$>>.code_id_of(FALSE, sch_<<$app_name$>>.make_acodekeyl_bystr2('Common nominal codes set', 'error'));
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION code_id_of_ambiguous() RETURNS integer AS $$
        SELECT sch_<<$app_name$>>.code_id_of(FALSE, sch_<<$app_name$>>.make_acodekeyl_bystr2('Common nominal codes set', 'ambiguous'));
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION code_id_of_language(lng_code_text varchar) RETURNS integer AS $$
        SELECT sch_<<$app_name$>>.code_id_of(FALSE, sch_<<$app_name$>>.make_acodekeyl_bystr2('Languages', $1));
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION code_id_of_entity(entity_code_text varchar) RETURNS integer AS $$
        SELECT sch_<<$app_name$>>.code_id_of(FALSE, sch_<<$app_name$>>.make_acodekeyl_bystr2('Entities', $1));
$$ LANGUAGE SQL;

COMMENT ON FUNCTION code_id_of_undefined()       IS 'code_id_of(FALSE, make_acodekeyl_bystr2(''Common nominal codes set'', ''undefined''))';
COMMENT ON FUNCTION code_id_of_unclassified()    IS 'code_id_of(FALSE, make_acodekeyl_bystr2(''Common nominal codes set'', ''unclassified''))';
COMMENT ON FUNCTION code_id_of_error()           IS 'code_id_of(FALSE, make_acodekeyl_bystr2(''Common nominal codes set'', ''error''))';
COMMENT ON FUNCTION code_id_of_ambiguous()       IS 'code_id_of(FALSE, make_acodekeyl_bystr2(''Common nominal codes set'', ''ambiguous''))';
COMMENT ON FUNCTION code_id_of_language(varchar) IS 'code_id_of(FALSE, make_acodekeyl_bystr2(''Languages'', $1))';
COMMENT ON FUNCTION code_id_of_entity(varchar) IS 'code_id_of(FALSE, make_acodekeyl_bystr2(''Entities'', $1))';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION codifier_default_code(par_if_exists boolean, par_cf_keyl t_code_key_by_lng)
RETURNS integer AS $$
DECLARE
        d integer:= NULL;
        cnt integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        CASE codekeyl_type(par_cf_keyl)
            WHEN 'undef' THEN
                IF NOT par_if_exists THEN
                        RAISE EXCEPTION 'An error occurred, when trying get a default code ID for codifier %! Key must be defined.', show_codekeyl(par_cf_keyl);
                END IF;

                PERFORM leave_schema_namespace(namespace_info);
                RETURN NULL;
            WHEN 'c_id' THEN
                SELECT subcode_id INTO d
                FROM sch_<<$app_name$>>.codes_tree
                WHERE supercode_id = ((par_cf_keyl).code_key).code_id
                  AND dflt_subcode_isit;
            WHEN 'c_nm (-l,-cf)' THEN
                SELECT ct.subcode_id INTO d
                FROM sch_<<$app_name$>>.codes_tree AS ct
                   , sch_<<$app_name$>>.codes      AS c
                WHERE ct.supercode_id = c.code_id
                  AND c.code_text     = ((par_cf_keyl).code_key).code_text
                  AND ct.dflt_subcode_isit;
            WHEN 'c_nm (+l_id,-cf)' THEN
                SELECT ct.subcode_id INTO d
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes_names AS cn
                WHERE ct.supercode_id = cn.code_id
                  AND cn.name          = ((par_cf_keyl).code_key).code_text
                  AND cn.lng_of_name   = ((par_cf_keyl).key_lng).code_id
                  AND ct.dflt_subcode_isit;
            WHEN 'c_nm (+l_nm,-cf)' THEN
                SELECT ct.subcode_id INTO d
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes_names AS cn
                   , sch_<<$app_name$>>.codes       AS c_lng
                   , sch_<<$app_name$>>.codes       AS c_lng_cf
                   , sch_<<$app_name$>>.codes_tree  AS c_lng_ct
                WHERE ct.supercode_id = cn.code_id
                  AND cn.name          = ((par_cf_keyl).code_key).code_text
                  AND cn.lng_of_name   = c_lng.code_id
                  AND c_lng.code_text = ((par_cf_keyl).key_lng).code_text
                  AND c_lng_ct.subcode_id = c_lng.code_id
                  AND c_lng_ct.supercode_id = c_lng_cf.code_id
                  AND c_lng_cf.code_text  = 'Languages'
                  AND ct.dflt_subcode_isit;
            ELSE
                RAISE EXCEPTION 'An error occurred in function "codifier_default_code"! Unexpected "codekeyl_type(par_cf_keyl)" output for code key: %!', show_codekeyl(par_cf_keyl);
        END CASE;

        GET DIAGNOSTICS cnt = ROW_COUNT;

        IF cnt = 0 OR d IS NULL THEN
                IF NOT par_if_exists THEN
                        RAISE EXCEPTION 'An error occurred, when trying get a default code ID for codifier: %! Default not found.', show_codekeyl(par_cf_keyl);
                END IF;
                PERFORM leave_schema_namespace(namespace_info);
                RETURN NULL;
        ELSIF cnt > 1 THEN
                RAISE EXCEPTION 'An error occurred, when trying get a default code ID for codifier: %! More then one default, which is illegal.', show_codekeyl(par_cf_keyl);
        END IF;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN d;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION codifier_default_code(par_if_exists boolean, par_cf_key t_code_key_by_lng) IS
'For keys of type "undef" NULL is returned. It will also return NULL, if default is not found.
If first parameter is FALSE, then all cases, when NULL is to be returned, an EXCEPTION gets rised instead.
';
-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_code(par_if_exists boolean, par_key t_addressed_code_key_by_lng) RETURNS sch_<<$app_name$>>.codes AS $$
DECLARE
        ccc sch_<<$app_name$>>.codes%ROWTYPE;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        SELECT c.*
        INTO ccc
        FROM sch_<<$app_name$>>.codes AS c
        WHERE c.code_id = code_id_of(par_if_exists, par_key);

        PERFORM leave_schema_namespace(namespace_info);
        RETURN ccc;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_code(par_if_exists boolean, par_acodekeyl t_addressed_code_key_by_lng) IS
'Wrapper around code_id_of(...).';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION code_belongs_to_codifier(par_if_cf_exists boolean, par_acodekeyl t_addressed_code_key_by_lng) RETURNS boolean AS $$
DECLARE
        e boolean:= NULL;
        srchd boolean:= FALSE;
	cnt integer;
        __const_nom_cf_name CONSTANT varchar := 'Common nominal codes set';
        __const_undef_c_name CONSTANT varchar:= 'undefined';
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        -- RAISE WARNING '%', show_acodekeyl(par_acodekeyl);

        CASE acodekeyl_type(par_acodekeyl)
            WHEN 'undef' THEN
                e:= NULL;
            WHEN 'cf_id' THEN
                srchd:= TRUE;

                SELECT TRUE
                INTO e
                FROM sch_<<$app_name$>>.codes_tree AS ct
                   , sch_<<$app_name$>>.codes_tree AS ct_nom
                   , sch_<<$app_name$>>.codes      AS c_undef
                   , sch_<<$app_name$>>.codes      AS c_nom
                WHERE ct.supercode_id     = ((par_acodekeyl).codifier_key).code_id
                  AND ct.subcode_id       = c_undef.code_id
                  AND ct_nom.supercode_id = c_nom.code_id
                  AND ct_nom.subcode_id   = c_undef.code_id
                  AND c_nom.code_text     = __const_nom_cf_name
                  AND c_undef.code_text   = __const_undef_c_name;
            WHEN 'cf_nm (-l)' THEN
                srchd:= TRUE;

                SELECT TRUE
                INTO e
                FROM sch_<<$app_name$>>.codes_tree AS ct
                   , sch_<<$app_name$>>.codes      AS cf
                   , sch_<<$app_name$>>.codes_tree AS ct_nom
                   , sch_<<$app_name$>>.codes      AS c_undef
                   , sch_<<$app_name$>>.codes      AS c_nom
                WHERE ct.supercode_id     = cf.code_id
                  AND cf.code_text        = ((par_acodekeyl).codifier_key).code_text
                  AND ct.subcode_id       = c_undef.code_id
                  AND ct_nom.supercode_id = c_nom.code_id
                  AND ct_nom.subcode_id   = c_undef.code_id
                  AND c_nom.code_text     = __const_nom_cf_name
                  AND c_undef.code_text   = __const_undef_c_name;
            WHEN 'cf_nm (+l_id)' THEN
                srchd:= TRUE;

                SELECT TRUE
                INTO e
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes_names AS cf_nm
                   , sch_<<$app_name$>>.codes_tree  AS ct_nom
                   , sch_<<$app_name$>>.codes       AS c_undef
                   , sch_<<$app_name$>>.codes       AS c_nom
                WHERE ct.supercode_id     = cf_nm.code_id
                  AND cf_nm.name          = ((par_acodekeyl).codifier_key).code_text
                  AND cf_nm.lng_of_name   = ((par_acodekeyl).key_lng).code_id
                  AND ct.subcode_id       = c_undef.code_id
                  AND ct_nom.supercode_id = c_nom.code_id
                  AND ct_nom.subcode_id   = c_undef.code_id
                  AND c_nom.code_text     = __const_nom_cf_name
                  AND c_undef.code_text   = __const_undef_c_name;
            WHEN 'cf_nm (+l_nm)' THEN
                srchd:= TRUE;

                SELECT TRUE
                INTO e
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes_names AS cf_nm
                   , sch_<<$app_name$>>.codes       AS c_lng
                   , sch_<<$app_name$>>.codes       AS c_lng_cf
                   , sch_<<$app_name$>>.codes_tree  AS c_lng_ct
                   , sch_<<$app_name$>>.codes_tree  AS ct_nom
                   , sch_<<$app_name$>>.codes       AS c_undef
                   , sch_<<$app_name$>>.codes       AS c_nom
                WHERE ct.supercode_id     = cf_nm.code_id
                  AND cf_nm.name          = ((par_acodekeyl).codifier_key).code_text
                  AND cf_nm.lng_of_name   = c_lng.code_id
                  AND c_lng_ct.subcode_id = c_lng.code_id
                  AND c_lng_ct.supercode_id = c_lng_cf.code_id
                  AND c_lng_cf.code_text  = 'Languages'
                  AND c_lng.code_text     = ((par_acodekeyl).key_lng).code_text
                  AND ct.subcode_id       = c_undef.code_id
                  AND ct_nom.supercode_id = c_nom.code_id
                  AND ct_nom.subcode_id   = c_undef.code_id
                  AND c_nom.code_text     = __const_nom_cf_name
                  AND c_undef.code_text   = __const_undef_c_name;
            WHEN 'c_id' THEN
                CASE codekeyl_type(make_codekeyl(par_acodekeyl.key_lng, par_acodekeyl.codifier_key))
                    WHEN 'c_id' THEN
                        srchd:= TRUE;

                        SELECT TRUE
                        INTO e
                        FROM sch_<<$app_name$>>.codes_tree AS ct
                        WHERE ct.supercode_id = ((par_acodekeyl).codifier_key).code_id
                          AND ct.subcode_id   = ((par_acodekeyl).code_key).code_id;
                    WHEN 'c_nm (-l,-cf)' THEN
                        srchd:= TRUE;

                        SELECT TRUE
                        INTO e
                        FROM sch_<<$app_name$>>.codes_tree AS ct
                           , sch_<<$app_name$>>.codes      AS cf
                        WHERE ct.supercode_id = cf.code_id
                          AND ct.subcode_id   = ((par_acodekeyl).code_key).code_id
                          AND cf.code_text    = ((par_acodekeyl).codifier_key).code_text;
                    WHEN 'c_nm (+l_id,-cf)' THEN
                        srchd:= TRUE;

                        SELECT TRUE
                        INTO e
                        FROM sch_<<$app_name$>>.codes_tree  AS ct
                           , sch_<<$app_name$>>.codes_names AS cf_n
                        WHERE ct.supercode_id  = cf_n.code_id
                          AND ct.subcode_id    = ((par_acodekeyl).code_key).code_id
                          AND cf_n.name        = ((par_acodekeyl).codifier_key).code_text
                          AND cf_n.lng_of_name = ((par_acodekeyl).key_lng).code_id;
                    WHEN 'c_nm (+l_nm,-cf)' THEN
                        srchd:= TRUE;

                        SELECT TRUE
                        INTO e
                        FROM sch_<<$app_name$>>.codes_tree  AS ct
                           , sch_<<$app_name$>>.codes_names AS cf_n
                           , sch_<<$app_name$>>.codes       AS c_lng
                           , sch_<<$app_name$>>.codes       AS c_lng_cf
                           , sch_<<$app_name$>>.codes_tree  AS c_lng_ct
                        WHERE ct.supercode_id     = cf_n.code_id
                          AND ct.subcode_id       = ((par_acodekeyl).code_key).code_id
                          AND cf_n.name           = ((par_acodekeyl).codifier_key).code_text
                          AND cf_n.lng_of_name    = c_lng.code_id
                          AND c_lng.code_text     = ((par_acodekeyl).key_lng).code_text
                          AND c_lng_ct.subcode_id = c_lng.code_id
                          AND c_lng_ct.supercode_id = c_lng_cf.code_id
                          AND c_lng_cf.code_text  = 'Languages';
                    WHEN 'undef' THEN
                        e:= NULL;
                    ELSE
                        RAISE EXCEPTION 'An error occurred in function "code_belongs_to_codifier"! Unexpected "codekeyl_type(make_codekeyl(par_acodekeyl.key_lng, par_acodekeyl.codifier_key))" output for code key: %!', show_acodekeyl(par_acodekeyl);
                END CASE;
            WHEN 'c_nm (-l,-cf)' THEN
                e:= NULL;
            WHEN 'c_nm (-l,+cf_id)' THEN
                srchd:= TRUE;

                SELECT TRUE
                INTO e
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes       AS c
                WHERE ct.supercode_id  = ((par_acodekeyl).codifier_key).code_id
                  AND ct.subcode_id    = c.code_id
                  AND c.code_text      = ((par_acodekeyl).code_key).code_text;
            WHEN 'c_nm (-l,+cf_nm)' THEN
                srchd:= TRUE;

                SELECT TRUE
                INTO e
                FROM sch_<<$app_name$>>.codes_tree AS ct
                   , sch_<<$app_name$>>.codes      AS cf
                   , sch_<<$app_name$>>.codes      AS c
                WHERE ct.supercode_id = cf.code_id
                  AND ct.subcode_id   = c.code_id
                  AND cf.code_text    = ((par_acodekeyl).codifier_key).code_text
                  AND c.code_text     = ((par_acodekeyl).code_key).code_text;
            WHEN 'c_nm (+l_id,-cf)' THEN
                e:= NULL;
            WHEN 'c_nm (+l_id,+cf_id)' THEN
                srchd:= TRUE;

                SELECT TRUE
                INTO e
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes_names AS c_n
                WHERE ct.supercode_id  = ((par_acodekeyl).codifier_key).code_id
                  AND ct.subcode_id    = c_n.code_id
                  AND c_n.lng_of_name  = ((par_acodekeyl).key_lng).code_id
                  AND c_n.name         = ((par_acodekeyl).code_key).code_text;
            WHEN 'c_nm (+l_id,+cf_nm)' THEN
                srchd:= TRUE;

                SELECT TRUE
                INTO e
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes_names AS cf_n
                   , sch_<<$app_name$>>.codes_names AS c_n
                WHERE ct.supercode_id  = cf_n.code_id
                  AND ct.subcode_id    = c_n.code_id
                  AND cf_n.lng_of_name = ((par_acodekeyl).key_lng).code_id
                  AND c_n.lng_of_name  = ((par_acodekeyl).key_lng).code_id
                  AND cf_n.name        = ((par_acodekeyl).codifier_key).code_text
                  AND c_n.name         = ((par_acodekeyl).code_key).code_text;
            WHEN 'c_nm (+l_nm,-cf)' THEN
                e:= NULL;
            WHEN 'c_nm (+l_nm,+cf_id)' THEN
                srchd:= TRUE;

                SELECT TRUE
                INTO e
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes_names AS c_n
                   , sch_<<$app_name$>>.codes       AS c_lng
                   , sch_<<$app_name$>>.codes       AS c_lng_cf
                   , sch_<<$app_name$>>.codes_tree  AS c_lng_ct
                WHERE ct.supercode_id  = ((par_acodekeyl).codifier_key).code_id
                  AND ct.subcode_id    = c_n.code_id
                  AND c_n.lng_of_name  = c_lng.code_id
                  AND c_lng.code_text  = ((par_acodekeyl).key_lng).code_text
                  AND c_n.name         = ((par_acodekeyl).code_key).code_text
                  AND c_lng_ct.subcode_id = c_lng.code_id
                  AND c_lng_ct.supercode_id = c_lng_cf.code_id
                  AND c_lng_cf.code_text  = 'Languages';
            WHEN 'c_nm (+l_nm,+cf_nm)' THEN
                srchd:= TRUE;

                SELECT TRUE
                INTO e
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes_names AS cf_n
                   , sch_<<$app_name$>>.codes_names AS c_n
                   , sch_<<$app_name$>>.codes       AS c_lng
                   , sch_<<$app_name$>>.codes       AS c_lng_cf
                   , sch_<<$app_name$>>.codes_tree  AS c_lng_ct
                WHERE ct.supercode_id  = cf_n.code_id
                  AND ct.subcode_id    = c_n.code_id
                  AND cf_n.lng_of_name = c_lng.code_id
                  AND c_n.lng_of_name  = c_lng.code_id
                  AND c_lng.code_text  = ((par_acodekeyl).key_lng).code_text
                  AND cf_n.name        = ((par_acodekeyl).codifier_key).code_text
                  AND c_n.name         = ((par_acodekeyl).code_key).code_text
                  AND c_lng_ct.subcode_id = c_lng.code_id
                  AND c_lng_ct.supercode_id = c_lng_cf.code_id
                  AND c_lng_cf.code_text  = 'Languages';

            ELSE
                RAISE EXCEPTION 'An error occurred in function "code_belongs_to_codifier"! Unexpected "acodekeyl_type(par_acodekeyl)" output for code key: %!', show_acodekeyl(par_acodekeyl);
        END CASE;

        cnt:= 0;
        IF srchd THEN
                GET DIAGNOSTICS cnt = ROW_COUNT;
                IF cnt = 0 THEN
                        IF NOT par_if_cf_exists THEN
                                PERFORM get_code(FALSE, make_acodekeyl((par_acodekeyl).key_lng, make_codekey_null(), (par_acodekeyl).codifier_key));
                        END IF;
                        PERFORM leave_schema_namespace(namespace_info);
                        RETURN FALSE;
                ELSIF cnt > 1 THEN
                        RAISE EXCEPTION 'Data inconsistecy error detected, when trying to check, if code belongs to codifier in code key %! Multiple belongings are found, but only one must have been.', show_acodekeyl(par_acodekeyl);
                ELSE
                        PERFORM leave_schema_namespace(namespace_info);
                        RETURN TRUE;
                END IF;
        ELSE
                RAISE EXCEPTION 'An error detected, when trying to check, if code belongs to codifier in code key %! Codifier not specified.', show_acodekeyl(par_acodekeyl);
        END IF;
        PERFORM leave_schema_namespace(namespace_info);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION code_belongs_to_codifier(par_if_cf_exists boolean, par_acodekeyl t_addressed_code_key_by_lng) IS
'Keys of type patterned by "cf_*" are treated to check, if codifier allows code {"Common nominal codes set"."undefined"}.
For keys of type patterned by "c_nm (*,-cf)" NULL is returned.
For keys of type "undef" NULL is returned.
For keys of type "c_id", if codifier is NULL, then NULL is returned.

If "par_if_cf_exists" parameter is FALSE,
        then for cases of resulting FALSE an additional check is performed - if specified codifier exists. If it doesn''t (exist), then an EXCEPTION is raised.
       ; and for cases of resulting FALSE then an EXCEPTION is raised.

This function generally is aimed for following 2 uses:

(1) Fast:
CREATE TABLE my_table (
        ...
        my_codified_field integer [[NOT] NULL]
        ...
      , FOREIGN KEY (my_codified_field) REFERENCES codes(code_id) ON DELETE RESTRICT ON UPDATE CASCADE
      , CONSTRAINT value_in_my_codified_field_must_be_in_my_codifier
                CHECK ( code_belongs_to_codifier(
                                FALSE
                              , make_acodekeyl(
                                          make_codekey_null()
                                        , make_codekey_bystr(''name_of_my_codifier'')
                                        , make_codekey_byid(my_codified_field)
                      )         )       )
);

(2) Slower and less optimal (no foreign keying), but user-friendlier:
CREATE TABLE my_table (
        ...
        my_codified_field varchar [[NOT] NULL]
        ...
      , CONSTRAINT value_in_my_codified_field_must_be_in_my_codifier
                CHECK ( code_belongs_to_codifier(
                                FALSE
                              , make_acodekeyl(
                                          make_codekey_null()
                                        , make_codekey_bystr(''name_of_my_codifier'')
                                        , make_codekey_bystr(my_codified_field)
                      )         )       )
);

--------------
WARNING!!! For PostgreSQL =< v8.4
If you put it TRUE in "par_if_cf_exists" parameter (code_belongs_to_codifier(TRUE, ...)),
then it won''t be good for using in a CHECK CONSTRAINT.
Because if it returns NULL (in cases, when codifier is not specified, which is an errornous situation),
the the behaviour of CHECK CONSTRAINT is same as it returned TRUE.
--------------
';

-------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_codes_l(par_key t_code_key_by_lng) RETURNS SETOF sch_<<$app_name$>>.codes AS $$
DECLARE
        ccc sch_<<$app_name$>>.codes%ROWTYPE;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        CASE codekeyl_type(par_key)
            WHEN 'c_id' THEN
                RETURN QUERY
                        SELECT c.*
                        FROM sch_<<$app_name$>>.codes AS c
                        WHERE c.code_id = ((par_key).code_key).code_id;
            WHEN 'c_nm (-l,-cf)' THEN
                RETURN QUERY
                        SELECT c.*
                        FROM sch_<<$app_name$>>.codes AS c
                        WHERE c.code_text = ((par_key).code_key).code_text;
            WHEN 'c_nm (+l_id,-cf)' THEN
                RETURN QUERY
                        SELECT c.*
                        FROM sch_<<$app_name$>>.codes       AS c
                           , sch_<<$app_name$>>.codes_names AS cn
                        WHERE c.code_id      = cn.code_id
                          AND cn.name        = ((par_key).code_key).code_text
                          AND cn.lng_of_name = ((par_key).key_lng).code_id;
            WHEN 'c_nm (+l_nm,-cf)' THEN
                RETURN QUERY
                        SELECT c.*
                        FROM sch_<<$app_name$>>.codes       AS c
                           , sch_<<$app_name$>>.codes_names AS cn
                           , sch_<<$app_name$>>.codes       AS c_lng
                           , sch_<<$app_name$>>.codes       AS c_lng_cf
                           , sch_<<$app_name$>>.codes_tree  AS c_lng_ct
                        WHERE c.code_id           = cn.code_id
                          AND cn.name             = ((par_key).code_key).code_text
                          AND cn.lng_of_name      = c_lng.code_id
                          AND c_lng.code_text     = ((par_key).key_lng).code_text
                          AND c_lng_ct.subcode_id = c_lng.code_id
                          AND c_lng_ct.supercode_id = c_lng_cf.code_id
                          AND c_lng_cf.code_text  = 'Languages';
            WHEN 'undef' THEN
            ELSE
                RAISE EXCEPTION 'An error occurred in function "get_codes_l"! Unexpected "codekeyl_type(par_key)" output for code key: %!', show_codekeyl(par_key);
        END CASE;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_codes_l(par_key t_code_key_by_lng) IS
'Tolerant version of "get_code(...)".
It doesn''t use "code_id_of(...)", and makes it possible to query for a set of codes (!plain or not!), that satisfy key condition.';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_nonplaincode_by_str(par_codifier varchar) RETURNS sch_<<$app_name$>>.codes AS $$
DECLARE
        ccc sch_<<$app_name$>>.codes%ROWTYPE;
        cnt integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        SELECT c.*
        INTO ccc
        FROM sch_<<$app_name$>>.codes AS c
        WHERE c.code_text  = $1
          AND c.code_type != 'plain code';

        GET DIAGNOSTICS cnt = ROW_COUNT;

        IF cnt = 0 THEN
                PERFORM leave_schema_namespace(namespace_info);
                RETURN NULL;
        ELSIF cnt > 1 THEN
                RAISE EXCEPTION 'Data inconsistecy error detected (function "get_nonplaincode_by_str"), when trying to read a codifier "%"! Multiple nonplain codes has such names (which is illegal), can not decide, which one to return.', par_codifier;
        END IF;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN ccc;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_nonplaincode_by_str(par_codifier varchar) IS
'Returns NULL if nothing found.';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_code_by_str(par_codifier varchar, par_code varchar) RETURNS sch_<<$app_name$>>.codes AS $$
DECLARE
        ccc sch_<<$app_name$>>.codes%ROWTYPE;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        ccc:= get_code(TRUE, make_acodekeyl_bystr2(par_codifier, par_code));
        PERFORM leave_schema_namespace(namespace_info);
        RETURN ccc;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_nonplaincode_by_str(par_codifier varchar) IS
'get_code(TRUE, make_acodekeyl_str2(par_codifier, par_code))
Returns NULL if nothing found.';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_codes_of_codifier(par_acodekeyl t_addressed_code_key_by_lng) RETURNS SETOF sch_<<$app_name$>>.codes AS $$
DECLARE
        c_id integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        c_id := code_id_of(TRUE, par_acodekeyl);

        RETURN QUERY
                SELECT c.*
                FROM sch_<<$app_name$>>.codes AS c, sch_<<$app_name$>>.codes_tree AS ct
                WHERE c.code_id = ct.subcode_id
                  AND ct.supercode_id = c_id;
        PERFORM leave_schema_namespace(namespace_info);
        RETURN;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_codes_of_codifier(par_acodekeyl t_addressed_code_key_by_lng) IS
'Selects all subcodes from codes_tree, by supercode_id = code_id_of(TRUE,$1).';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_codifiers_of_code(par_acodekeyl t_addressed_code_key_by_lng) RETURNS SETOF sch_<<$app_name$>>.codes AS $$
DECLARE
        c_id integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        c_id := code_id_of(TRUE, par_acodekeyl);

        RETURN QUERY
                SELECT c.*
                FROM sch_<<$app_name$>>.codes AS c, sch_<<$app_name$>>.codes_tree AS ct
                WHERE c.code_id = ct.supercode_id
                  AND ct.subcode_id = c_id;
        PERFORM leave_schema_namespace(namespace_info);
        RETURN;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_codes_of_codifier(par_acodekeyl t_addressed_code_key_by_lng) IS
'Selects all supercodes from codes_tree, by subcode_id = code_id_of(TRUE,$1).';

-------------------------------------------------------------------------------

CREATE TYPE codes_tree_node AS (
                code_id     integer
              , code_text   varchar
              , code_type   code_type
              , default_ist boolean
              , tree_depth  integer
              , nodes_path  integer[] -- code_id[]
              , path_terminated_with_cycle boolean
              );

CREATE OR REPLACE FUNCTION find_subcodes(
          par_if_exists boolean
        , par_cf_key    t_addressed_code_key_by_lng
        , par_include_code_itself
                        boolean
        , par_only_ones_not_reachable_from_elsewhere
                        boolean
        ) RETURNS SETOF codes_tree_node AS $$
DECLARE
        max_dpth             integer;
        root_c               sch_<<$app_name$>>.codes%ROWTYPE;
        root_codes_tree_node sch_<<$app_name$>>.codes_tree_node;
        initial_scope        sch_<<$app_name$>>.codes_tree_node[];
        initial_scope_ids    integer[];
        shared_subcodes      integer[];
        excluded_subcodes    integer[];
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        root_c:= get_code(par_if_exists, par_cf_key);
        IF root_c IS NULL THEN
                PERFORM leave_schema_namespace(namespace_info);
                RETURN;
        END IF;
        root_codes_tree_node:= ROW(
                root_c.code_id
              , root_c.code_text
              , root_c.code_type
              , TRUE
              , 0
              , ARRAY[root_c.code_id]
              , FALSE
              );
        initial_scope:= ARRAY(
                        WITH RECURSIVE subcodes(code_id, code_text, code_type, default_ist, tree_depth, nodes_path, path_terminated_with_cycle) AS (
                            SELECT root_codes_tree_node.*
                          UNION ALL
                            SELECT ct.subcode_id                  AS code_id
                                 , c.code_text                    AS code_text
                                 , c.code_type                    AS code_type
                                 , ct.dflt_subcode_isit           AS default_ist
                                 , sc.tree_depth + 1              AS tree_depth
                                 , sc.nodes_path || ct.subcode_id AS nodes_path
                                 , sc.nodes_path @> ARRAY[ct.subcode_id] AS path_terminated_with_cycle
                            FROM sch_<<$app_name$>>.codes_tree AS ct
                               , sch_<<$app_name$>>.codes      AS  c
                               , subcodes AS sc
                            WHERE NOT path_terminated_with_cycle
                              AND ct.supercode_id = sc.code_id
                              AND c.code_id = ct.subcode_id
                        )
                        SELECT ROW(code_id, code_text, code_type, default_ist, tree_depth, nodes_path, path_terminated_with_cycle) :: codes_tree_node
                        FROM subcodes
                        WHERE (tree_depth != 0 OR par_include_code_itself)
                );

        IF NOT par_only_ones_not_reachable_from_elsewhere THEN
                RETURN QUERY
                        SELECT *
                        FROM unnest(initial_scope) AS x
                        WHERE (x.code_id != root_c.code_id OR par_include_code_itself);
        ELSE
                initial_scope_ids:= ARRAY(
                        SELECT DISTINCT code_id
                        FROM unnest(initial_scope) AS x
                        );
                shared_subcodes := ARRAY(
                        SELECT DISTINCT subcode_id
                        FROM sch_<<$app_name$>>.codes_tree
                        WHERE     initial_scope_ids @> ARRAY[subcode_id]
                          AND NOT initial_scope_ids @> ARRAY[supercode_id]
                          AND     supercode_id != root_c.code_id
                          AND       subcode_id != root_c.code_id
                );

                excluded_subcodes:= ARRAY(
                        SELECT DISTINCT x.code_id
                        FROM unnest(initial_scope) AS x
                        WHERE (x.nodes_path && shared_subcodes)
                );

                RETURN QUERY
                        SELECT x.*
                        FROM unnest(initial_scope) AS x
                        WHERE NOT (ARRAY[x.code_id] <@ excluded_subcodes)
                          AND (x.code_id != root_c.code_id OR par_include_code_itself);
        END IF;
        PERFORM leave_schema_namespace(namespace_info);
        RETURN;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION find_subcodes(
          par_if_exists boolean
        , par_cf_key    t_addressed_code_key_by_lng
        , par_include_code_itself
                        boolean
        , par_only_ones_not_reachable_from_elsewhere
                        boolean
        ) IS
'Selects all from the tree with
        ( get_code(par_cf_key).code_id
        , get_code(par_cf_key).code_text
        , get_code(par_cf_key).code_type
        , TRUE
        , 0
        , ARRAY [root_code_id]
        , FALSE
        )
in the root.
If parameter "par_only_ones_not_reachable_from_elsewhere" is TRUE, then excludes nodes, that are reachable by codifiers from outside of search scope.

There is a case when find_code won''t return anything for case,
when "par_only_ones_not_reachable_from_elsewhere" is TRUE:
if there exist paths A->X, X->A, B->X, but path A->B does not exist.
Nothing is found in this case, because anything reachable from A is also reachable from B.
';

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Administration functions:

CREATE OR REPLACE FUNCTION remove_code(
        par_if_exists   boolean
      , par_acodekeyl   t_addressed_code_key_by_lng
      , par_remove_code boolean
      , par_cascade_remove_subcodes
                        boolean
      , par_if_cascade__only_ones_not_reachable_from_elsewhere
                        boolean
      ) RETURNS integer AS $$
DECLARE
        cnt integer;
        find_results integer[];
        c_id integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        IF NOT par_cascade_remove_subcodes THEN
                IF par_remove_code THEN
                        c_id := code_id_of(TRUE, par_acodekeyl);

                        DELETE FROM sch_<<$app_name$>>.codes WHERE code_id = c_id;

                        GET DIAGNOSTICS cnt = ROW_COUNT;

                        PERFORM leave_schema_namespace(namespace_info);
                        RETURN cnt;
                ELSE
                        PERFORM leave_schema_namespace(namespace_info);
                        RETURN 0;
                END IF;
        ELSE
                find_results:= ARRAY(
                        SELECT DISTINCT code_id
                        FROM find_subcodes(par_if_exists, par_acodekeyl, par_remove_code, par_if_cascade__only_ones_not_reachable_from_elsewhere)
                        );

                DELETE FROM sch_<<$app_name$>>.codes WHERE find_results @> ARRAY[code_id];

                GET DIAGNOSTICS cnt = ROW_COUNT;

                PERFORM leave_schema_namespace(namespace_info);
                RETURN cnt;
        END IF;
        PERFORM leave_schema_namespace(namespace_info);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION remove_code(par_if_exists boolean, par_acodekeyl t_addressed_code_key_by_lng, par_remove_code boolean, par_cascade_remove_subcodes boolean, par_if_cascade__only_ones_not_reachable_from_elsewhere boolean) IS
'Wrapper around find_subcodes(...). Returns count of rows deleted.

There is a case when remove_code won''t delete anything for case,
when "par_if_cascade__only_ones_not_reachable_from_elsewhere" is TRUE: see comments to "find_code(...)" function for more info.
';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION bind_code_to_codifier(
          par_c_acodekeyl t_addressed_code_key_by_lng
        , par_cf_codekeyl t_code_key_by_lng
        , par_dflt boolean
        ) RETURNS integer AS $$
DECLARE
        c_id  integer;
        cf_id integer;
        cnt   integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        c_id:=  code_id_of(FALSE,                     par_c_acodekeyl );
        cf_id:= code_id_of(FALSE, generalize_codekeyl(par_cf_codekeyl));

        INSERT INTO sch_<<$app_name$>>.codes_tree (supercode_id, subcode_id, dflt_subcode_isit)
        VALUES (cf_id, c_id, COALESCE(par_dflt, FALSE));

        GET DIAGNOSTICS cnt = ROW_COUNT;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN cnt;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION bind_code_to_codifier(
          par_c_acodekeyl  t_addressed_code_key_by_lng
        , par_cf_codekeyl t_code_key_by_lng
        , par_dflt boolean
        ) IS
'Wrapper around "code_id_of(FALSE, ...)". Returns count of rows inserted.';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION unbind_code_from_codifier(
          par_if_exists boolean
        , par_c_acodekeyl  t_addressed_code_key_by_lng
        ) RETURNS integer AS $$
DECLARE
        c_id  integer;
        cf_id integer;
        cnt integer:= 0;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        c_id:=  code_id_of(par_if_exists, par_c_acodekeyl);
        cf_id:= code_id_of(par_if_exists, generalize_codekeyl(make_codekeyl(par_c_acodekeyl.key_lng, par_c_acodekeyl.codifier_key)));

        DELETE FROM sch_<<$app_name$>>.codes_tree WHERE supercode_id = cf_id AND subcode_id = c_id;

        GET DIAGNOSTICS cnt = ROW_COUNT;

        IF (cnt IS NULL OR cnt != 1) AND (NOT par_if_exists) THEN
                RAISE EXCEPTION 'An error occurred, when trying to unbind code %! Bad count (%) of rows modified.', show_acodekeyl(par_c_acodekeyl), cnt;
        END IF;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN cnt;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION unbind_code_from_codifier(
          par_if_exists boolean
        , par_c_acodekeyl  t_addressed_code_key_by_lng
        ) IS
'Wrapper around "code_id_of(...)". Returns count of rows deleted.';

-------------------------------------------------------------------------------

CREATE TYPE code_construction_input AS (code_text varchar, code_type code_type);

CREATE OR REPLACE FUNCTION new_code_by_userseqs(
          par_code_construct code_construction_input
        , par_super_code     t_code_key_by_lng
        , par_dflt_isit      boolean
        , par_codifier_ids_seq_name  varchar
        , par_plaincode_ids_seq_name varchar
        ) RETURNS integer AS $$
DECLARE
        cnt1 integer;
        cnt2 integer;
        c_id integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        IF par_code_construct.code_type = 'plain code' THEN
                c_id := nextval(par_plaincode_ids_seq_name);
        ELSE
                c_id := nextval(par_codifier_ids_seq_name);
        END IF;

        INSERT INTO sch_<<$app_name$>>.codes (code_id, code_text, code_type)
        VALUES (c_id, par_code_construct.code_text, par_code_construct.code_type);

        GET DIAGNOSTICS cnt1 = ROW_COUNT;

        IF NOT (codekeyl_type(par_super_code) = 'undef') THEN
                cnt2:= bind_code_to_codifier(
                                make_acodekeyl_byid(c_id)
                              , make_codekeyl_byid(code_id_of(FALSE, generalize_codekeyl(par_super_code)))
                              , par_dflt_isit
                              );
        END IF;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN c_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION new_code_by_userseqs(
          par_code_construct code_construction_input
        , par_super_code     t_code_key_by_lng
        , par_dflt_isit      boolean
        , par_codifier_ids_seq_name  varchar
        , par_plaincode_ids_seq_name varchar
        ) IS
'Returns ID of newly created code.
If new code is of type "plain code", then it''s ID is generated using sequence "par_plaincode_ids_seq_name". Else, sequence "par_codifier_ids_seq_name" is used.
Don''t forget that the specified sequences must be accessible with your current "search_path" PostgreSQL env. variable.
In provided API this function is the ONLY one, that accepts custom sequences for codes IDs generation.

Supercode cannot be of type "plain code", orelse an error will be triggered.
Supercode may be NULL.
';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION new_code(
          par_code_construct code_construction_input
        , par_super_code     t_code_key_by_lng
        , par_dflt_isit      boolean
        ) RETURNS integer AS $$
DECLARE
        c_id integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        c_id := new_code_by_userseqs(par_code_construct, par_super_code, par_dflt_isit, 'sch_<<$app_name$>>.codifiers_ids_seq', 'sch_<<$app_name$>>.plain_codes_ids_seq');

        PERFORM leave_schema_namespace(namespace_info);
        RETURN c_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION new_code(
          par_code_construct code_construction_input
        , par_super_code     t_code_key_by_lng
        , par_dflt_isit      boolean
        ) IS
'Wrapper around "new_code_by_userseqs" function with last two parameters = "sch_<<$app_name$>>.codifiers_ids_seq" and "sch_<<$app_name$>>.plain_codes_ids_seq".';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION add_subcodes_under_codifier(
          par_cf t_code_key_by_lng
        , par_cf_dflt_codestr varchar
        , VARIADIC par_codes_array code_construction_input[]
        )
RETURNS integer[] AS $$
DECLARE
        dflt_correct boolean;
        i integer;
        cf_id integer;
        c_ids_arr integer[];
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        cf_id:= code_id_of(FALSE, generalize_codekeyl(par_cf));

        dflt_correct := (par_cf_dflt_codestr IS NULL) OR (par_cf_dflt_codestr = '');

        FOR i IN 1..COALESCE(array_upper(par_codes_array, 1), 0) LOOP
                dflt_correct := dflt_correct OR ((par_codes_array[i]).code_text = par_cf_dflt_codestr);
        END LOOP;

        IF NOT dflt_correct THEN
                RAISE EXCEPTION 'An error occurred, when trying to add subcodes under a codifier %! The default code is specified to = "%", but it is not in the lists codes.', show_codekeyl(par_cf), par_cf_dflt_codestr;
        END IF;

        c_ids_arr:= ARRAY(
                SELECT new_code( ROW(cil.code_text, cil.code_type) :: code_construction_input
                               , make_codekeyl_byid(cf_id)
                               , par_cf_dflt_codestr = cil.code_text
                               )
                FROM unnest(par_codes_array) AS cil(code_text, code_type)
        );

        PERFORM leave_schema_namespace(namespace_info);
        RETURN c_ids_arr;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION add_subcodes_under_codifier(
          par_cf t_code_key_by_lng
        , par_cf_dflt_codestr varchar
        , VARIADIC par_codes_array code_construction_input[]
        )  IS
'Returns set of IDs of newly created codes.
Parameter "par_cf_dflt_codestr" accepts NULL or '''', if default code isn''t to be among provided in "par_codes_array" codes.
Else (if not NULL, nor '''') if value of "par_cf_dflt_codestr" parameter isn''t among provided in "par_codes_array" codes, then an exception is rised.
';

-------------------------------------------------------------------------------

CREATE TYPE result_of_making_new_codifier_w_subcodes AS (codifier_id integer, subcodes_ids_list integer[]);

CREATE OR REPLACE FUNCTION new_codifier_w_subcodes(
          par_super_cf             t_code_key_by_lng
        , par_cf_construct         code_construction_input
        , par_cf_dflt_codestr      varchar
        , VARIADIC par_codes_array code_construction_input[]
        )
RETURNS result_of_making_new_codifier_w_subcodes AS $$
DECLARE
        r sch_<<$app_name$>>.result_of_making_new_codifier_w_subcodes;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        SELECT code_id INTO r.codifier_id
        FROM unnest(add_subcodes_under_codifier(par_super_cf, NULL :: varchar, VARIADIC ARRAY[par_cf_construct])) AS re(code_id);

        r.subcodes_ids_list:= add_subcodes_under_codifier(
                                        make_codekeyl_byid(r.codifier_id)
                                      , par_cf_dflt_codestr
                                      , VARIADIC par_codes_array
                                      );

        PERFORM leave_schema_namespace(namespace_info);
        RETURN r;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION new_codifier_w_subcodes(
          par_super_cf             t_code_key_by_lng
        , par_cf_construct         code_construction_input
        , par_cf_dflt_codestr      varchar
        , VARIADIC par_codes_array code_construction_input[]
        )  IS
'Wrapper around "add_subcodes_under_codifier" function.
';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION make_codifier_from_plaincode(
          par_if_exists   boolean
        , par_reidentify  boolean
        , par_cf          t_code_key_by_lng
        , par_cf_new_type code_type
        )
RETURNS integer AS $$
DECLARE
        cf_id integer:= NULL;
        cnt integer;
        c sch_<<$app_name$>>.codes%ROWTYPE;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        -- validate input data
        IF par_cf_new_type = 'plain code' THEN
                RAISE EXCEPTION 'An error occurred, in the function "make_codifier_from_plaincode", code %! The new type of code can not be "plain code".', show_codekeyl(par_cf);
        END IF;

        SELECT *
        INTO c
        FROM get_codes_l(par_cf) as co
        WHERE co.code_type = 'plain code';

        GET DIAGNOSTICS cnt = ROW_COUNT;

        IF cnt > 1 THEN
                RAISE EXCEPTION 'An error occurred, in the function "make_codifier_from_plaincode", code %! Can''t make a codifier, because target code has a nonunique name.', show_codekeyl(par_cf);
        ELSIF cnt = 0 THEN
                IF NOT par_if_exists THEN
                        RAISE EXCEPTION 'An error occurred, in the function "make_codifier_from_plaincode", code %! Target code not found.', show_codekeyl(par_cf);
                END IF;
                PERFORM leave_schema_namespace(namespace_info);
                RETURN NULL;
        END IF;

        IF c.code_type != 'plain code' THEN
                RAISE EXCEPTION 'An error occurred, in the function "make_codifier_from_plaincode", code %! The old type of code must be "plain code".', show_codekeyl(par_cf);
        END IF;

        IF c.code_type = par_cf_new_type THEN
                RAISE EXCEPTION 'An error occurred, in the function "make_codifier_from_plaincode", code %! New code equals old code.', show_codekeyl(par_cf);
        END IF;

        IF par_reidentify THEN
                UPDATE sch_<<$app_name$>>.codes SET code_type = par_cf_new_type, code_id = nextval('sch_<<$app_name$>>.codifiers_ids_seq') WHERE code_id = c.code_id
                RETURNING code_id INTO cf_id;
        ELSE
                UPDATE sch_<<$app_name$>>.codes SET code_type = par_cf_new_type WHERE code_id = c.code_id
                RETURNING code_id INTO cf_id;
        END IF;

        PERFORM leave_schema_namespace(namespace_info);
        RETURN cf_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION  make_codifier_from_plaincode(
          par_if_exists   boolean
        , par_reidentify  boolean
        , par_cf          t_code_key_by_lng
        , par_cf_new_type code_type
        ) IS
'Returns ID of the code.
Returns an error
if target code isn''t found, or
is already of type "plain code", or
if new type specified to be "plain code", or
if new type = old type.

Finds code (to make codifier from) using query:
        SELECT *
        INTO c
        FROM get_codes_l(par_cf) as co
        WHERE co.code_type = ''plain code'';
';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION make_codifier_from_plaincode_w_values(
          par_if_exists       boolean
        , par_reidentify      boolean
        , par_c               t_code_key_by_lng
        , par_cf_new_type     code_type
        , par_cf_dflt_codestr varchar
        , VARIADIC par_codes_array code_construction_input[] -- par_cf_dflt_codestr must persist in this array
        )
RETURNS result_of_making_new_codifier_w_subcodes AS $$
DECLARE
        r sch_<<$app_name$>>.result_of_making_new_codifier_w_subcodes;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        r.codifier_id:= make_codifier_from_plaincode(par_if_exists, par_reidentify, par_c, VARIADIC par_cf_new_type);

        r.subcodes_ids_list:= add_subcodes_under_codifier(make_codekeyl_byid(r.codifier_id), par_cf_dflt_codestr, VARIADIC par_codes_array);

        PERFORM leave_schema_namespace(namespace_info);
        RETURN r;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION  make_codifier_from_plaincode_w_values(
          par_if_exists       boolean
        , par_reidentify      boolean
        , par_c               t_code_key_by_lng
        , par_cf_new_type     code_type
        , par_cf_dflt_codestr varchar
        , VARIADIC par_codes_array code_construction_input[]
        ) IS
'Wrapper around functions "make_codifier_from_plaincode(...)" and "add_subcodes_under_codifier(...)"
';

-------------------------------------------------------------------------------

CREATE TYPE name_construction_input AS
        ( lng         t_code_key_by_lng
        , name        varchar
        , entity      t_code_key_by_lng
        , description varchar
        );

COMMENT ON TYPE name_construction_input IS
'Used to fill "named_in_languages" table or it''s child table.
Since "entity" field usually has a default value, it will usually be treated in a specific way: given NULL it is theated as DEFAULT (in insertion procedure).
Constructor function:
        mk_name_construction_input(
          par_lng         t_code_key_by_lng
        , par_name        varchar
        , par_entity      t_code_key_by_lng
        , par_description varchar
        )
';

CREATE OR REPLACE FUNCTION mk_name_construction_input(
          par_lng         t_code_key_by_lng
        , par_name        varchar
        , par_entity      t_code_key_by_lng
        , par_description varchar
        ) RETURNS name_construction_input AS $$
        SELECT ROW($1, $2, $3, $4) :: sch_<<$app_name$>>.name_construction_input;
$$ LANGUAGE SQL;

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION add_code_lng_names(
          par_if_exists boolean
        , par_c         t_addressed_code_key_by_lng
        , VARIADIC par_codesnames_array
                        name_construction_input[]
        )
RETURNS integer AS $$
DECLARE
        cnt1 integer;
        cnt2 integer;
        c_id integer;
        dflt_lng_c_id integer;
        namespace_info sch_<<$app_name$>>.t_namespace_info;
BEGIN
        namespace_info := sch_<<$app_name$>>.enter_schema_namespace();

        c_id := code_id_of(par_if_exists, par_c);

        IF c_id IS NULL THEN
                IF NOT par_if_exists THEN
                        RAISE EXCEPTION 'An error occurred, in the function "add_code_lng_names", for code %! Can''t determine target code ID.', show_acodekeyl(par_c);
                END IF;

                PERFORM leave_schema_namespace(namespace_info);
                RETURN 0;
        ELSE
                FOR cnt1 IN
                        SELECT 1 FROM unnest(par_codesnames_array) AS inp WHERE codekeyl_type(inp.lng) = 'undef' LIMIT 1
                LOOP
                        dflt_lng_c_id:= codifier_default_code(FALSE, make_codekeyl_bystr('Languages'));
                END LOOP;

                INSERT INTO codes_names (code_id, lng_of_name, name, entity, description)
                SELECT c_id, v.lng_of_name, v.name, v.entity, v.description
                FROM (SELECT CASE WHEN codekeyl_type(inp.lng) != 'undef'
                                  THEN code_id_of(
                                                FALSE
                                              , make_acodekeyl(
                                                        (inp.lng).key_lng
                                                      , make_codekey_bystr('Languages')
                                                      , (inp.lng).code_key
                                                      )
                                              )
                                  ELSE dflt_lng_c_id
                             END AS lng_of_name
                           , inp.name
                           , code_id_of( FALSE
                                       , make_acodekeyl(
                                                (inp.entity).key_lng
                                              , make_codekey_bystr('Entities')
                                              , (inp.entity).code_key
                                              )
                                       ) AS entity
                           , inp.description
                      FROM unnest(par_codesnames_array) AS inp
                      WHERE codekeyl_type(inp.entity) != 'undef'
                      ) AS v;
                GET DIAGNOSTICS cnt1 = ROW_COUNT;

                -- it's a pity Postgres has poor semantics for inserting DEFAULT... well, it's not a big deal though
                INSERT INTO codes_names (code_id, lng_of_name, name, description)
                SELECT c_id, v.lng_of_name, v.name, v.description
                FROM (SELECT CASE WHEN codekeyl_type(inp.lng) != 'undef'
                                  THEN code_id_of(
                                                FALSE
                                              , make_acodekeyl(
                                                        (inp.lng).key_lng
                                                      , make_codekey_bystr('Languages')
                                                      , (inp.lng).code_key
                                                      )
                                              )
                                  ELSE dflt_lng_c_id
                             END AS lng_of_name
                           , inp.name
                           , inp.description
                      FROM unnest(par_codesnames_array) AS inp
                      WHERE codekeyl_type(inp.entity) = 'undef'
                      ) AS v;

                GET DIAGNOSTICS cnt2 = ROW_COUNT;

                PERFORM leave_schema_namespace(namespace_info);
                RETURN (cnt1 + cnt2);
        END IF;

        PERFORM leave_schema_namespace(namespace_info);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION  add_code_lng_names(
          par_if_exists boolean
        , par_c         t_addressed_code_key_by_lng
        , VARIADIC par_codesnames_array
                        name_construction_input[]
        ) IS
'Adding entries in the "codes_names" table.
Returns number of rows inserted.
If in a row of "par_codesnames_array" field "entity" is NULL, then INSERT is performed with DEFAULT for this field.
The behaviour is different for field "lng" (when it''s NULL), here INSERT is performed with default value of codifier "Languages".

Hint: use this function source code as a template for your child-tables inheriting "named_in_languages"
';

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- Service functions

GRANT EXECUTE ON FUNCTION enter_schema_namespace()TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION leave_schema_namespace(par_prev_state t_namespace_info)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION __watch(par_str varchar)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;

-- Referencing functions:

GRANT EXECUTE ON FUNCTION make_codekey(par_code_id integer, par_code_text varchar)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_codekey_null()TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_codekey_byid(par_code_id integer)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_codekey_bystr(par_code_text varchar)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_acodekey(par_cf_key t_code_key, par_c_key t_code_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_acodekey_null()TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_codekeyl(par_key_lng t_code_key, par_code_key t_code_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_codekeyl_null()TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_codekeyl_byid(par_code_id integer)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_codekeyl_bystr(par_code_text varchar)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_codekeyl_bystrl(par_lng_key t_code_key, par_code_text varchar)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_acodekeyl(par_key_lng t_code_key, par_cf_key t_code_key, par_c_key t_code_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_acodekeyl_null()TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_acodekeyl_byid(par_code_id integer)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_acodekeyl_bystr1(par_code_text varchar)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_acodekeyl_bystr2(par_codifier_text varchar, par_code_text varchar)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION generalize_codekey(par_key t_code_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION generalize_codekeyl(par_key t_code_key_by_lng)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION generalize_acodekey(par_key t_addressed_code_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION codekey_type(par_key t_code_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION acodekey_type(par_key t_addressed_code_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION codekeyl_type(par_key t_code_key_by_lng)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION acodekeyl_type(par_key t_addressed_code_key_by_lng)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION show_codekey(par_key t_code_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION show_acodekey(par_key t_addressed_code_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION show_codekeyl(par_key t_code_key_by_lng)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION show_acodekeyl(par_key t_addressed_code_key_by_lng)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION mk_name_construction_input(par_lng t_code_key_by_lng, par_name varchar, par_entity t_code_key_by_lng, par_description varchar)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;

-- Lookup functions:

GRANT EXECUTE ON FUNCTION code_id_of(par_if_exists boolean, par_acodekeyl t_addressed_code_key_by_lng)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION code_id_of_undefined()TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION code_id_of_unclassified()TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION code_id_of_error()TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION code_id_of_ambiguous()TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION code_id_of_language(varchar)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION code_id_of_entity(entity_code_text varchar)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION code_belongs_to_codifier(par_if_cf_exists boolean, par_acodekeyl t_addressed_code_key_by_lng)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_code(par_if_exists boolean, par_key t_addressed_code_key_by_lng)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION codifier_default_code(par_if_exists boolean, par_cf_keyl t_code_key_by_lng)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_codes_l(par_key t_code_key_by_lng)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_nonplaincode_by_str(par_codifier varchar)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_code_by_str(par_codifier varchar, par_code varchar)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_codes_of_codifier(par_acodekeyl t_addressed_code_key_by_lng)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_codifiers_of_code(par_acodekeyl t_addressed_code_key_by_lng)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION find_subcodes(par_if_exists boolean, par_cf_key t_addressed_code_key_by_lng, par_include_code_itself boolean, par_only_ones_not_reachable_from_elsewhere boolean)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;

-- Administration functions:

GRANT EXECUTE ON FUNCTION remove_code(par_if_exists boolean, par_acodekeyl t_addressed_code_key_by_lng, par_remove_code boolean, par_cascade_remove_subcodes boolean, par_if_cascade__only_ones_not_reachable_from_elsewhere boolean)TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION bind_code_to_codifier(par_c_acodekeyl t_addressed_code_key_by_lng, par_cf_codekeyl t_code_key_by_lng, par_dflt boolean)TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION unbind_code_from_codifier(par_if_exists boolean, par_c_acodekeyl t_addressed_code_key_by_lng)TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION new_code_by_userseqs(par_code_construct code_construction_input, par_super_code t_code_key_by_lng, par_dflt_isit boolean, par_codifier_ids_seq_name varchar, par_plaincode_ids_seq_name varchar)TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION new_code(par_code_construct code_construction_input, par_super_code t_code_key_by_lng, par_dflt_isit boolean)TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION add_subcodes_under_codifier(par_cf t_code_key_by_lng, par_cf_dflt_codestr varchar, VARIADIC par_codes_array code_construction_input[])TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION new_codifier_w_subcodes(par_super_cf t_code_key_by_lng, par_cf_construct code_construction_input, par_cf_dflt_codestr varchar, VARIADIC par_codes_array code_construction_input[])TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION make_codifier_from_plaincode(par_if_exists boolean, par_reidentify boolean, par_cf t_code_key_by_lng, par_cf_new_type code_type)TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION make_codifier_from_plaincode_w_values(par_if_exists boolean, par_reidentify boolean, par_c t_code_key_by_lng, par_cf_new_type code_type, par_cf_dflt_codestr varchar, VARIADIC par_codes_array code_construction_input[])TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION add_code_lng_names(par_if_exists boolean, par_c t_addressed_code_key_by_lng, VARIADIC par_codesnames_array name_construction_input[])TO user_<<$app_name$>>_data_admin;
