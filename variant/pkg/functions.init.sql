-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- (1) case sensetive (2) postgres lowercases real names
\c <<$db_name$>> user_db<<$db_name$>>_app<<$app_name$>>_owner

SET search_path TO sch_<<$app_name$>>, comn_funs, public; -- sets only for current session
\set ECHO none

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

\echo NOTICE >>>>> functions.init.sql [BEGIN]

-- Referencing functions:

CREATE TYPE t_code_key                  AS (code_id integer, code_text varchar);
CREATE TYPE t_addressed_code_key        AS (codifier_key t_code_key, code_key t_code_key);
CREATE TYPE t_code_key_by_lng           AS (key_lng t_code_key,                          code_key t_code_key);
CREATE TYPE t_addressed_code_key_by_lng AS (key_lng t_code_key, codifier_key t_code_key, code_key t_code_key);

--------------------------------------------------------------------------
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
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION make_codekey_null() RETURNS t_code_key AS $$
        SELECT sch_<<$app_name$>>.make_codekey(NULL :: integer, NULL :: varchar);
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION make_codekey_byid(par_code_id integer) RETURNS t_code_key AS $$
        SELECT sch_<<$app_name$>>.make_codekey($1, NULL :: varchar);
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION make_codekey_bystr(par_code_text varchar) RETURNS t_code_key AS $$
        SELECT sch_<<$app_name$>>.make_codekey(NULL :: integer, $1);
$$ LANGUAGE SQL IMMUTABLE;

------------------

CREATE OR REPLACE FUNCTION make_acodekey(par_cf_key t_code_key, par_c_key t_code_key) RETURNS t_addressed_code_key
LANGUAGE plpgsql IMMUTABLE
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE r sch_<<$app_name$>>.t_addressed_code_key;
BEGIN   r.codifier_key:= par_cf_key; r.code_key:= par_c_key;
        RETURN r;
END;
$$;

CREATE OR REPLACE FUNCTION make_acodekey_null() RETURNS t_addressed_code_key AS $$
        SELECT sch_<<$app_name$>>.make_acodekey(
                        sch_<<$app_name$>>.make_codekey_null()
                      , sch_<<$app_name$>>.make_codekey_null()
                      );
$$ LANGUAGE SQL IMMUTABLE;

------------------

CREATE OR REPLACE FUNCTION make_codekeyl(par_key_lng t_code_key, par_code_key t_code_key) RETURNS t_code_key_by_lng
LANGUAGE plpgsql IMMUTABLE
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE r sch_<<$app_name$>>.t_code_key_by_lng;
BEGIN   r.key_lng:= par_key_lng; r.code_key:= par_code_key;
        RETURN r;
END;
$$;

CREATE OR REPLACE FUNCTION make_codekeyl_null() RETURNS t_code_key_by_lng AS $$
        SELECT sch_<<$app_name$>>.make_codekeyl(
                        sch_<<$app_name$>>.make_codekey_null()
                      , sch_<<$app_name$>>.make_codekey_null()
                      );
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION make_codekeyl_byid(par_code_id integer) RETURNS t_code_key_by_lng AS $$
        SELECT sch_<<$app_name$>>.make_codekeyl(
                        sch_<<$app_name$>>.make_codekey_null()
                      , sch_<<$app_name$>>.make_codekey_byid($1)
                      );
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION make_codekeyl_bystr(par_code_text varchar) RETURNS t_code_key_by_lng AS $$
        SELECT sch_<<$app_name$>>.make_codekeyl(
                        sch_<<$app_name$>>.make_codekey_null()
                      , sch_<<$app_name$>>.make_codekey_bystr($1)
                      );
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION make_codekeyl_bystrl(par_lng_key t_code_key, par_code_text varchar) RETURNS t_code_key_by_lng AS $$
        SELECT sch_<<$app_name$>>.make_codekeyl(
                        $1
                      , sch_<<$app_name$>>.make_codekey_bystr($2)
                      );
$$ LANGUAGE SQL IMMUTABLE;

------------------

CREATE OR REPLACE FUNCTION make_acodekeyl(par_key_lng t_code_key, par_cf_key t_code_key, par_c_key t_code_key) RETURNS t_addressed_code_key_by_lng
LANGUAGE plpgsql IMMUTABLE
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE r sch_<<$app_name$>>.t_addressed_code_key_by_lng;
BEGIN   r.key_lng:= par_key_lng; r.codifier_key:= par_cf_key; r.code_key:= par_c_key;
        RETURN r;
END;
$$;

CREATE OR REPLACE FUNCTION make_acodekeyl_null() RETURNS t_addressed_code_key_by_lng AS $$
        SELECT sch_<<$app_name$>>.make_acodekeyl(
                        sch_<<$app_name$>>.make_codekey_null()
                      , sch_<<$app_name$>>.make_codekey_null()
                      , sch_<<$app_name$>>.make_codekey_null()
                      );
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION make_acodekeyl_byid(par_code_id integer) RETURNS t_addressed_code_key_by_lng AS $$
        SELECT sch_<<$app_name$>>.make_acodekeyl(
                        sch_<<$app_name$>>.make_codekey_null()
                      , sch_<<$app_name$>>.make_codekey_null()
                      , sch_<<$app_name$>>.make_codekey_byid($1)
                      );
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION make_acodekeyl_bystr1(par_code_text varchar) RETURNS t_addressed_code_key_by_lng AS $$
        SELECT sch_<<$app_name$>>.make_acodekeyl(
                        sch_<<$app_name$>>.make_codekey_null()
                      , sch_<<$app_name$>>.make_codekey_null()
                      , sch_<<$app_name$>>.make_codekey_bystr($1)
                      );
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION make_acodekeyl_bystr2(par_codifier_text varchar, par_code_text varchar) RETURNS t_addressed_code_key_by_lng AS $$
        SELECT sch_<<$app_name$>>.make_acodekeyl(
                        sch_<<$app_name$>>.make_codekey_null()
                      , sch_<<$app_name$>>.make_codekey_bystr($1)
                      , sch_<<$app_name$>>.make_codekey_bystr($2)
                      );
$$ LANGUAGE SQL IMMUTABLE;

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION generalize_codekey(par_key t_code_key) RETURNS t_addressed_code_key_by_lng AS $$
        SELECT sch_<<$app_name$>>.make_acodekeyl(
                        sch_<<$app_name$>>.make_codekey_null()
                      , sch_<<$app_name$>>.make_codekey_null()
                      , $1
                      );
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION generalize_codekey_ascf(par_key t_code_key) RETURNS t_addressed_code_key_by_lng AS $$
        SELECT sch_<<$app_name$>>.make_acodekeyl(
                        sch_<<$app_name$>>.make_codekey_null()
                      , $1
                      , sch_<<$app_name$>>.make_codekey_null()
                      );
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION generalize_codekeyl(par_key t_code_key_by_lng) RETURNS t_addressed_code_key_by_lng AS $$
        SELECT sch_<<$app_name$>>.make_acodekeyl(
                        ($1).key_lng
                      , sch_<<$app_name$>>.make_codekey_null()
                      , ($1).code_key
                      );
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION generalize_codekeyl_ascf(par_key t_code_key_by_lng) RETURNS t_addressed_code_key_by_lng AS $$
        SELECT sch_<<$app_name$>>.make_acodekeyl(
                        ($1).key_lng
                      , ($1).code_key
                      , sch_<<$app_name$>>.make_codekey_null()
                      );
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION generalize_acodekey(par_key t_addressed_code_key) RETURNS t_addressed_code_key_by_lng AS $$
        SELECT sch_<<$app_name$>>.make_acodekeyl(
                        sch_<<$app_name$>>.make_codekey_null()
                      , ($1).codifier_key
                      , ($1).code_key
                      );
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION generalize_codekeyl_wcf(par_cf_codekey t_code_key, par_key t_code_key_by_lng) RETURNS t_addressed_code_key_by_lng AS $$
        SELECT sch_<<$app_name$>>.make_acodekeyl(
                        ($2).key_lng
                      , $1
                      , ($2).code_key
                      );
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION generalize_codekey_wcf(par_cf_codekey t_code_key, par_key t_code_key) RETURNS t_addressed_code_key_by_lng AS $$
        SELECT sch_<<$app_name$>>.make_acodekeyl(
                        sch_<<$app_name$>>.make_codekey_null()
                      , $1
                      , $2
                      );
$$ LANGUAGE SQL IMMUTABLE;


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

COMMENT ON TYPE t_code_key_type IS
'
Here is the full list (not declared types marked with *):

undef
* c_id (-l,-cf) = c_id
* c_id (-l,+cf_id)
* c_id (-l,+cf_nm)
* c_id (+l_id,-cf)
* c_id (+l_id,+cf_id)
* c_id (+l_id,+cf_nm)
* c_id (+l_nm,-cf)
* c_id (+l_nm,+cf_id)
* c_id (+l_nm,+cf_nm)
c_nm (-l,-cf)
c_nm (-l,+cf_id)
c_nm (-l,+cf_nm)
c_nm (+l_id,-cf)
c_nm (+l_id,+cf_id)
c_nm (+l_id,+cf_nm)
c_nm (+l_nm,-cf)
c_nm (+l_nm,+cf_id)
c_nm (+l_nm,+cf_nm)
* cf_id (-l) = cf_id
* cf_id (+l_id)
* cf_id (+l_nm)
cf_nm (-l)
cf_nm (+l_id)
cf_nm (+l_nm)
';

CREATE OR REPLACE FUNCTION codekey_type(par_key t_code_key) RETURNS t_code_key_type
LANGUAGE plpgsql IMMUTABLE
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        ct sch_<<$app_name$>>.t_code_key_type;
BEGIN   IF par_key IS NULL THEN
                ct:= 'undef';
        ELSIF par_key.code_id IS NOT NULL THEN
                ct:= 'c_id';
        ELSIF par_key.code_text IS NOT NULL THEN
                ct:= 'c_nm (-l,-cf)';
        ELSE
                ct:= 'undef';
        END IF;

        RETURN ct;
END;
$$;

COMMENT ON FUNCTION codekey_type(par_key t_code_key) IS
'May return 3 types
: "undef"
, "c_id"
, "c_nm (-l,-cf)"
.
Doesn''t return NULL.
';

CREATE OR REPLACE FUNCTION acodekey_type(par_key t_addressed_code_key) RETURNS t_code_key_type
LANGUAGE plpgsql IMMUTABLE
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        ct  sch_<<$app_name$>>.t_code_key_type;
        ct2 sch_<<$app_name$>>.t_code_key_type;
        ct3 sch_<<$app_name$>>.t_code_key_type;
BEGIN   IF par_key IS NULL THEN
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

        RETURN ct;
END;
$$;

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

CREATE OR REPLACE FUNCTION codekeyl_type(par_key t_code_key_by_lng) RETURNS t_code_key_type
LANGUAGE plpgsql IMMUTABLE
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE ct  sch_<<$app_name$>>.t_code_key_type;
        ct2 sch_<<$app_name$>>.t_code_key_type;
        ct3 sch_<<$app_name$>>.t_code_key_type;
BEGIN   IF par_key IS NULL THEN
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

        RETURN ct;
END;
$$;

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

CREATE OR REPLACE FUNCTION acodekeyl_type(par_key t_addressed_code_key_by_lng) RETURNS t_code_key_type
LANGUAGE plpgsql IMMUTABLE
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        ct  sch_<<$app_name$>>.t_code_key_type;
        ct2 sch_<<$app_name$>>.t_code_key_type;
        ct3 sch_<<$app_name$>>.t_code_key_type;
        ct4 sch_<<$app_name$>>.t_code_key_type;
BEGIN
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

        RETURN ct;
END;
$$;

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

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION optimized_codekey_isit(par_codekey t_code_key) RETURNS boolean
LANGUAGE SQL IMMUTABLE
AS $$
        SELECT sch_<<$app_name$>>.codekey_type($1) = 'c_id';
$$;

CREATE OR REPLACE FUNCTION optimized_acodekey_isit(par_acodekey t_addressed_code_key, par_opt_mask integer) RETURNS boolean
LANGUAGE plpgsql IMMUTABLE
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        ctype sch_<<$app_name$>>.t_code_key_type;
        r boolean;
BEGIN
        IF par_opt_mask = 0 THEN
                RETURN TRUE;
        ELSIF par_opt_mask NOT IN (1,2,3) THEN
                RAISE EXCEPTION 'An error occurred in function "optimized_acodekey_isit"! Bad mask.';
        END IF;

        ctype:= acodekey_type(par_acodekey);
        IF ctype = 'undef' THEN
                RETURN FALSE;
        END IF;
        r:=     ((mod(par_opt_mask     , 2) = 0) OR (ctype = 'c_id'))
            AND ((mod(par_opt_mask >> 1, 2) = 0) OR (codekey_type(par_acodekey.codifier_key) = 'c_id'));
        RETURN r;
END;
$$;

COMMENT ON FUNCTION optimized_acodekey_isit(par_acodekey t_addressed_code_key, par_opt_mask integer) IS
'Parameter "par_opt_mask" is a bit-mask:
(0) code key is checked to be defined by ID;
(1) codifier key is checked to be defined by ID;
(rest) not used.
.
Doesn''t return NULL.
';

--------------

CREATE OR REPLACE FUNCTION optimized_codekeyl_isit(par_codekeyl t_code_key_by_lng, par_opt_mask integer) RETURNS boolean
LANGUAGE plpgsql IMMUTABLE
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        ctype sch_<<$app_name$>>.t_code_key_type;
        r boolean;
BEGIN
        IF par_opt_mask = 0 THEN
                RETURN TRUE;
        ELSIF par_opt_mask NOT IN (1,4,5) THEN
                RAISE EXCEPTION 'An error occurred in function "optimized_codekeyl_isit"! Bad mask.';
        END IF;

        ctype:= codekeyl_type(par_codekeyl);
        IF ctype = 'undef' THEN
                RETURN FALSE;
        END IF;
        r:=     ((mod(par_opt_mask     , 2) = 0) OR (ctype = 'c_id'))
            AND ((mod(par_opt_mask >> 2, 2) = 0) OR (codekey_type(par_codekeyl.key_lng) = 'c_id'));
        RETURN r;
END;
$$;

COMMENT ON FUNCTION optimized_codekeyl_isit(par_codekeyl t_code_key_by_lng, par_opt_mask integer) IS
'Parameter "par_opt_mask" is a bit-mask:
(0) code key is checked to be defined by ID;
(1) not used;
(2) language key is checked to be defined by ID;
(rest) not used.
.
Doesn''t return NULL.
';

CREATE OR REPLACE FUNCTION optimized_acodekeyl_isit(par_acodekeyl t_addressed_code_key_by_lng, par_opt_mask integer) RETURNS boolean
LANGUAGE plpgsql IMMUTABLE
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        ctype sch_<<$app_name$>>.t_code_key_type;
        r boolean;
BEGIN
        IF par_opt_mask = 0 THEN
                RETURN TRUE;
        ELSIF par_opt_mask > 7 OR par_opt_mask < 0 THEN
                RAISE EXCEPTION 'An error occurred in function "optimized_acodekeyl_isit"! Bad mask.';
        END IF;

        ctype:= acodekeyl_type(par_acodekeyl);
        IF ctype = 'undef' THEN
                RETURN FALSE;
        END IF;
        r:=     ((mod(par_opt_mask     , 2) = 0) OR (ctype = 'c_id'))
            AND ((mod(par_opt_mask >> 1, 2) = 0) OR (codekey_type(par_acodekeyl.codifier_key) = 'c_id'))
            AND ((mod(par_opt_mask >> 2, 2) = 0) OR (codekey_type(par_acodekeyl.key_lng) = 'c_id'));
        RETURN r;
END;
$$;

COMMENT ON FUNCTION optimized_acodekeyl_isit(par_acodekeyl t_addressed_code_key_by_lng, par_opt_mask integer) IS
'Parameter "par_opt_mask" is a bit-mask:
(0) code key is checked to be defined by ID;
(1) codifier key is checked to be defined by ID;
(2) language key is checked to be defined by ID;
(rest) not used.
.
Doesn''t return NULL.
';

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
$$ LANGUAGE SQL IMMUTABLE;

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
$$ LANGUAGE SQL IMMUTABLE;

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
$$ LANGUAGE SQL IMMUTABLE;

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
$$ LANGUAGE SQL IMMUTABLE;

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------
-- Lookup functions:

CREATE OR REPLACE FUNCTION optimize_acodekeyl(par_ifexists boolean, par_acodekeyl t_addressed_code_key_by_lng, par_determine_mask integer) RETURNS t_addressed_code_key_by_lng
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        tmp_codekey      sch_<<$app_name$>>.t_code_key;
        v_acodekeyl      sch_<<$app_name$>>.t_addressed_code_key_by_lng;
        v_acodekeyl_type sch_<<$app_name$>>.t_code_key_type;
        v_codekey_type   sch_<<$app_name$>>.t_code_key_type;
        v_language_id    integer:= NULL;
        v_codifier_id    integer:= NULL;
        v_code_id        integer:= NULL;
        test             boolean;
        allow_insufficient_key boolean:= FALSE;
        rows_count       integer:= -1;
BEGIN
        IF par_determine_mask > 7 OR par_determine_mask < 0 THEN
                RAISE EXCEPTION 'Unsupported determination mode mask!';
        END IF;

        IF par_ifexists THEN
                IF sch_<<$app_name$>>.optimized_acodekeyl_isit(par_acodekeyl, par_determine_mask) THEN
                        RETURN par_acodekeyl;
                END IF;
        END IF;

        v_acodekeyl := par_acodekeyl;
        v_acodekeyl_type := acodekeyl_type(v_acodekeyl);
        CASE v_acodekeyl_type
            WHEN 'undef' THEN
                IF (mod(par_determine_mask, 8) != 0) AND NOT allow_insufficient_key THEN
                        RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Determination command is given, but key is undefined.', show_acodekeyl(v_acodekeyl);
                END IF;
            WHEN 'c_id' THEN
                v_codekey_type := codekey_type(v_acodekeyl.codifier_key);

                IF mod(par_determine_mask >> 1, 2) = 1 THEN -- if codifier to be determined
                        CASE v_codekey_type
                            WHEN 'undef'         THEN
                                IF NOT allow_insufficient_key THEN
                                    RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Codifier is commanded to be determined, but no codifier is specified (code may belong to multiple codifiers)(1).', show_acodekeyl(v_acodekeyl);
                                END IF;
                            WHEN 'c_id'          THEN
                                IF mod(par_determine_mask >> 2, 2) = 1 THEN -- if language to be determined
                                        CASE codekey_type(v_acodekeyl.key_lng)
                                            WHEN 'undef' THEN
                                                IF NOT allow_insufficient_key THEN
                                                    RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Language is commanded to be determined, but no language is specified(1).', show_acodekeyl(v_acodekeyl);
                                                END IF;
                                            WHEN 'c_id' THEN
                                                -- done already
                                            WHEN 'c_nm (-l,-cf)' THEN
                                                tmp_codekey := v_acodekeyl.key_lng;
                                                tmp_codekey.code_id := code_id_of_language((v_acodekeyl.key_lng).code_text);
                                                v_acodekeyl.key_lng := tmp_codekey;
                                            ELSE
                                                RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Unexpected result for "codekey_type(v_acodekeyl.key_lng)"(1).', show_acodekeyl(v_acodekeyl);
                                        END CASE;
                                END IF;
                            WHEN 'c_nm (-l,-cf)' THEN
                                CASE codekey_type(v_acodekeyl.key_lng)
                                    WHEN 'undef' THEN
                                        IF mod(par_determine_mask >> 2, 2) = 1 THEN -- if language to be determined
                                            IF NOT allow_insufficient_key THEN
                                                RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Language is commanded to be determined, but no language is specified(2).', show_acodekeyl(v_acodekeyl);
                                            END IF;
                                        END IF;

                                        SELECT c.code_id
                                        INTO v_codifier_id
                                        FROM codes_tree AS ct
                                           , codes      AS c
                                        WHERE ct.supercode_id = c.code_id
                                          AND ct.subcode_id   = (v_acodekeyl.code_key).code_id
                                          AND c.code_text     = (v_acodekeyl.codifier_key).code_text;

                                        GET DIAGNOSTICS rows_count = ROW_COUNT;

                                        IF NOT (rows_count = 1) AND NOT par_ifexists THEN
                                                RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Verification of code belonging to codifier failed (not found).', show_acodekeyl(v_acodekeyl);
                                        ELSE
                                                tmp_codekey := v_acodekeyl.codifier_key;
                                                tmp_codekey.code_id := v_codifier_id;
                                                v_acodekeyl.codifier_key := tmp_codekey;
                                        END IF;
                                    WHEN 'c_id' THEN
                                        SELECT cn.code_id
                                        INTO v_codifier_id
                                        FROM codes_tree  AS ct
                                           , codes_names AS cn
                                        WHERE cn.lng_of_name  = (v_acodekeyl.key_lng).code_id
                                          AND ct.supercode_id = cn.code_id
                                          AND ct.subcode_id   = (v_acodekeyl.code_key).code_id
                                          AND cn.name         = (v_acodekeyl.codifier_key).code_text;

                                        GET DIAGNOSTICS rows_count = ROW_COUNT;

                                        IF NOT (rows_count = 1) AND NOT par_ifexists THEN
                                                RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Verification of code belonging to codifier failed (not found).', show_acodekeyl(v_acodekeyl);
                                        ELSE
                                                tmp_codekey := v_acodekeyl.codifier_key;
                                                tmp_codekey.code_id := v_codifier_id;
                                                v_acodekeyl.codifier_key := tmp_codekey;
                                        END IF;
                                    WHEN 'c_nm (-l,-cf)' THEN
                                        SELECT cf_n.code_id, c_lng.language_code_id
                                        INTO v_codifier_id, v_language_id
                                        FROM codes_tree  AS ct
                                           , codes_names AS cf_n
                                           , languages   AS c_lng
                                        WHERE ct.supercode_id  = cf_n.code_id
                                          AND ct.subcode_id    = (v_acodekeyl.code_key).code_id
                                          AND cf_n.lng_of_name = c_lng.code_id
                                          AND c_lng.code_text
                                                               = (v_acodekeyl.key_lng).code_text
                                          AND cf_n.name        = (v_acodekeyl.codifier_key).code_text;

                                        GET DIAGNOSTICS rows_count = ROW_COUNT;

                                        IF NOT (rows_count = 1) AND NOT par_ifexists THEN
                                                RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Verification of code belonging to codifier failed (not found).', show_acodekeyl(v_acodekeyl);
                                        ELSE
                                                tmp_codekey := v_acodekeyl.codifier_key;
                                                tmp_codekey.code_id := v_codifier_id;
                                                v_acodekeyl.codifier_key := tmp_codekey;

                                                tmp_codekey := v_acodekeyl.key_lng;
                                                tmp_codekey.code_id := v_language_id;
                                                v_acodekeyl.key_lng := tmp_codekey;
                                        END IF;
                                    ELSE
                                        RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Unexpected result for "codekey_type(v_acodekeyl.key_lng)"(2).', show_acodekeyl(v_acodekeyl);
                                END CASE;
                            ELSE
                                RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Unexpected result for "codekey_type(v_acodekeyl.codifier_key)".', show_acodekeyl(v_acodekeyl);
                        END CASE;
                ELSIF mod(par_determine_mask >> 2, 2) = 1 THEN
                        CASE codekey_type(v_acodekeyl.key_lng)
                            WHEN 'undef' THEN
                                IF NOT allow_insufficient_key THEN
                                    RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Language is commanded to be determined, but no language is specified(0).', show_acodekeyl(v_acodekeyl);
                                END IF;
                            WHEN 'c_id' THEN
                            WHEN 'c_nm (-l,-cf)' THEN
                                tmp_codekey := v_acodekeyl.key_lng;
                                tmp_codekey.code_id := code_id_of_language((v_acodekeyl.key_lng).code_text);
                                v_acodekeyl.key_lng := tmp_codekey;
                            ELSE
                                RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Unexpected result for "codekey_type(v_acodekeyl.key_lng)"(3).', show_acodekeyl(v_acodekeyl);
                        END CASE;
                END IF;
            WHEN 'cf_id' THEN
                IF (mod(par_determine_mask, 2) = 1) AND NOT allow_insufficient_key THEN
                        RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Code is commanded to be determined, but no identifiable code is specified(0).', show_acodekeyl(v_acodekeyl);
                END IF;

                IF mod(par_determine_mask >> 2, 2) = 1 THEN
                        CASE codekey_type(v_acodekeyl.key_lng)
                            WHEN 'undef' THEN
                                IF NOT allow_insufficient_key THEN
                                    RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Language is commanded to be determined, but no language is specified(3).', show_acodekeyl(v_acodekeyl);
                                END IF;
                            WHEN 'c_id' THEN
                            WHEN 'c_nm (-l,-cf)' THEN
                                tmp_codekey := v_acodekeyl.key_lng;
                                tmp_codekey.code_id := code_id_of_language((v_acodekeyl.key_lng).code_text);
                                v_acodekeyl.key_lng := tmp_codekey;
                            ELSE
                                RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Unexpected result for "codekey_type(v_acodekeyl.key_lng)"(3).', show_acodekeyl(v_acodekeyl);
                        END CASE;
                END IF;
            WHEN 'c_nm (-l,-cf)' THEN
                IF (mod(par_determine_mask, 8) != 0) AND NOT allow_insufficient_key THEN
                        RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Determination command is given, but it''s impossible to determine anything with key of type "c_nm (-l,-cf)".', show_acodekeyl(v_acodekeyl);
                END IF;
            WHEN 'c_nm (-l,+cf_id)' THEN
                IF (mod(par_determine_mask >> 2, 2) = 1) AND NOT allow_insufficient_key THEN
                        RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Language is commanded to be determined, but no language is specified(4).', show_acodekeyl(v_acodekeyl);
                END IF;

                IF (mod(par_determine_mask, 2) = 1) THEN
                        SELECT c.code_id
                        INTO v_code_id
                        FROM codes       AS c
                           , codes_tree  AS ct
                        WHERE c.code_text     = (v_acodekeyl.code_key).code_text
                          AND ct.supercode_id = (v_acodekeyl.codifier_key).code_id
                          AND ct.subcode_id   = c.code_id;

                        GET DIAGNOSTICS rows_count = ROW_COUNT;

                        IF NOT (rows_count = 1) AND NOT par_ifexists THEN
                                RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Verification of code belonging to codifier failed (not found).', show_acodekeyl(v_acodekeyl);
                        ELSE
                                tmp_codekey := v_acodekeyl.code_key;
                                tmp_codekey.code_id := v_code_id;
                                v_acodekeyl.code_key := tmp_codekey;
                        END IF;
                END IF;
            WHEN 'c_nm (-l,+cf_nm)' THEN
                IF (mod(par_determine_mask >> 2, 2) = 1) AND NOT allow_insufficient_key THEN
                        RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Language is commanded to be determined, but no language is specified(5).', show_acodekeyl(v_acodekeyl);
                END IF;

                IF (mod(par_determine_mask, 2) = 1) OR (mod(par_determine_mask >> 1, 2) = 1) THEN
                        SELECT cf.code_id, c.code_id
                        INTO v_codifier_id, v_code_id
                        FROM codes       AS cf
                           , codes       AS c
                           , codes_tree  AS ct
                        WHERE cf.code_text    = (v_acodekeyl.codifier_key).code_text
                          AND c.code_text     = (v_acodekeyl.code_key).code_text
                          AND ct.supercode_id = cf.code_id
                          AND ct.subcode_id   = c.code_id;

                        GET DIAGNOSTICS rows_count = ROW_COUNT;

                        IF NOT (rows_count = 1) AND NOT par_ifexists THEN
                                RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Verification of code belonging to codifier failed (not found).', show_acodekeyl(v_acodekeyl);
                        ELSE
                                tmp_codekey := v_acodekeyl.codifier_key;
                                tmp_codekey.code_id := v_codifier_id;
                                v_acodekeyl.codifier_key := tmp_codekey;

                                tmp_codekey := v_acodekeyl.code_key;
                                tmp_codekey.code_id := v_code_id;
                                v_acodekeyl.code_key := tmp_codekey;
                        END IF;
                END IF;
            WHEN 'c_nm (+l_id,-cf)' THEN
                IF (mod(par_determine_mask, 2) = 1) AND NOT allow_insufficient_key THEN
                        RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Code is commanded to be determined, but no identifiable code is specified(1).', show_acodekeyl(v_acodekeyl);
                END IF;
                IF (mod(par_determine_mask >> 1, 2) = 1) AND NOT allow_insufficient_key THEN
                        RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Codifier is commanded to be determined, but no codifier is specified (code may belong to multiple codifiers)(2).', show_acodekeyl(v_acodekeyl);
                END IF;
            WHEN 'c_nm (+l_nm,-cf)' THEN
                IF (mod(par_determine_mask, 2) = 1) AND NOT allow_insufficient_key THEN
                        RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Code is commanded to be determined, but no identifiable code is specified(2).', show_acodekeyl(v_acodekeyl);
                END IF;
                IF (mod(par_determine_mask >> 1, 2) = 1) AND NOT allow_insufficient_key THEN
                        RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Codifier is commanded to be determined, but no codifier is specified (code may belong to multiple codifiers)(3).', show_acodekeyl(v_acodekeyl);
                END IF;

                IF mod(par_determine_mask >> 2, 2) = 1 THEN -- if language to be determined
                        CASE codekey_type(v_acodekeyl.key_lng)
                            WHEN 'undef' THEN
                                IF NOT allow_insufficient_key THEN
                                    RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Language is commanded to be determined, but no language is specified(3).', show_acodekeyl(v_acodekeyl);
                                END IF;
                            WHEN 'c_id' THEN
                            WHEN 'c_nm (-l,-cf)' THEN
                                tmp_codekey := v_acodekeyl.key_lng;
                                tmp_codekey.code_id := code_id_of_language((v_acodekeyl.key_lng).code_text);
                                v_acodekeyl.key_lng := tmp_codekey;
                            ELSE
                                RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Unexpected result for "codekey_type(v_acodekeyl.key_lng)"(3).', show_acodekeyl(v_acodekeyl);
                        END CASE;
                END IF;
            WHEN 'cf_nm (-l)' THEN
                IF (mod(par_determine_mask, 2) = 1) AND NOT allow_insufficient_key THEN
                        RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Code is commanded to be determined, but no identifiable code is specified(3).', show_acodekeyl(v_acodekeyl);
                END IF;
                IF (mod(par_determine_mask >> 2, 2) = 1) AND NOT allow_insufficient_key THEN
                        RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Language is commanded to be determined, but no language is specified(6).', show_acodekeyl(v_acodekeyl);
                END IF;
                IF (mod(par_determine_mask >> 1, 2) = 1) THEN
                        SELECT cf.code_id
                        INTO v_codifier_id
                        FROM codes       AS cf
                        WHERE cf.code_text  = (v_acodekeyl.codifier_key).code_text
                          AND cf.code_type != 'plain code';

                        GET DIAGNOSTICS rows_count = ROW_COUNT;

                        IF NOT (rows_count = 1) AND NOT par_ifexists THEN
                                RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Verification of code belonging to codifier failed (not found).', show_acodekeyl(v_acodekeyl);
                        ELSE
                                tmp_codekey := v_acodekeyl.codifier_key;
                                tmp_codekey.code_id := v_codifier_id;
                                v_acodekeyl.codifier_key := tmp_codekey;
                        END IF;
                END IF;
            WHEN 'cf_nm (+l_id)' THEN
                IF (mod(par_determine_mask, 2) = 1) AND NOT allow_insufficient_key THEN
                        RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Code is commanded to be determined, but no identifiable code is specified(4).', show_acodekeyl(v_acodekeyl);
                END IF;

                IF (mod(par_determine_mask >> 1, 2) = 1) THEN
                        SELECT cf_n.code_id
                        INTO v_codifier_id
                        FROM codes       AS cf
                           , codes_names AS cf_n
                        WHERE cf.code_id = cf_n.code_id
                          AND cf_n.name  = (v_acodekeyl.codifier_key).code_text
                          AND cf_n.lng_of_name = (v_acodekeyl.key_lng).code_id
                          AND cf.code_type != 'plain code';

                        GET DIAGNOSTICS rows_count = ROW_COUNT;

                        IF NOT (rows_count = 1) AND NOT par_ifexists THEN
                                RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Verification of code belonging to codifier failed (not found).', show_acodekeyl(v_acodekeyl);
                        ELSE
                                tmp_codekey := v_acodekeyl.codifier_key;
                                tmp_codekey.code_id := v_codifier_id;
                                v_acodekeyl.codifier_key := tmp_codekey;
                        END IF;
                END IF;
            WHEN 'cf_nm (+l_nm)' THEN
                IF (mod(par_determine_mask, 2) = 1) AND NOT allow_insufficient_key THEN
                        RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Code is commanded to be determined, but no identifiable code is specified(5).', show_acodekeyl(v_acodekeyl);
                END IF;

                IF (mod(par_determine_mask >> 1, 2) = 1) OR (mod(par_determine_mask >> 2, 2) = 1) THEN
                        SELECT cf_n.code_id, c_lng.code_id
                        INTO v_codifier_id, v_language_id
                        FROM codes       AS cf
                           , codes_names AS cf_n
                           , codes       AS c_lng
                        WHERE cf.code_id       = cf_n.code_id
                          AND cf_n.name        = (v_acodekeyl.codifier_key).code_text
                          AND cf_n.lng_of_name = c_lng.code_id
                          AND c_lng.code_text
                                               = (v_acodekeyl.key_lng).code_text
                          AND cf.code_type    != 'plain code';

                        GET DIAGNOSTICS rows_count = ROW_COUNT;

                        IF NOT (rows_count = 1) AND NOT par_ifexists THEN
                                RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Verification of code belonging to codifier failed (not found).', show_acodekeyl(v_acodekeyl);
                        ELSE
                                tmp_codekey := v_acodekeyl.codifier_key;
                                tmp_codekey.code_id := v_codifier_id;
                                v_acodekeyl.codifier_key := tmp_codekey;

                                tmp_codekey := v_acodekeyl.key_lng;
                                tmp_codekey.code_id := v_language_id;
                                v_acodekeyl.key_lng := tmp_codekey;
                        END IF;
                END IF;
            WHEN 'c_nm (+l_id,+cf_id)' THEN
                IF (mod(par_determine_mask, 2) = 1) THEN
                        SELECT c_n.code_id
                        INTO v_code_id
                        FROM codes_names AS c_n
                           , codes_tree  AS ct
                        WHERE c_n.name        = (v_acodekeyl.code_key).code_text
                          AND c_n.lng_of_name = (v_acodekeyl.key_lng).code_id
                          AND c_n.code_id     = ct.subcode_id
                          AND ct.supercode_id = (v_acodekeyl.codifier_key).code_id;

                        GET DIAGNOSTICS rows_count = ROW_COUNT;

                        IF NOT (rows_count = 1) AND NOT par_ifexists THEN
                                RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Verification of code belonging to codifier failed (not found).', show_acodekeyl(v_acodekeyl);
                        ELSE
                                tmp_codekey := v_acodekeyl.code_key;
                                tmp_codekey.code_id := v_code_id;
                                v_acodekeyl.code_key := tmp_codekey;
                        END IF;
                END IF;
            WHEN 'c_nm (+l_id,+cf_nm)' THEN
                IF (mod(par_determine_mask, 2) = 1) OR (mod(par_determine_mask >> 1, 2) = 1) THEN
                        SELECT c_n.code_id, cf_n.code_id
                        INTO v_code_id, v_codifier_id
                        FROM codes_names AS c_n
                           , codes_names AS cf_n
                           , codes_tree  AS ct
                        WHERE c_n.name        = (v_acodekeyl.code_key).code_text
                          AND cf_n.name       = (v_acodekeyl.codifier_key).code_text
                          AND c_n.code_id     = ct.subcode_id
                          AND cf_n.code_id    = ct.supercode_id
                          AND c_n.lng_of_name = (v_acodekeyl.key_lng).code_id
                          AND cf_n.lng_of_name = (v_acodekeyl.key_lng).code_id;

                        GET DIAGNOSTICS rows_count = ROW_COUNT;

                        IF NOT (rows_count = 1) AND NOT par_ifexists THEN
                                RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Verification of code belonging to codifier failed (not found).', show_acodekeyl(v_acodekeyl);
                        ELSE
                                tmp_codekey := v_acodekeyl.code_key;
                                tmp_codekey.code_id := v_code_id;
                                v_acodekeyl.code_key := tmp_codekey;

                                tmp_codekey := v_acodekeyl.codifier_key;
                                tmp_codekey.code_id := v_codifier_id;
                                v_acodekeyl.codifier_key := tmp_codekey;
                        END IF;
                END IF;
            WHEN 'c_nm (+l_nm,+cf_id)' THEN
                IF (mod(par_determine_mask, 2) = 1) OR (mod(par_determine_mask >> 2, 2) = 1) THEN
                        SELECT c_n.code_id, c_lng.code_id
                        INTO v_code_id, v_language_id
                        FROM codes_names AS c_n
                           , codes_names AS cf_n
                           , codes_tree  AS ct
                           , languages   AS c_lng
                        WHERE c_n.name        = (v_acodekeyl.code_key).code_text
                          AND c_n.code_id     = ct.subcode_id
                          AND ct.supercode_id = (v_acodekeyl.codifier_key).code_id
                          AND c_n.lng_of_name = c_lng.code_id
                          AND c_lng.code_text
                                              = (v_acodekeyl.key_lng).code_text;

                        GET DIAGNOSTICS rows_count = ROW_COUNT;

                        IF NOT (rows_count = 1) AND NOT par_ifexists THEN
                                RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Verification of code belonging to codifier failed (not found).', show_acodekeyl(v_acodekeyl);
                        ELSE
                                tmp_codekey := v_acodekeyl.code_key;
                                tmp_codekey.code_id := v_code_id;
                                v_acodekeyl.code_key := tmp_codekey;

                                tmp_codekey := v_acodekeyl.key_lng;
                                tmp_codekey.code_id := v_language_id;
                                v_acodekeyl.key_lng := tmp_codekey;
                        END IF;
                END IF;
            WHEN 'c_nm (+l_nm,+cf_nm)' THEN
                IF (mod(par_determine_mask, 8) != 0) THEN
                        SELECT c_n.code_id, cf_n.code_id, c_lng.code_id
                        INTO v_code_id, v_codifier_id, v_language_id
                        FROM codes_names AS c_n
                           , codes_names AS cf_n
                           , codes_tree  AS ct
                           , languages       AS c_lng
                        WHERE c_n.name         = (v_acodekeyl.code_key).code_text
                          AND cf_n.name        = (v_acodekeyl.codifier_key).code_text
                          AND c_n.code_id      = ct.subcode_id
                          AND cf_n.code_id     = ct.supercode_id
                          AND c_n.lng_of_name  = c_lng.code_id
                          AND cf_n.lng_of_name = c_lng.code_id
                          AND c_lng.code_text
                                               = (v_acodekeyl.key_lng).code_text;

                        GET DIAGNOSTICS rows_count = ROW_COUNT;

                        IF NOT (rows_count = 1) AND NOT par_ifexists THEN
                                RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Verification of code belonging to codifier failed (not found).', show_acodekeyl(v_acodekeyl);
                        ELSE
                                tmp_codekey := v_acodekeyl.code_key;
                                tmp_codekey.code_id := v_code_id;
                                v_acodekeyl.code_key := tmp_codekey;

                                tmp_codekey := v_acodekeyl.codifier_key;
                                tmp_codekey.code_id := v_codifier_id;
                                v_acodekeyl.codifier_key := tmp_codekey;

                                tmp_codekey := v_acodekeyl.key_lng;
                                tmp_codekey.code_id := v_language_id;
                                v_acodekeyl.key_lng := tmp_codekey;
                        END IF;
                END IF;
            ELSE
                RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl"! Unexpected "acodekeyl_type(v_acodekeyl)" output for code key: %!', show_acodekeyl(v_acodekeyl);
        END CASE;

        -- These (\/) errors should never occur!
        -- If it came to them, then apropriate error (defined earlier in the procedur) failed to trigger properly!!!
        -- IF (mod(par_determine_mask, 2) != 0) THEN
        --         v_codekey_type:= codekey_type(v_acodekeyl.code_key);
        --         IF v_codekey_type != 'c_id' THEN
        --                 RAISE WARNING '!!!';
        --                 RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Code ID, set to be determined, is left undetermined in result.', show_acodekeyl(v_acodekeyl);
        --         END IF;
        -- END IF;
        --
        -- IF (mod(par_determine_mask >> 1, 2) != 0) THEN
        --         v_codekey_type:= codekey_type(v_acodekeyl.codifier_key);
        --         IF v_codekey_type != 'c_id' THEN
        --                 RAISE WARNING '!!!';
        --                 RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Codifier ID, set to be determined, is left undetermined in result.', show_acodekeyl(v_acodekeyl);
        --         END IF;
        -- END IF;
        --
        -- IF (mod(par_determine_mask >> 2, 2) != 0) THEN
        --         v_codekey_type:= codekey_type(v_acodekeyl.key_lng);
        --         IF v_codekey_type != 'c_id' THEN
        --                 RAISE WARNING '!!!';
        --                 RAISE EXCEPTION 'An error occurred in function "optimize_acodekeyl" for code key: %! Language ID, set to be determined, is left undetermined in result.', show_acodekeyl(v_acodekeyl);
        --         END IF;
        -- END IF;

        RETURN v_acodekeyl;
END;
$$;

COMMENT ON FUNCTION optimize_acodekeyl(par_ifexists boolean, par_acodekeyl t_addressed_code_key_by_lng, par_determine_mask integer) IS
'This function optimizes addressed and languaged code key.
By optimizing here is understood making key containing names to contain IDs.
Such (ID-ed) keys always work faster. The main use case: when you have to do more than 1 action using 1 same key, it''s best to optimize it.
All functions working with code keys do such optimization - each one it''s own.
So if you optimize one key, that is to be used in multiple operations, the summary cost will be less.

Determination mask bit-map:
(0) - determine code ID
(1) - determine codifier ID
(2) - determine language ID
Anyway, if determination mask is 1 then determination of codifier ID and language ID is not obligate. But, if for determination of code ID codifier and/or language are tackled, then their IDs will also be determined.
Parameter "par_ifexists" if TRUE, then function won''t raise exceptions in cases, when unable to find whats needed for determination (addressed by given key) codes tables. However, if for key optimization querying codes table is not needed, then exception won''t be rised anyway.
But if given key is not sufficiently defined to satisfy determination (requested in mask), then an error will be rised. F.e., language key is requested to be optimized, but it''s given NULL - error.

This function is not for tasks which include the verification: if code addressed by key exists! For such purpose use "code_id_of" function.
';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION optimization_mode_for_acodekeyl(par_acodekeyl t_addressed_code_key_by_lng, par_determination_preference_mask integer, par_imperative_or_mask integer)
RETURNS integer
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        result_mode integer:= 0;
        v_acodekeyl_type   sch_<<$app_name$>>.t_code_key_type;
        v_codekey_type     sch_<<$app_name$>>.t_code_key_type:= 'undef';
        v_codifierkey_type sch_<<$app_name$>>.t_code_key_type:= 'undef';
        v_lngkey_type      sch_<<$app_name$>>.t_code_key_type:= 'undef';
BEGIN
        IF par_determination_preference_mask > 7 OR par_determination_preference_mask < 0 THEN
                RAISE EXCEPTION 'Unsupported determination preference mask!';
        END IF;
        IF par_imperative_or_mask > 7 OR par_imperative_or_mask < 0 THEN
                RAISE EXCEPTION 'Unsupported determination imperative or-mask!';
        END IF;

        v_acodekeyl_type := sch_<<$app_name$>>.acodekeyl_type(par_acodekeyl);
        IF v_acodekeyl_type = 'undef' THEN
            result_mode:= par_imperative_or_mask;
        ELSE
            IF mod(par_determination_preference_mask     , 2) = 1 THEN -- if code to be determined
                CASE sch_<<$app_name$>>.codekey_type(par_acodekeyl.code_key)
                    WHEN 'undef' THEN
                    WHEN 'c_id', 'c_nm (-l,-cf)' THEN result_mode:= 1;
                    ELSE RAISE EXCEPTION 'Unsupported code key type: "%"!', sch_<<$app_name$>>.codekey_type(par_acodekeyl.code_key);
                END CASE;
            END IF;

            IF mod(par_determination_preference_mask >> 1, 2) = 1 THEN -- if codifier to be determined
                CASE sch_<<$app_name$>>.codekey_type(par_acodekeyl.codifier_key)
                    WHEN 'undef' THEN
                    WHEN 'c_id', 'c_nm (-l,-cf)' THEN result_mode:= result_mode + 2;
                    ELSE RAISE EXCEPTION 'Unsupported codifier key type: "%"!', sch_<<$app_name$>>.codekey_type(par_acodekeyl.codifier_key);
                END CASE;
            END IF;
            IF mod(par_determination_preference_mask >> 2, 2) = 1 THEN -- if language to be determined
                CASE sch_<<$app_name$>>.codekey_type(par_acodekeyl.key_lng)
                    WHEN 'undef' THEN
                    WHEN 'c_id', 'c_nm (-l,-cf)' THEN result_mode:= result_mode + 4;
                    ELSE RAISE EXCEPTION 'Unsupported language key type: "%"!', sch_<<$app_name$>>.codekey_type(par_acodekeyl.key_lng);
                END CASE;
            END IF;
        END IF;

        result_mode:= result_mode | par_imperative_or_mask;

        RETURN result_mode;
END;
$$;

COMMENT ON FUNCTION optimization_mode_for_acodekeyl(par_acodekeyl t_addressed_code_key_by_lng, par_determination_preference_mask integer, par_imperative_or_mask integer) IS '
Context:
1. Whenever you call "optimize_acodekeyl" with mode to determine, say, language - if language key is NULL, then function will raise exception.
2. The "acodekeyl" is considered to be optimized, whenever code ID is known.

Sometimes we don''t know, if language (or codifier) key persists, and, if it persists, even if code ID is known, we need to determine language code ID.
Due to <condext.(1)> we need a way to call "optimize_acodekeyl" with *determination preference*, instead of strict *determination mode*. Preference is less strict, comparing to mode, which is more imperative.
That''s where subject function steps in - it determines best mode for given acodekeyl and prefernce, that (mode) won''t result in exception, when applied to "optimize_acodekeyl".
Bitwise OR is applied to resulting *prefered* mode with second operand "par_imperative_or_mask".
';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION optimize_acodekeyl(par_ifexists boolean, par_acodekeyl t_addressed_code_key_by_lng, par_determination_preference_mask integer, par_imperative_or_mask integer) RETURNS t_addressed_code_key_by_lng AS $$
        SELECT sch_<<$app_name$>>.optimize_acodekeyl($1, $2, sch_<<$app_name$>>.optimization_mode_for_acodekeyl($2, $3, $4));
$$ LANGUAGE SQL;

COMMENT ON FUNCTION optimize_acodekeyl(par_ifexists boolean, par_acodekeyl t_addressed_code_key_by_lng, par_determination_preference_mask integer, par_imperative_or_mask integer) IS
'=optimize_acodekeyl($1, $2, optimization_mode_for_acodekeyl($2, $3, $4))';

-----

CREATE OR REPLACE FUNCTION optimize_acodekeyl(par_ifexists boolean, par_acodekeyl t_addressed_code_key_by_lng) RETURNS t_addressed_code_key_by_lng AS $$
        SELECT sch_<<$app_name$>>.optimize_acodekeyl($1, $2, sch_<<$app_name$>>.optimization_mode_for_acodekeyl($2, 1, 1));
$$ LANGUAGE SQL;

COMMENT ON FUNCTION optimize_acodekeyl(par_ifexists boolean, par_acodekeyl t_addressed_code_key_by_lng, par_determination_preference_mask integer, par_imperative_or_mask integer) IS
'=optimize_acodekeyl($1, $2, optimization_mode_for_acodekeyl($2, 1, 1))';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION code_id_of(par_if_exists boolean, par_acodekeyl t_addressed_code_key_by_lng) RETURNS integer
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        c_id integer:= NULL;
        srch_prfd boolean;
        cnt integer;
BEGIN
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
                   , sch_<<$app_name$>>.languages   AS c_lng
                WHERE c.code_type        != 'plain code'
                  AND c.code_id           = cn.code_id
                  AND cn.name             = ((par_acodekeyl).code_key).code_text
                  AND cn.lng_of_name      = c_lng.code_id
                  AND c_lng.code_text
                                          = ((par_acodekeyl).key_lng).code_text;
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
                   , sch_<<$app_name$>>.languages   AS c_lng
                WHERE ct.supercode_id  = ((par_acodekeyl).codifier_key).code_id
                  AND ct.subcode_id    = c_n.code_id
                  AND c_n.lng_of_name  = c_lng.code_id
                  AND c_lng.code_text
                                       = ((par_acodekeyl).key_lng).code_text
                  AND c_n.name         = ((par_acodekeyl).code_key).code_text;
            WHEN 'c_nm (+l_nm,+cf_nm)' THEN
                srch_prfd:= TRUE;

                SELECT c_n.code_id
                INTO c_id
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes_names AS cf_n
                   , sch_<<$app_name$>>.codes_names AS c_n
                   , sch_<<$app_name$>>.languages   AS c_lng
                WHERE ct.supercode_id  = cf_n.code_id
                  AND ct.subcode_id    = c_n.code_id
                  AND cf_n.lng_of_name = c_lng.code_id
                  AND c_n.lng_of_name  = c_lng.code_id
                  AND c_lng.code_text
                                       = ((par_acodekeyl).key_lng).code_text
                  AND cf_n.name        = ((par_acodekeyl).codifier_key).code_text
                  AND c_n.name         = ((par_acodekeyl).code_key).code_text;
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

        RETURN c_id;
END;
$$;

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

CREATE OR REPLACE FUNCTION code_id_of_language(lng_code_text varchar) RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE i integer;
BEGIN   SELECT code_id INTO STRICT i FROM sch_<<$app_name$>>.languages WHERE code_text = lng_code_text;
        RETURN i;
END;
$$;

CREATE OR REPLACE FUNCTION code_id_of_entity(entity_code_text varchar) RETURNS integer AS $$
        SELECT sch_<<$app_name$>>.code_id_of(FALSE, sch_<<$app_name$>>.make_acodekeyl_bystr2('Named entities', $1));
$$ LANGUAGE SQL;

COMMENT ON FUNCTION code_id_of_undefined()       IS 'code_id_of(FALSE, make_acodekeyl_bystr2(''Common nominal codes set'', ''undefined''))';
COMMENT ON FUNCTION code_id_of_unclassified()    IS 'code_id_of(FALSE, make_acodekeyl_bystr2(''Common nominal codes set'', ''unclassified''))';
COMMENT ON FUNCTION code_id_of_error()           IS 'code_id_of(FALSE, make_acodekeyl_bystr2(''Common nominal codes set'', ''error''))';
COMMENT ON FUNCTION code_id_of_ambiguous()       IS 'code_id_of(FALSE, make_acodekeyl_bystr2(''Common nominal codes set'', ''ambiguous''))';
COMMENT ON FUNCTION code_id_of_language(varchar) IS 'SELECT code_id INTO STRICT i FROM sch_<<$app_name$>>.languages WHERE code_text = lng_code_text;';
COMMENT ON FUNCTION code_id_of_entity(varchar)   IS 'code_id_of(FALSE, make_acodekeyl_bystr2(''Named entities'', $1))';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION codifier_id_of(par_if_exists boolean, par_cf_keyl t_code_key_by_lng)
RETURNS integer AS $$
        SELECT sch_<<$app_name$>>.code_id_of(
                        $1
                      , sch_<<$app_name$>>.make_acodekeyl(
                                ($2).key_lng
                              , ($2).code_key
                              , sch_<<$app_name$>>.make_codekey_null()
                      )       );
$$ LANGUAGE SQL;

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION codifier_default_code(par_if_exists boolean, par_cf_keyl t_code_key_by_lng)
RETURNS integer
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        d integer:= NULL;
        cnt integer;
BEGIN
        CASE codekeyl_type(par_cf_keyl)
            WHEN 'undef' THEN
                IF NOT par_if_exists THEN
                        RAISE EXCEPTION 'An error occurred, when trying get a default code ID for codifier %! Key must be defined.', show_codekeyl(par_cf_keyl);
                END IF;

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
                   , sch_<<$app_name$>>.languages   AS c_lng
                WHERE ct.supercode_id = cn.code_id
                  AND cn.name          = ((par_cf_keyl).code_key).code_text
                  AND cn.lng_of_name   = c_lng.code_id
                  AND c_lng.code_text
                                       = ((par_cf_keyl).key_lng).code_text
                  AND ct.dflt_subcode_isit;
            ELSE
                RAISE EXCEPTION 'An error occurred in function "codifier_default_code"! Unexpected "codekeyl_type(par_cf_keyl)" output for code key: %!', show_codekeyl(par_cf_keyl);
        END CASE;

        GET DIAGNOSTICS cnt = ROW_COUNT;

        IF cnt = 0 OR d IS NULL THEN
                IF NOT par_if_exists THEN
                        RAISE EXCEPTION 'An error occurred, when trying get a default code ID for codifier: %! Default not found.', show_codekeyl(par_cf_keyl);
                END IF;
                RETURN NULL;
        ELSIF cnt > 1 THEN
                RAISE EXCEPTION 'An error occurred, when trying get a default code ID for codifier: %! More then one default, which is illegal.', show_codekeyl(par_cf_keyl);
        END IF;

        RETURN d;
END;
$$;

COMMENT ON FUNCTION codifier_default_code(par_if_exists boolean, par_cf_key t_code_key_by_lng) IS
'For keys of type "undef" NULL is returned. It will also return NULL, if default is not found.
If first parameter is FALSE, then all cases, when NULL is to be returned, an EXCEPTION gets rised instead.
';
-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_code(par_if_exists boolean, par_key t_addressed_code_key_by_lng) RETURNS sch_<<$app_name$>>.codes
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        ccc sch_<<$app_name$>>.codes%ROWTYPE;
BEGIN
        SELECT c.*
        INTO ccc
        FROM sch_<<$app_name$>>.codes AS c
        WHERE c.code_id = code_id_of(par_if_exists, par_key);

        RETURN ccc;
END;
$$;

COMMENT ON FUNCTION get_code(par_if_exists boolean, par_acodekeyl t_addressed_code_key_by_lng) IS
'Wrapper around code_id_of(...).';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION code_belongs_to_codifier(par_if_cf_exists boolean, par_acodekeyl t_addressed_code_key_by_lng) RETURNS boolean
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        e boolean:= NULL;
        srchd boolean:= FALSE;
	cnt integer;
        __const_nom_cf_name CONSTANT varchar := 'Common nominal codes set';
        __const_undef_c_name CONSTANT varchar:= 'undefined';
BEGIN
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
                   , sch_<<$app_name$>>.languages   AS c_lng
                   , sch_<<$app_name$>>.codes_tree  AS ct_nom
                   , sch_<<$app_name$>>.codes       AS c_undef
                   , sch_<<$app_name$>>.codes       AS c_nom
                WHERE ct.supercode_id     = cf_nm.code_id
                  AND cf_nm.name          = ((par_acodekeyl).codifier_key).code_text
                  AND cf_nm.lng_of_name   = c_lng.code_id
                  AND c_lng.code_text
                                          = ((par_acodekeyl).key_lng).code_text
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
                           , sch_<<$app_name$>>.languages    AS c_lng
                        WHERE ct.supercode_id     = cf_n.code_id
                          AND ct.subcode_id       = ((par_acodekeyl).code_key).code_id
                          AND cf_n.name           = ((par_acodekeyl).codifier_key).code_text
                          AND cf_n.lng_of_name    = c_lng.code_id
                          AND c_lng.code_text
                                                  = ((par_acodekeyl).key_lng).code_text;
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
                   , sch_<<$app_name$>>.languages   AS c_lng
                WHERE ct.supercode_id  = ((par_acodekeyl).codifier_key).code_id
                  AND ct.subcode_id    = c_n.code_id
                  AND c_n.lng_of_name  = c_lng.code_id
                  AND c_lng.code_text
                                       = ((par_acodekeyl).key_lng).code_text
                  AND c_n.name         = ((par_acodekeyl).code_key).code_text;
            WHEN 'c_nm (+l_nm,+cf_nm)' THEN
                srchd:= TRUE;

                SELECT TRUE
                INTO e
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes_names AS cf_n
                   , sch_<<$app_name$>>.codes_names AS c_n
                   , sch_<<$app_name$>>.languages   AS c_lng
                WHERE ct.supercode_id  = cf_n.code_id
                  AND ct.subcode_id    = c_n.code_id
                  AND cf_n.lng_of_name = c_lng.code_id
                  AND c_n.lng_of_name  = c_lng.code_id
                  AND c_lng.code_text
                                       = ((par_acodekeyl).key_lng).code_text
                  AND cf_n.name        = ((par_acodekeyl).codifier_key).code_text
                  AND c_n.name         = ((par_acodekeyl).code_key).code_text;

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
                        RETURN FALSE;
                ELSIF cnt > 1 THEN
                        RAISE EXCEPTION 'Data inconsistecy error detected, when trying to check, if code belongs to codifier in code key %! Multiple belongings are found, but only one must have been.', show_acodekeyl(par_acodekeyl);
                ELSE
                        RETURN TRUE;
                END IF;
        ELSE
                RAISE EXCEPTION 'An error detected, when trying to check, if code belongs to codifier in code key %! Codifier not specified.', show_acodekeyl(par_acodekeyl);
        END IF;
END;
$$;

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
CREATE OR REPLACE FUNCTION get_codes_l(par_key t_code_key_by_lng) RETURNS SETOF sch_<<$app_name$>>.codes
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        ccc sch_<<$app_name$>>.codes%ROWTYPE;
BEGIN
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
                           , sch_<<$app_name$>>.languages   AS c_lng
                        WHERE c.code_id           = cn.code_id
                          AND cn.name             = ((par_key).code_key).code_text
                          AND cn.lng_of_name      = c_lng.code_id
                          AND c_lng.code_text
                                                  = ((par_key).key_lng).code_text;
            WHEN 'undef' THEN
            ELSE
                RAISE EXCEPTION 'An error occurred in function "get_codes_l"! Unexpected "codekeyl_type(par_key)" output for code key: %!', show_codekeyl(par_key);
        END CASE;

        RETURN;
END;
$$;

COMMENT ON FUNCTION get_codes_l(par_key t_code_key_by_lng) IS
'Tolerant version of "get_code(...)".
It doesn''t use "code_id_of(...)", and makes it possible to query for a set of codes (!plain or not!), that satisfy key condition.';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_codifier(par_if_exists boolean, par_key t_code_key_by_lng) RETURNS sch_<<$app_name$>>.codes
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE i integer := 0;
        ccc sch_<<$app_name$>>.codes%ROWTYPE;
BEGIN   IF par_if_exists IS NULL THEN
                RAISE EXCEPTION 'An error occurred in function "get_codifier"! Value of "par_if_exists" can''t be NULL!';
        END IF;
        FOR ccc IN
                SELECT c.*
                FROM sch_<<$app_name$>>.get_codes_l(par_key) AS c
        LOOP i:= i + 1;
             IF i > 1 THEN
                RAISE EXCEPTION 'An error occurred in function "get_codifier"! Too many (>1) results for given key %!', show_codekeyl(par_key);
             END IF;
        END LOOP;
        IF i < 1 AND NOT par_if_exists THEN
                RAISE EXCEPTION 'An error occurred in function "get_codifier"! Nothing is found by given key %!', show_codekeyl(par_key);
        END IF;
        RETURN ccc;
END;
$$;

COMMENT ON FUNCTION get_codifier(par_if_exists boolean, par_acodekeyl t_code_key_by_lng) IS
'Wrapper around get_codes_l(...) with control of size of results set.';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_nonplaincode_by_str(par_codifier varchar) RETURNS sch_<<$app_name$>>.codes
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        ccc sch_<<$app_name$>>.codes%ROWTYPE;
        cnt integer;
BEGIN
        SELECT c.*
        INTO ccc
        FROM sch_<<$app_name$>>.codes AS c
        WHERE c.code_text  = $1
          AND c.code_type != 'plain code';

        GET DIAGNOSTICS cnt = ROW_COUNT;

        IF cnt = 0 THEN
                RETURN NULL;
        ELSIF cnt > 1 THEN
                RAISE EXCEPTION 'Data inconsistecy error detected (function "get_nonplaincode_by_str"), when trying to read a codifier "%"! Multiple nonplain codes has such names (which is illegal), can not decide, which one to return.', par_codifier;
        END IF;

        RETURN ccc;
END;
$$;

COMMENT ON FUNCTION get_nonplaincode_by_str(par_codifier varchar) IS
'Returns NULL if nothing found.';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_code_by_str(par_codifier varchar, par_code varchar) RETURNS sch_<<$app_name$>>.codes
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        ccc sch_<<$app_name$>>.codes%ROWTYPE;
BEGIN
        ccc:= get_code(TRUE, make_acodekeyl_bystr2(par_codifier, par_code));
        RETURN ccc;
END;
$$;

COMMENT ON FUNCTION get_code_by_str(par_codifier varchar, par_code varchar) IS
'get_code(TRUE, make_acodekeyl_str2(par_codifier, par_code))
Returns NULL if nothing found.';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_codes_of_codifier(par_acodekeyl t_addressed_code_key_by_lng) RETURNS SETOF sch_<<$app_name$>>.codes
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        c_id integer;
BEGIN
        c_id := code_id_of(TRUE, par_acodekeyl);

        RETURN QUERY
                SELECT c.*
                FROM sch_<<$app_name$>>.codes AS c, sch_<<$app_name$>>.codes_tree AS ct
                WHERE c.code_id = ct.subcode_id
                  AND ct.supercode_id = c_id;
        RETURN;
END;
$$;

COMMENT ON FUNCTION get_codes_of_codifier(par_acodekeyl t_addressed_code_key_by_lng) IS
'Selects all subcodes from codes_tree, by supercode_id = code_id_of(TRUE,$1).';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_codifiers_of_code(par_acodekeyl t_addressed_code_key_by_lng) RETURNS SETOF sch_<<$app_name$>>.codes
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        c_id integer;
BEGIN
        c_id := code_id_of(TRUE, par_acodekeyl);

        RETURN QUERY
                SELECT c.*
                FROM sch_<<$app_name$>>.codes AS c, sch_<<$app_name$>>.codes_tree AS ct
                WHERE c.code_id = ct.supercode_id
                  AND ct.subcode_id = c_id;
        RETURN;
END;
$$;

COMMENT ON FUNCTION get_codifiers_of_code(par_acodekeyl t_addressed_code_key_by_lng) IS
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
        ) RETURNS SETOF codes_tree_node
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        max_dpth             integer;
        root_c               sch_<<$app_name$>>.codes%ROWTYPE;
        root_codes_tree_node sch_<<$app_name$>>.codes_tree_node;
        initial_scope        sch_<<$app_name$>>.codes_tree_node[];
        initial_scope_ids    integer[];
        shared_subcodes      integer[];
        excluded_subcodes    integer[];
BEGIN
        root_c:= get_code(par_if_exists, par_cf_key);
        IF root_c IS NULL THEN
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

        IF NOT par_only_ones_not_reachable_from_elsewhere THEN
                -- duplicate query under ELSE there is
                RETURN QUERY
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
                        SELECT code_id, code_text, code_type, default_ist, tree_depth, nodes_path, path_terminated_with_cycle
                        FROM subcodes
                        WHERE (tree_depth != 0 OR par_include_code_itself);
        ELSE
                -- duplicate query before ELSE there is
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
        RETURN;
END;
$$;

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

-------------------------------------------------------------------------------

CREATE TYPE t_inter_code_sign___ AS (
                code_id     integer
              , code_text   varchar
              , code_type   code_type
              );

COMMENT ON TYPE t_inter_code_sign___ IS 'For internal use.';


CREATE OR REPLACE FUNCTION find_subcodes(
          par_if_exists boolean
        , par_cf_key    t_addressed_code_key_by_lng
        , par_in_scope_of_cf_key  t_code_key_by_lng
        , par_include_code_itself
                        boolean
        , par_only_ones_not_reachable_from_elsewhere
                        boolean
        ) RETURNS SETOF codes_tree_node
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        max_dpth             integer;
        root_c               sch_<<$app_name$>>.codes%ROWTYPE;
        root_codes_tree_node sch_<<$app_name$>>.codes_tree_node;
        initial_scope        sch_<<$app_name$>>.codes_tree_node[];
        initial_scope_ids    integer[];
        shared_subcodes      integer[];
        excluded_subcodes    integer[];
        scope_c_id           integer;
        under_scope_c        sch_<<$app_name$>>.t_inter_code_sign___[];
BEGIN
        scope_c_id:= codifier_id_of(par_if_exists, par_in_scope_of_cf_key);
        root_c:= get_code(par_if_exists, par_cf_key);
        IF root_c IS NULL OR scope_c_id IS NULL THEN
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

        under_scope_c:= ARRAY(
                SELECT c.code_id, c.code_text, c.code_type
                FROM sch_<<$app_name$>>.codes_tree AS ct, sch_<<$app_name$>>.codes AS c
                WHERE ct.supercode_id = scope_c_id
                  AND ct.subcode_id = c.code_id
        );

        IF par_include_code_itself THEN
            IF root_c.code_id IN (SELECT c.code_id FROM unnest(under_scope_c)) IS DISTINCT FROM TRUE THEN
                RETURN;
        END IF; END IF;

        IF NOT par_only_ones_not_reachable_from_elsewhere THEN
                RETURN QUERY
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
                               , unnest(under_scope_c)         AS  c
                               , subcodes AS sc
                            WHERE NOT path_terminated_with_cycle
                              AND ct.supercode_id = sc.code_id
                              AND c.code_id = ct.subcode_id
                        )
                        SELECT code_id, code_text, code_type, default_ist, tree_depth, nodes_path, path_terminated_with_cycle
                        FROM subcodes
                        WHERE (tree_depth != 0 OR par_include_code_itself);
        ELSE
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
                               , unnest(under_scope_c)         AS  c
                               , subcodes AS sc
                            WHERE NOT path_terminated_with_cycle
                              AND ct.supercode_id = sc.code_id
                              AND c.code_id = ct.subcode_id
                        )
                        SELECT ROW(code_id, code_text, code_type, default_ist, tree_depth, nodes_path, path_terminated_with_cycle) :: codes_tree_node
                        FROM subcodes
                        WHERE (tree_depth != 0 OR par_include_code_itself)
                );

                initial_scope_ids:= ARRAY(
                        SELECT DISTINCT code_id
                        FROM unnest(initial_scope) AS x
                        );
                shared_subcodes := ARRAY(
                        SELECT DISTINCT subcode_id
                        FROM sch_<<$app_name$>>.codes_tree
                        WHERE     initial_scope_ids @> ARRAY[subcode_id]
                          AND NOT initial_scope_ids @> ARRAY[supercode_id]
                          AND     supercode_id != scope_c_id
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
        RETURN;
END;
$$;

COMMENT ON FUNCTION find_subcodes(
          par_if_exists boolean
        , par_cf_key    t_addressed_code_key_by_lng
        , par_in_scope_of_cf_key  t_code_key_by_lng
        , par_include_code_itself
                        boolean
        , par_only_ones_not_reachable_from_elsewhere
                        boolean
        ) IS
'Specific extension of "find_subcodes" function. Here all results must belong to codifier addressed by the "par_in_scope_of_cf_key" parameter.
If "par_in_scope_of_cf_key" addresses no codifier, results set is empty.
If "par_in_scope_of_cf_key" is found during the search, it is not included in results and search won''continue for this subbranch.
If "par_include_code_itself" IS TRUE and code addressed by "par_cf_key" doesn''t belong to scope codifier, then resulting set is empty.
The behavior associated with "par_only_ones_not_reachable_from_elsewhere" now ignores "par_in_scope_of_cf_key" (it doesn''t belong to "elswhere").

';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION find_supercodes(
          par_if_exists boolean
        , par_c_key     t_addressed_code_key_by_lng
        , par_in_scope_of_cf_key
                        t_code_key_by_lng
        , par_include_code_itself
                        boolean
        , par_only_ones_not_reachable_from_elsewhere
                        boolean
        ) RETURNS SETOF codes_tree_node
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        max_dpth             integer;
        root_c               sch_<<$app_name$>>.codes%ROWTYPE;
        root_codes_tree_node sch_<<$app_name$>>.codes_tree_node;
        initial_scope        sch_<<$app_name$>>.codes_tree_node[];
        initial_scope_ids    integer[];
        shared_subcodes      integer[];
        excluded_subcodes    integer[];
        scope_c_id           integer;
        under_scope_c        sch_<<$app_name$>>.t_inter_code_sign___[];
BEGIN
        scope_c_id:= codifier_id_of(par_if_exists, par_in_scope_of_cf_key);
        root_c:= get_code(par_if_exists, par_cf_key);
        IF root_c IS NULL OR scope_c_id IS NULL THEN
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

        under_scope_c:= ARRAY(
                SELECT c.code_id, c.code_text, c.code_type
                FROM sch_<<$app_name$>>.codes_tree AS ct, sch_<<$app_name$>>.codes AS c
                WHERE ct.supercode_id = scope_c_id
                  AND ct.subcode_id = c.code_id
        );

        IF par_include_code_itself THEN
            IF root_c.code_id IN (SELECT c.code_id FROM unnest(under_scope_c)) IS DISTINCT FROM TRUE THEN
                RETURN;
        END IF; END IF;

        IF NOT par_only_ones_not_reachable_from_elsewhere THEN
                RETURN QUERY
                        WITH RECURSIVE supercodes(code_id, code_text, code_type, default_ist, tree_depth, nodes_path, path_terminated_with_cycle) AS (
                            SELECT root_codes_tree_node.*
                          UNION ALL
                            SELECT ct.supercode_id                AS code_id
                                 , c.code_text                    AS code_text
                                 , c.code_type                    AS code_type
                                 , ct.dflt_subcode_isit           AS default_ist
                                 , sc.tree_depth - 1              AS tree_depth
                                 , sc.nodes_path || ct.supercode_id        AS nodes_path
                                 , sc.nodes_path @> ARRAY[ct.supercode_id] AS path_terminated_with_cycle
                            FROM sch_<<$app_name$>>.codes_tree AS ct
                               , unnest(under_scope_c)         AS  c
                               , supercodes AS sc
                            WHERE NOT path_terminated_with_cycle
                              AND ct.subcode_id = sc.code_id
                              AND c.code_id = ct.supercode_id
                              AND ct.supercode_id != scope_c_id
                        )
                        SELECT code_id, code_text, code_type, default_ist, tree_depth, nodes_path, path_terminated_with_cycle
                        FROM supercodes
                        WHERE (tree_depth != 0 OR par_include_code_itself);
        ELSE
                initial_scope:= ARRAY(
                        WITH RECURSIVE supercodes(code_id, code_text, code_type, default_ist, tree_depth, nodes_path, path_terminated_with_cycle) AS (
                            SELECT root_codes_tree_node.*
                          UNION ALL
                            SELECT ct.supercode_id                AS code_id
                                 , c.code_text                    AS code_text
                                 , c.code_type                    AS code_type
                                 , ct.dflt_subcode_isit           AS default_ist
                                 , sc.tree_depth - 1              AS tree_depth
                                 , sc.nodes_path || ct.supercode_id        AS nodes_path
                                 , sc.nodes_path @> ARRAY[ct.supercode_id] AS path_terminated_with_cycle
                            FROM sch_<<$app_name$>>.codes_tree AS ct
                               , unnest(under_scope_c)         AS  c
                               , supercodes AS sc
                            WHERE NOT path_terminated_with_cycle
                              AND ct.subcode_id = sc.code_id
                              AND c.code_id = ct.supercode_id
                              AND ct.supercode_id != scope_c_id
                        )
                        SELECT ROW(code_id, code_text, code_type, default_ist, tree_depth, nodes_path, path_terminated_with_cycle) :: codes_tree_node
                        FROM supercodes
                        WHERE (tree_depth != 0 OR par_include_code_itself)
                );

                initial_scope_ids:= ARRAY(
                        SELECT DISTINCT code_id
                        FROM unnest(initial_scope) AS x
                        );
                shared_subcodes := ARRAY(
                        SELECT DISTINCT subcode_id
                        FROM sch_<<$app_name$>>.codes_tree
                        WHERE     initial_scope_ids @> ARRAY[subcode_id]
                          AND NOT initial_scope_ids @> ARRAY[supercode_id]
                          AND     supercode_id != scope_c_id
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
        RETURN;
END;
$$;

COMMENT ON FUNCTION find_supercodes(
          par_if_exists boolean
        , par_c_key     t_addressed_code_key_by_lng
        , par_in_scope_of_cf_key  t_code_key_by_lng
        , par_include_code_itself
                        boolean
        , par_only_ones_not_reachable_from_elsewhere
                        boolean
        ) IS
'Specific modification of "find_subcodes" function. Here search is performed in opposite direction, and all results must belong to codifier addressed by the "par_in_scope_of_cf_key" parameter.
If "par_in_scope_of_cf_key" addresses no codifier, results set is empty.
The search for the supercodes won''t consider "par_in_scope_of_cf_key" as includable in results set, and, thus, won''t include anything superer than that.
The behavior associated with "par_only_ones_not_reachable_from_elsewhere" now ignores "par_in_scope_of_cf_key" (it doesn''t belong to "elswhere").
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
      ) RETURNS integer
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        cnt integer;
        find_results integer[];
        c_id integer;
BEGIN
        IF NOT par_cascade_remove_subcodes THEN
                IF par_remove_code THEN
                        c_id := code_id_of(TRUE, par_acodekeyl);

                        DELETE FROM sch_<<$app_name$>>.codes WHERE code_id = c_id;

                        GET DIAGNOSTICS cnt = ROW_COUNT;

                        RETURN cnt;
                ELSE
                        RETURN 0;
                END IF;
        ELSE
                find_results:= ARRAY(
                        SELECT DISTINCT code_id
                        FROM find_subcodes(par_if_exists, par_acodekeyl, par_remove_code, par_if_cascade__only_ones_not_reachable_from_elsewhere)
                        );

                DELETE FROM sch_<<$app_name$>>.codes WHERE find_results @> ARRAY[code_id];

                GET DIAGNOSTICS cnt = ROW_COUNT;

                RETURN cnt;
        END IF;
END;
$$;

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
        ) RETURNS integer
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        c_id  integer;
        cf_id integer;
        cnt   integer;
BEGIN
        c_id:=  code_id_of(FALSE,                     par_c_acodekeyl );
        cf_id:= code_id_of(FALSE, generalize_codekeyl(par_cf_codekeyl));

        INSERT INTO sch_<<$app_name$>>.codes_tree (supercode_id, subcode_id, dflt_subcode_isit)
        VALUES (cf_id, c_id, COALESCE(par_dflt, FALSE));

        GET DIAGNOSTICS cnt = ROW_COUNT;

        RETURN cnt;
END;
$$;

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
        ) RETURNS integer
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        c_id  integer;
        cf_id integer;
        cnt integer:= 0;
BEGIN
        c_id:=  code_id_of(par_if_exists, par_c_acodekeyl);
        cf_id:= code_id_of(par_if_exists, generalize_codekeyl(make_codekeyl(par_c_acodekeyl.key_lng, par_c_acodekeyl.codifier_key)));

        DELETE FROM sch_<<$app_name$>>.codes_tree WHERE supercode_id = cf_id AND subcode_id = c_id;

        GET DIAGNOSTICS cnt = ROW_COUNT;

        IF (cnt IS NULL OR cnt != 1) AND (NOT par_if_exists) THEN
                RAISE EXCEPTION 'An error occurred, when trying to unbind code %! Bad count (%) of rows modified.', show_acodekeyl(par_c_acodekeyl), cnt;
        END IF;

        RETURN cnt;
END;
$$;

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
        ) RETURNS integer
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        cnt1 integer;
        cnt2 integer;
        c_id integer;
BEGIN
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

        RETURN c_id;
END;
$$;

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
        ) RETURNS integer
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        c_id integer;
BEGIN
        c_id := new_code_by_userseqs(par_code_construct, par_super_code, par_dflt_isit, 'sch_<<$app_name$>>.codifiers_ids_seq', 'sch_<<$app_name$>>.plain_codes_ids_seq');

        RETURN c_id;
END;
$$;

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
        ) RETURNS integer[]
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        dflt_correct boolean;
        i integer;
        cf_id integer;
        c_ids_arr integer[];
BEGIN
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

        RETURN c_ids_arr;
END;
$$;

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
RETURNS result_of_making_new_codifier_w_subcodes
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        r sch_<<$app_name$>>.result_of_making_new_codifier_w_subcodes;
BEGIN
        SELECT code_id INTO r.codifier_id
        FROM unnest(add_subcodes_under_codifier(par_super_cf, NULL :: varchar, VARIADIC ARRAY[par_cf_construct])) AS re(code_id);

        r.subcodes_ids_list:= add_subcodes_under_codifier(
                                        make_codekeyl_byid(r.codifier_id)
                                      , par_cf_dflt_codestr
                                      , VARIADIC par_codes_array
                                      );

        RETURN r;
END;
$$;

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
RETURNS integer
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        cf_id integer:= NULL;
        cnt integer;
        c sch_<<$app_name$>>.codes%ROWTYPE;
BEGIN
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

        RETURN cf_id;
END;
$$;

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
RETURNS result_of_making_new_codifier_w_subcodes
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        r sch_<<$app_name$>>.result_of_making_new_codifier_w_subcodes;
BEGIN
        r.codifier_id:= make_codifier_from_plaincode(par_if_exists, par_reidentify, par_c, VARIADIC par_cf_new_type);

        r.subcodes_ids_list:= add_subcodes_under_codifier(make_codekeyl_byid(r.codifier_id), par_cf_dflt_codestr, VARIADIC par_codes_array);

        RETURN r;
END;
$$;

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
$$ LANGUAGE SQL IMMUTABLE;

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION add_code_lng_names(
          par_if_exists boolean
        , par_c         t_addressed_code_key_by_lng
        , VARIADIC par_codesnames_array
                        name_construction_input[]
        )
RETURNS integer
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE
        cnt1 integer;
        cnt2 integer;
        c_id integer;
        dflt_lng_c_id integer;
BEGIN
        c_id := code_id_of(par_if_exists, par_c);

        IF c_id IS NULL THEN
                IF NOT par_if_exists THEN
                        RAISE EXCEPTION 'An error occurred, in the function "add_code_lng_names", for code %! Can''t determine target code ID.', show_acodekeyl(par_c);
                END IF;

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
                                              , generalize_codekeyl_wcf(make_codekey_bystr('Languages'), inp.lng)
                                              )
                                  ELSE dflt_lng_c_id
                             END AS lng_of_name
                           , inp.name
                           , code_id_of( FALSE
                                       , generalize_codekeyl_wcf(make_codekey_bystr('Named entities'), inp.lng)
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
                                              , generalize_codekeyl_wcf(make_codekey_bystr('Languages'), inp.lng)
                                              )
                                  ELSE dflt_lng_c_id
                             END AS lng_of_name
                           , inp.name
                           , inp.description
                      FROM unnest(par_codesnames_array) AS inp
                      WHERE codekeyl_type(inp.entity) = 'undef'
                      ) AS v;

                GET DIAGNOSTICS cnt2 = ROW_COUNT;

                RETURN (cnt1 + cnt2);
        END IF;
END;
$$;

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

-- Referencing functions:

GRANT EXECUTE ON FUNCTION make_codekey(par_code_id integer, par_code_text varchar) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_codekey_null() TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_codekey_byid(par_code_id integer) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_codekey_bystr(par_code_text varchar) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_acodekey(par_cf_key t_code_key, par_c_key t_code_key) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_acodekey_null() TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_codekeyl(par_key_lng t_code_key, par_code_key t_code_key) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_codekeyl_null() TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_codekeyl_byid(par_code_id integer) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_codekeyl_bystr(par_code_text varchar) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_codekeyl_bystrl(par_lng_key t_code_key, par_code_text varchar) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_acodekeyl(par_key_lng t_code_key, par_cf_key t_code_key, par_c_key t_code_key) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_acodekeyl_null() TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_acodekeyl_byid(par_code_id integer) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_acodekeyl_bystr1(par_code_text varchar) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_acodekeyl_bystr2(par_codifier_text varchar, par_code_text varchar) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION optimized_codekey_isit(par_codekey t_code_key) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION optimized_acodekey_isit(par_acodekey t_addressed_code_key, par_opt_mask integer) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION optimized_codekeyl_isit(par_codekeyl t_code_key_by_lng, par_opt_mask integer) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION optimized_acodekeyl_isit(par_acodekeyl t_addressed_code_key_by_lng, par_opt_mask integer) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION show_codekey(par_key t_code_key) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION show_acodekey(par_key t_addressed_code_key) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION show_codekeyl(par_key t_code_key_by_lng) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION show_acodekeyl(par_key t_addressed_code_key_by_lng) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION generalize_codekey(par_key t_code_key) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION generalize_codekey_ascf(par_key t_code_key) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION generalize_codekeyl(par_key t_code_key_by_lng) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION generalize_codekeyl_ascf(par_key t_code_key_by_lng) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION generalize_acodekey(par_key t_addressed_code_key) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION generalize_codekey_wcf(par_cf_codekey t_code_key, par_key t_code_key) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION generalize_codekeyl_wcf(par_cf_codekey t_code_key, par_key t_code_key_by_lng) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION codekey_type(par_key t_code_key) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION acodekey_type(par_key t_addressed_code_key) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION codekeyl_type(par_key t_code_key_by_lng) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION acodekeyl_type(par_key t_addressed_code_key_by_lng) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION mk_name_construction_input(par_lng t_code_key_by_lng, par_name varchar, par_entity t_code_key_by_lng, par_description varchar) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;


-- Lookup functions:

GRANT EXECUTE ON FUNCTION optimize_acodekeyl(par_ifexists boolean, par_acodekeyl t_addressed_code_key_by_lng, par_determine_mask integer) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION optimization_mode_for_acodekeyl(par_acodekeyl t_addressed_code_key_by_lng, par_determination_preference_mask integer, par_imperative_or_mask integer) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION optimize_acodekeyl(par_ifexists boolean, par_acodekeyl t_addressed_code_key_by_lng, par_determination_preference_mask integer, par_imperative_or_mask integer) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION optimize_acodekeyl(par_ifexists boolean, par_acodekeyl t_addressed_code_key_by_lng) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION code_id_of(par_if_exists boolean, par_acodekeyl t_addressed_code_key_by_lng) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION code_id_of_undefined() TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION code_id_of_unclassified() TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION code_id_of_error() TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION code_id_of_ambiguous() TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION code_id_of_language(varchar) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION code_id_of_entity(entity_code_text varchar) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION codifier_id_of(par_if_exists boolean, par_cf_keyl t_code_key_by_lng) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION code_belongs_to_codifier(par_if_cf_exists boolean, par_acodekeyl t_addressed_code_key_by_lng) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_code(par_if_exists boolean, par_key t_addressed_code_key_by_lng) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION codifier_default_code(par_if_exists boolean, par_cf_keyl t_code_key_by_lng) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_codes_l(par_key t_code_key_by_lng) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_codifier(par_if_exists boolean, par_acodekeyl t_code_key_by_lng) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_nonplaincode_by_str(par_codifier varchar) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_code_by_str(par_codifier varchar, par_code varchar) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_codes_of_codifier(par_acodekeyl t_addressed_code_key_by_lng) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_codifiers_of_code(par_acodekeyl t_addressed_code_key_by_lng) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION find_subcodes(par_if_exists boolean, par_cf_key t_addressed_code_key_by_lng, par_include_code_itself boolean, par_only_ones_not_reachable_from_elsewhere boolean) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION find_subcodes(
          par_if_exists boolean
        , par_cf_key    t_addressed_code_key_by_lng
        , par_in_scope_of_cf_key  t_code_key_by_lng
        , par_include_code_itself
                        boolean
        , par_only_ones_not_reachable_from_elsewhere
                        boolean
        ) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION find_supercodes(
          par_if_exists boolean
        , par_c_key     t_addressed_code_key_by_lng
        , par_in_scope_of_cf_key
                        t_code_key_by_lng
        , par_include_code_itself
                        boolean
        , par_only_ones_not_reachable_from_elsewhere
                        boolean
        ) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin, user_db<<$db_name$>>_app<<$app_name$>>_data_reader;


-- Administration functions:

GRANT EXECUTE ON FUNCTION remove_code(par_if_exists boolean, par_acodekeyl t_addressed_code_key_by_lng, par_remove_code boolean, par_cascade_remove_subcodes boolean, par_if_cascade__only_ones_not_reachable_from_elsewhere boolean)  TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION bind_code_to_codifier(par_c_acodekeyl t_addressed_code_key_by_lng, par_cf_codekeyl t_code_key_by_lng, par_dflt boolean)  TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION unbind_code_from_codifier(par_if_exists boolean, par_c_acodekeyl t_addressed_code_key_by_lng)  TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION new_code_by_userseqs(par_code_construct code_construction_input, par_super_code t_code_key_by_lng, par_dflt_isit boolean, par_codifier_ids_seq_name varchar, par_plaincode_ids_seq_name varchar)  TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION new_code(par_code_construct code_construction_input, par_super_code t_code_key_by_lng, par_dflt_isit boolean)  TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION add_subcodes_under_codifier(par_cf t_code_key_by_lng, par_cf_dflt_codestr varchar, VARIADIC par_codes_array code_construction_input[])  TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION new_codifier_w_subcodes(par_super_cf t_code_key_by_lng, par_cf_construct code_construction_input, par_cf_dflt_codestr varchar, VARIADIC par_codes_array code_construction_input[])  TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION make_codifier_from_plaincode(par_if_exists boolean, par_reidentify boolean, par_cf t_code_key_by_lng, par_cf_new_type code_type)  TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION make_codifier_from_plaincode_w_values(par_if_exists boolean, par_reidentify boolean, par_c t_code_key_by_lng, par_cf_new_type code_type, par_cf_dflt_codestr varchar, VARIADIC par_codes_array code_construction_input[])  TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION add_code_lng_names(par_if_exists boolean, par_c t_addressed_code_key_by_lng, VARIADIC par_codesnames_array name_construction_input[])  TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> functions.init.sql [END]

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\i modules/cf_dedictbls.init.sql
