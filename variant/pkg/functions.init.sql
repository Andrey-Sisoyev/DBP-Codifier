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

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

CREATE TYPE t_code_key                  AS (code_id integer, code_text varchar);
CREATE TYPE t_addressed_code_key        AS (codifier_key t_code_key, code_key t_code_key);
CREATE TYPE t_code_key_by_lng           AS (key_lng code_key,                          code_key t_code_key);
CREATE TYPE t_addressed_code_key_by_lng AS (key_lng code_key, codifier_key t_code_key, code_key t_code_key);

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
From another point of view, an extension of t_addressed_code_key - if lng_key is NULL, then t_addressed_code_key_by_lng is theated as t_addressed_code_key.
Since t_addressed_code_key_by_lng is able to simulate all simplier code_key types, it is used everywhere in the API.
';

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION make_codekey_null() RETURNS t_code_key AS $$
        SELECT NULL :: t_code_key;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION make_codekey_byid(par_code_id integer) RETURNS t_code_key AS $$ 
        SELECT ROW(par_code_id, NULL :: varchar) :: t_code_key;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION make_codekey_bystr(par_code_text varchar) RETURNS t_code_key AS $$
        SELECT ROW(NULL :: integer, par_code_text) :: t_code_key;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION make_acodekey_null() RETURNS t_addressed_code_key AS $$
        SELECT NULL :: t_addressed_code_key;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION make_acodekey(par_cf_key t_code_key, par_c_key t_code_key) RETURNS t_addressed_code_key AS $$
DECLARE r t_addressed_code_key; BEGIN r.codifier_key:= par_cf_key; r.code_key:= par_c_key; RETURN r; END; 
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION make_codekeyl(par_key_lng t_code_key, par_code_key t_code_key) RETURNS t_code_key_by_lng AS $$ 
DECLARE r t_code_key_by_lng; BEGIN r.key_lng:= par_key_lng; r.code_key:= par_code_key; RETURN r; END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION make_codekeyl_null() RETURNS t_code_key_by_lng AS $$
        SELECT NULL :: t_code_key_by_lng;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION make_codekeyl_byid(par_code_id integer) RETURNS t_code_key_by_lng AS $$ 
        SELECT make_codekeyl(NULL :: t_code_key, make_codekey_byid(par_code_id));
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION make_codekeyl_bystr(par_code_text varchar) RETURNS t_code_key_by_lng AS $$
        SELECT make_codekeyl(make_codekey_null(), make_codekey_bystr(par_code_text));
$$ LANGUAGE SQL;
CREATE OR REPLACE FUNCTION make_codekeyl_bystrl(par_lng_key t_code_key, par_code_text varchar) RETURNS t_code_key_by_lng AS $$
        SELECT make_codekeyl(par_lng_key, make_codekey_bystr(par_code_text));
$$ LANGUAGE SQL;

------------------

CREATE OR REPLACE FUNCTION make_acodekeyl_null() RETURNS t_addressed_code_key_by_lng AS $$
        SELECT NULL :: t_addressed_code_key_by_lng;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION make_acodekeyl(par_key_lng t_code_key, par_cf_key t_code_key, par_c_key t_code_key) RETURNS t_addressed_code_key_by_lng AS $$
DECLARE r t_addressed_code_key_by_lng; BEGIN r.key_lng:= par_key_lng; r.codifier_key:= par_cf_key; r.code_key:= par_c_key; RETURN r; END; 
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION make_acodekeyl_byid(par_code_id integer) RETURNS t_addressed_code_key_by_lng AS $$
        SELECT make_acodekeyl(NULL :: t_code_key, make_codekey_byid(par_code_id), NULL :: t_code_key);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION make_acodekeyl_bystr1(par_code_text varchar) RETURNS t_addressed_code_key_by_lng AS $$
        SELECT make_acodekeyl(NULL :: t_code_key, NULL :: t_code_key, make_codekey_bystr(par_code_text));
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION make_acodekeyl_bystr2(par_codifier_text varchar, par_code_text varchar) RETURNS t_addressed_code_key_by_lng AS $$
        SELECT make_acodekeyl(NULL :: t_code_key, make_codekey_bystr(par_codifier_text), make_codekey_bystr(par_code_text));
$$ LANGUAGE SQL;

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION show_codekey(par_key t_code_key) RETURNS varchar AS $$
        SELECT '{t_code_key | code_id: ' || COALESCE(par_key.code_id, 'NULL') || '; code_text: ' || COALESCE('"' || par_key.code_text || '"', 'NULL') || '}';
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION show_acodekey(par_key t_addressed_code_key) RETURNS varchar AS $$
        SELECT '{t_addressed_code_key | codifier_key: ' || COALESCE(show_codekey(par_key.codifier_key), 'NULL') || '; code_key: ' || COALESCE(show_codekey(par_key.code_key), 'NULL') || '}';
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION show_codekeyl(par_key t_code_key_by_lng) RETURNS varchar AS $$
        SELECT '{t_code_key_by_lng | key_lng: ' || COALESCE(show_codekey(par_key.key_lng), 'NULL') || '; code_key: ' || COALESCE(show_codekey(par_key.code_key), 'NULL') || '}';
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION show_acodekeyl(par_key t_addressed_code_key_by_lng) RETURNS varchar AS $$
        SELECT '{t_addressed_code_key_by_lng | key_lng: ' || COALESCE(show_codekey(par_key.key_lng), 'NULL') || '; codifier_key: ' || COALESCE(show_codekey(par_key.codifier_key), 'NULL') || '; code_key: ' || COALESCE(show_codekey(par_key.code_key), 'NULL') || '}';
$$ LANGUAGE SQL;

--------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION generalize_codekey(par_key t_code_key) RETURNS t_addressed_code_key_by_lng AS $$
        SELECT make_acodekeyl(NULL :: t_code_key, NULL :: t_code_key, par_key);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION generalize_codekeyl(par_key t_code_key_by_lng) RETURNS t_addressed_code_key_by_lng AS $$
        SELECT make_acodekeyl(par_key.lng_key, NULL :: t_code_key, par_key.code_key);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION generalize_acodekey(par_key t_addressed_code_key) RETURNS t_addressed_code_key_by_lng AS $$
        SELECT make_acodekeyl(NULL :: t_code_key, par_key.codifier_key, par_key.code_key);
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
        ct t_code_key_type;
BEGIN 
        IF par_key IS NULL THEN
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
        ct  t_code_key_type;
        ct2 t_code_key_type;
        ct3 t_code_key_type;
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
                                ct:= 'cf_nm (-l)';
                        ELSIF ct3 = 'undef' THEN
                                ct:= ct3;
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
                                ct:= ct3;
                        ELSE 
                                RAISE EXCEPTION 'An error occurred in function "acodekey_type"! Unexpected "codekey_type(par_key.codifier_key)" output!';
                        END IF;                
                ELSE
                        RAISE EXCEPTION 'An error occurred in function "acodekey_type"! Unexpected "codekey_type(par_key.code_key)" output!';
                END IF;
        END IF;
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
        ct  t_code_key_type;
        ct2 t_code_key_type;
        ct3 t_code_key_type;
BEGIN 
        IF par_key IS NULL THEN
                ct:= 'undef';
        ELSE
                ct2:= codekey_type(par_key.code_key);

                IF ct2 = 'c_id' THEN
                        ct:= ct2;
                ELSIF ct2 = 'c_nm (-l,-cf)' THEN
                        ct3:= codekey_type(par_key.lng_key);

                        IF ct3 = 'c_id' THEN
                                ct:= 'c_nm (+l_id,-cf)';
                        ELSIF ct3 = 'c_nm (-l,-cf)' THEN
                                ct:= 'c_nm (+l_nm,-cf)';
                        ELSIF ct3 = 'undef' THEN
                                ct:= ct2;
                        ELSE
                                RAISE EXCEPTION 'An error occurred in function "codekeyl_type"! Unexpected "codekey_type(par_key.lng_key)" output!';
                        END IF;
                ELSIF ct2 = 'undef' THEN
                        ct:= ct2;
                ELSE
                        RAISE EXCEPTION 'An error occurred in function "codekeyl_type"! Unexpected "codekey_type(par_key.code_key)" output!';
                END IF;
        END IF;
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
        ct  t_code_key_type;
        ct2 t_code_key_type;
        ct3 t_code_key_type;
        ct4 t_code_key_type;
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
                                ct4:= codekey_type(par_key.lng_key);

                                IF ct4 = 'c_id' THEN
                                        ct:= 'cf_nm (+l_id)';
                                ELSIF ct4 = 'c_nm (-l,-cf)' THEN
                                        ct:= 'cf_nm (+l_nm)';
                                ELSIF ct4 = 'undef' THEN
                                        ct:= 'cf_nm (-l)';
                                ELSE
                                        RAISE EXCEPTION 'An error occurred in function "acodekeyl_type"! Unexpected "codekey_type(par_key.lng_key)" output!';
                                END IF;
                        ELSIF ct3 = 'undef' THEN
                                ct:= ct3;
                        ELSE 
                                RAISE EXCEPTION 'An error occurred in function "acodekey_type"! Unexpected "codekey_type(par_key.codifier_key)" output!';
                        END IF;
                ELSIF ct2 = 'c_nm (-l,-cf)' THEN
                        ct3:= codekey_type(par_key.codifier_key);
                        ct4:= codekey_type(par_key.lng_key);

                        IF ct3 = 'c_id' THEN
                                IF ct4 = 'c_id' THEN
                                        ct:= 'c_nm (+l_id,+cf_id)';
                                ELSIF ct3 = 'c_nm (-l,-cf)' THEN
                                        ct:= 'c_nm (+l_nm,+cf_id)';
                                ELSIF ct3 = 'undef' THEN
                                        ct:= 'c_nm (-l,+cf_id)';
                                ELSE
                                        RAISE EXCEPTION 'An error occurred in function "acodekeyl_type"! Unexpected "codekey_type(par_key.lng_key)" output!';
                                END IF;
                        ELSIF ct3 = 'c_nm (-l,-cf)' THEN
                                IF ct4 = 'c_id' THEN
                                        ct:= 'c_nm (+l_id,+cf_nm)';
                                ELSIF ct3 = 'c_nm (-l,-cf)' THEN
                                        ct:= 'c_nm (+l_nm,+cf_nm)';
                                ELSIF ct3 = 'undef' THEN
                                        ct:= 'c_nm (-l,+cf_nm)';
                                ELSE
                                        RAISE EXCEPTION 'An error occurred in function "acodekeyl_type"! Unexpected "codekey_type(par_key.lng_key)" output!';
                                END IF;                        
                        ELSIF ct3 = 'undef' THEN
                                IF ct4 = 'c_id' THEN
                                        ct:= 'c_nm (+l_id,-cf)';
                                ELSIF ct3 = 'c_nm (-l,-cf)' THEN
                                        ct:= 'c_nm (+l_nm,-cf)';
                                ELSIF ct3 = 'undef' THEN
                                        ct:= 'c_nm (-l,-cf)';
                                ELSE
                                        RAISE EXCEPTION 'An error occurred in function "acodekeyl_type"! Unexpected "codekey_type(par_key.lng_key)" output!';
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

CREATE OR REPLACE FUNCTION code_id_of(par_if_exists boolean, par_acodekeyl t_addressed_code_key_by_lng) RETURNS integer AS $$
DECLARE
        c_id integer:= NULL;
        srch_prfd boolean;
        cnt integer;
BEGIN
        srch_prfd:= FALSE;
        cnt:= 0;
        CASE acodekeyl_type(par_acodekeyl)
            WHEN 'undef', 'cf_id', 'cf_nm (-l)', 'cf_nm (+l_id)', 'cf_nm (+l_nm)' THEN
                srch_prfd:= FALSE;
                c_id:= NULL;
                cnt:= 0;
            WHEN 'c_id' THEN
                srch_prfd:= FALSE;
                c_id:= par_acodekeyl.code_key.code_id;
                cnt:= 1;
            WHEN 'c_nm (-l,-cf)' THEN
                srch_prfd:= TRUE;

                SELECT c.code_id
                INTO c_id
                FROM sch_<<$app_name$>>.codes AS c
                WHERE c.code_type != 'plain code'
                  AND c.code_text  = par_acodekeyl.code_key.code_text;
            WHEN 'c_nm (+l_id,-cf)' THEN
                srch_prfd:= TRUE;

                SELECT c.code_id
                INTO c_id
                FROM sch_<<$app_name$>>.codes       AS c
                   , sch_<<$app_name$>>.codes_names AS cn
                WHERE c.code_type   != 'plain code'
                  AND c.code_id      = cn.code_id
                  AND cn.name        = par_acodekeyl.code_key.code_text
                  AND cn.lng_of_name = par_acodekeyl.lng_key.code_id;
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
                  AND cn.name             = par_acodekeyl.code_key.code_text
                  AND cn.lng_of_name      = c_lng.code_id
                  AND c_lng.code_text     = par_acodekeyl.lng_key.code_text
                  AND c_lng_ct.subcode_id = c_lng.code_id
                  AND c_lng_ct.supercode_id = c_lng_cf.code_id
                  AND c_lng_cf.code_text  = 'Languages';
            WHEN 'c_nm (-l,+cf_id)' THEN
                srch_prfd:= TRUE;

                SELECT c.code_id
                INTO c_id
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes_names AS c
                WHERE ct.supercode_id  = par_acodekeyl.codifier_key.code_id
                  AND ct.subcode_id    = c.code_id
                  AND c.code_text      = par_acodekeyl.code_key.code_text;
            WHEN 'c_nm (-l,+cf_nm)' THEN
                srch_prfd:= TRUE;

                SELECT c.code_id
                INTO c_id
                FROM sch_<<$app_name$>>.codes_tree AS ct
                   , sch_<<$app_name$>>.codes      AS cf
                   , sch_<<$app_name$>>.codes      AS c
                WHERE ct.supercode_id = cf.code_id
                  AND ct.subcode_id   = c.code_id
                  AND cf.code_text    = par_acodekeyl.codifier_key.code_text
                  AND c.code_text     = par_acodekeyl.code_key.code_text;
            WHEN 'c_nm (+l_id,+cf_id)' THEN
                srch_prfd:= TRUE;

                SELECT c_n.code_id
                INTO c_id
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes_names AS c_n
                WHERE ct.supercode_id  = par_acodekeyl.codifier_key.code_id
                  AND ct.subcode_id    = c_n.code_id
                  AND c_n.lng_of_name  = par_acodekeyl.lng_key.code_id 
                  AND c_n.name         = par_acodekeyl.code_key.code_text;
            WHEN 'c_nm (+l_id,+cf_nm)' THEN
                srch_prfd:= TRUE;

                SELECT c_n.code_id
                INTO c_id
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes_names AS cf_n
                   , sch_<<$app_name$>>.codes_names AS c_n
                WHERE ct.supercode_id  = cf_n.code_id
                  AND ct.subcode_id    = c_n.code_id
                  AND cf_n.lng_of_name = par_acodekeyl.lng_key.code_id 
                  AND c_n.lng_of_name  = par_acodekeyl.lng_key.code_id 
                  AND cf_n.name        = par_acodekeyl.codifier_key.code_text
                  AND c_n.name         = par_acodekeyl.code_key.code_text;
            WHEN 'c_nm (+l_nm,+cf_id)' THEN
                srch_prfd:= TRUE;

                SELECT c_n.code_id
                INTO c_id
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes_names AS c_n
                   , sch_<<$app_name$>>.codes_names AS c_lng
                   , sch_<<$app_name$>>.codes       AS c_lng_cf
                   , sch_<<$app_name$>>.codes_tree  AS c_lng_ct
                WHERE ct.supercode_id  = par_acodekeyl.codifier_key.code_id
                  AND ct.subcode_id    = c_n.code_id
                  AND c_n.lng_of_name  = c_lng.code_id 
                  AND c_lng.code_text  = par_acodekeyl.lng_key.code_text
                  AND c_n.name         = par_acodekeyl.code_key.code_text
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
                   , sch_<<$app_name$>>.codes_names AS c_lng
                   , sch_<<$app_name$>>.codes       AS c_lng_cf
                   , sch_<<$app_name$>>.codes_tree  AS c_lng_ct
                WHERE ct.supercode_id  = cf_n.code_id
                  AND ct.subcode_id    = c_n.code_id
                  AND cf_n.lng_of_name = c_lng.code_id 
                  AND c_n.lng_of_name  = c_lng.code_id 
                  AND c_lng.code_text  = par_acodekeyl.lng_key.code_text
                  AND cf_n.name        = par_acodekeyl.codifier_key.code_text
                  AND c_n.name         = par_acodekeyl.code_key.code_text
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
        SELECT code_id_of(TRUE, make_acodekeyl_bystr2('Common nominal codes set', 'undefined')); 
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION code_id_of_unclassified() RETURNS integer AS $$
        SELECT code_id_of(TRUE, make_acodekeyl_bystr2('Common nominal codes set', 'unclassified')); 
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION code_id_of_error() RETURNS integer AS $$
        SELECT code_id_of(TRUE, make_acodekeyl_bystr2('Common nominal codes set', 'error')); 
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION code_id_of_ambiguous() RETURNS integer AS $$
        SELECT code_id_of(TRUE, make_acodekeyl_bystr2('Common nominal codes set', 'ambiguous')); 
$$ LANGUAGE SQL;

COMMENT ON FUNCTION code_id_of_undefined()    IS 'code_id_of(TRUE, make_acodekeyl_bystr2(''Common nominal codes set'', ''undefined''))';
COMMENT ON FUNCTION code_id_of_unclassified() IS 'code_id_of(TRUE, make_acodekeyl_bystr2(''Common nominal codes set'', ''unclassified''))';
COMMENT ON FUNCTION code_id_of_error()        IS 'code_id_of(TRUE, make_acodekeyl_bystr2(''Common nominal codes set'', ''error''))';
COMMENT ON FUNCTION code_id_of_ambiguous()    IS 'code_id_of(TRUE, make_acodekeyl_bystr2(''Common nominal codes set'', ''ambiguous''))';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION code_belongs_to_codifier(par_acodekeyl t_addressed_code_key_by_lng) RETURNS boolean AS $$
DECLARE
        e boolean;
	cnt integer;
        __const_nom_cf_name CONSTANT varchar := 'Common nominal codes set';
        __const_undef_c_name CONSTANT varchar:= 'undefined';
BEGIN
        
        CASE acodekeyl_type(par_acodekeyl)
            WHEN 'undef' THEN
                RETURN NULL;
            WHEN 'cf_id' THEN
                SELECT TRUE
                INTO e
                FROM sch_<<$app_name$>>.codes_tree AS ct
                   , sch_<<$app_name$>>.codes_tree AS ct_nom
                   , sch_<<$app_name$>>.codes      AS c_undef
                   , sch_<<$app_name$>>.codes      AS c_nom
                WHERE ct.supercode_id     = par_acodekeyl.codifier_key.code_id
                  AND ct.subcode_id       = c_undef.code_id
                  AND ct_nom.supercode_id = c_nom.code_id
                  AND ct_nom.subcode_id   = c_undef.code_id
                  AND c_nom.code_text     = __const_nom_cf_name
                  AND c_undef.code_text   = __const_undef_c_name;
            WHEN 'cf_nm (-l)' THEN 
                SELECT TRUE
                INTO e
                FROM sch_<<$app_name$>>.codes_tree AS ct
                   , sch_<<$app_name$>>.codes      AS cf
                   , sch_<<$app_name$>>.codes_tree AS ct_nom
                   , sch_<<$app_name$>>.codes      AS c_undef
                   , sch_<<$app_name$>>.codes      AS c_nom
                WHERE ct.supercode_id     = cf.code_id
                  AND cf.code_text        = par_acodekeyl.codifier_key.code_text
                  AND ct.subcode_id       = c_undef.code_id
                  AND ct_nom.supercode_id = c_nom.code_id
                  AND ct_nom.subcode_id   = c_undef.code_id
                  AND c_nom.code_text     = __const_nom_cf_name
                  AND c_undef.code_text   = __const_undef_c_name;
            WHEN 'cf_nm (+l_id)' THEN
                SELECT TRUE
                INTO e
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes_names AS cf_nm
                   , sch_<<$app_name$>>.codes_tree  AS ct_nom
                   , sch_<<$app_name$>>.codes       AS c_undef
                   , sch_<<$app_name$>>.codes       AS c_nom
                WHERE ct.supercode_id     = cf_nm.code_id
                  AND cf_nm.name          = par_acodekeyl.codifier_key.code_text
                  AND cf_nm.lng_of_name   = par_acodekeyl.lng_key.code_id
                  AND ct.subcode_id       = c_undef.code_id
                  AND ct_nom.supercode_id = c_nom.code_id
                  AND ct_nom.subcode_id   = c_undef.code_id
                  AND c_nom.code_text     = __const_nom_cf_name
                  AND c_undef.code_text   = __const_undef_c_name;
            WHEN 'cf_nm (+l_nm)' THEN
                SELECT TRUE
                INTO e
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes_names AS cf_nm
                   , sch_<<$app_name$>>.codes_names AS c_lng
                   , sch_<<$app_name$>>.codes       AS c_lng_cf
                   , sch_<<$app_name$>>.codes_tree  AS c_lng_ct
                   , sch_<<$app_name$>>.codes_tree  AS ct_nom
                   , sch_<<$app_name$>>.codes       AS c_undef
                   , sch_<<$app_name$>>.codes       AS c_nom
                WHERE ct.supercode_id     = cf_nm.code_id
                  AND cf_nm.name          = par_acodekeyl.codifier_key.code_text
                  AND cf_nm.lng_of_name   = c_lng.code_id
                  AND c_lng_ct.subcode_id = c_lng.code_id
                  AND c_lng_ct.supercode_id = c_lng_cf.code_id
                  AND c_lng_cf.code_text  = 'Languages'
                  AND c_lng.code_text     = par_acodekeyl.lng_key.code_text
                  AND ct.subcode_id       = c_undef.code_id
                  AND ct_nom.supercode_id = c_nom.code_id
                  AND ct_nom.subcode_id   = c_undef.code_id
                  AND c_nom.code_text     = __const_nom_cf_name
                  AND c_undef.code_text   = __const_undef_c_name;
            WHEN 'c_id' THEN
                CASE codekeyl_type(make_codekeyl(par_acodekeyl.key_lng, par_acodekeyl.codifier_key))
                    WHEN 'c_id' THEN
                        SELECT TRUE
                        INTO e
                        FROM sch_<<$app_name$>>.codes_tree AS ct
                        WHERE ct.supercode_id = par_acodekeyl.codifier_key.code_id
                          AND ct.subcode_id   = par_acodekeyl.code_key.code_id;
                    WHEN 'c_nm (-l,-cf)' THEN
                        SELECT TRUE
                        INTO e
                        FROM sch_<<$app_name$>>.codes_tree AS ct
                           , sch_<<$app_name$>>.codes      AS cf
                        WHERE ct.supercode_id = cf.code_id
                          AND ct.subcode_id   = par_acodekeyl.code_key.code_id
                          AND cf.code_text    = par_acodekeyl.codifier_key.code_text;
                    WHEN 'c_nm (+l_id,-cf)' THEN
                        SELECT TRUE
                        INTO e
                        FROM sch_<<$app_name$>>.codes_tree  AS ct
                           , sch_<<$app_name$>>.codes_names AS cf_n
                        WHERE ct.supercode_id  = cf_n.code_id
                          AND ct.subcode_id    = par_acodekeyl.code_key.code_id
                          AND cf_n.name        = par_acodekeyl.codifier_key.code_text
                          AND cf_n.lng_of_name = par_acodekeyl.lng_key.code_id;
                    WHEN 'c_nm (+l_nm,-cf)' THEN
                        SELECT TRUE
                        INTO e
                        FROM sch_<<$app_name$>>.codes_tree  AS ct
                           , sch_<<$app_name$>>.codes_names AS cf_n
                           , sch_<<$app_name$>>.codes_names AS c_lng
                           , sch_<<$app_name$>>.codes       AS c_lng_cf
                           , sch_<<$app_name$>>.codes_tree  AS c_lng_ct
                        WHERE ct.supercode_id     = cf_n.code_id
                          AND ct.subcode_id       = par_acodekeyl.code_key.code_id
                          AND cf_n.name           = par_acodekeyl.codifier_key.code_text
                          AND cf_n.lng_of_name    = c_lng.code_id 
                          AND c_lng.code_text     = par_acodekeyl.lng_key.code_text
                          AND c_lng_ct.subcode_id = c_lng.code_id
                          AND c_lng_ct.supercode_id = c_lng_cf.code_id
                          AND c_lng_cf.code_text  = 'Languages';
                    WHEN 'undef' THEN
                        RETURN NULL;
                    ELSE
                        RAISE EXCEPTION 'An error occurred in function "code_belongs_to_codifier"! Unexpected "codekeyl_type(make_codekeyl(par_acodekeyl.key_lng, par_acodekeyl.codifier_key))" output for code key: %!', show_acodekeyl(par_acodekeyl); 
                END CASE;
            WHEN 'c_nm (-l,-cf)' THEN
                RETURN NULL;
            WHEN 'c_nm (-l,+cf_id)' THEN
                SELECT TRUE
                INTO e
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes_names AS c
                WHERE ct.supercode_id  = par_acodekeyl.codifier_key.code_id
                  AND ct.subcode_id    = c.code_id
                  AND c.code_text      = par_acodekeyl.code_key.code_text;
            WHEN 'c_nm (-l,+cf_nm)' THEN
                SELECT TRUE
                INTO e
                FROM sch_<<$app_name$>>.codes_tree AS ct
                   , sch_<<$app_name$>>.codes      AS cf
                   , sch_<<$app_name$>>.codes      AS c
                WHERE ct.supercode_id = cf.code_id
                  AND ct.subcode_id   = c.code_id
                  AND cf.code_text    = par_acodekeyl.codifier_key.code_text
                  AND c.code_text     = par_acodekeyl.code_key.code_text;
            WHEN 'c_nm (+l_id,-cf)' THEN
                RETURN NULL;
            WHEN 'c_nm (+l_id,+cf_id)' THEN
                SELECT TRUE
                INTO e
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes_names AS c_n
                WHERE ct.supercode_id  = par_acodekeyl.codifier_key.code_id
                  AND ct.subcode_id    = c_n.code_id
                  AND c_n.lng_of_name  = par_acodekeyl.lng_key.code_id 
                  AND c_n.name         = par_acodekeyl.code_key.code_text;
            WHEN 'c_nm (+l_id,+cf_nm)' THEN
                SELECT TRUE
                INTO e
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes_names AS cf_n
                   , sch_<<$app_name$>>.codes_names AS c_n
                WHERE ct.supercode_id  = cf_n.code_id
                  AND ct.subcode_id    = c_n.code_id
                  AND cf_n.lng_of_name = par_acodekeyl.lng_key.code_id 
                  AND c_n.lng_of_name  = par_acodekeyl.lng_key.code_id 
                  AND cf_n.name        = par_acodekeyl.codifier_key.code_text
                  AND c_n.name         = par_acodekeyl.code_key.code_text;
            WHEN 'c_nm (+l_nm,-cf)' THEN
                RETURN NULL;
            WHEN 'c_nm (+l_nm,+cf_id)' THEN
                SELECT TRUE
                INTO e
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes_names AS c_n
                   , sch_<<$app_name$>>.codes_names AS c_lng
                   , sch_<<$app_name$>>.codes       AS c_lng_cf
                   , sch_<<$app_name$>>.codes_tree  AS c_lng_ct
                WHERE ct.supercode_id  = par_acodekeyl.codifier_key.code_id
                  AND ct.subcode_id    = c_n.code_id
                  AND c_n.lng_of_name  = c_lng.code_id 
                  AND c_lng.code_text  = par_acodekeyl.lng_key.code_text
                  AND c_n.name         = par_acodekeyl.code_key.code_text
                  AND c_lng_ct.subcode_id = c_lng.code_id
                  AND c_lng_ct.supercode_id = c_lng_cf.code_id
                  AND c_lng_cf.code_text  = 'Languages';
            WHEN 'c_nm (+l_nm,+cf_nm)' THEN
                SELECT TRUE
                INTO e
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes_names AS cf_n
                   , sch_<<$app_name$>>.codes_names AS c_n
                   , sch_<<$app_name$>>.codes_names AS c_lng
                   , sch_<<$app_name$>>.codes       AS c_lng_cf
                   , sch_<<$app_name$>>.codes_tree  AS c_lng_ct
                WHERE ct.supercode_id  = cf_n.code_id
                  AND ct.subcode_id    = c_n.code_id
                  AND cf_n.lng_of_name = c_lng.code_id 
                  AND c_n.lng_of_name  = c_lng.code_id 
                  AND c_lng.code_text  = par_acodekeyl.lng_key.code_text
                  AND cf_n.name        = par_acodekeyl.codifier_key.code_text
                  AND c_n.name         = par_acodekeyl.code_key.code_text;
                  AND c_lng_ct.subcode_id = c_lng.code_id
                  AND c_lng_ct.supercode_id = c_lng_cf.code_id
                  AND c_lng_cf.code_text  = 'Languages';

            ELSE
                RAISE EXCEPTION 'An error occurred in function "code_belongs_to_codifier"! Unexpected "acodekeyl_type(par_acodekeyl)" output for code key: %!', show_acodekeyl(par_acodekeyl); 
        END CASE;

        GET DIAGNOSTICS cnt = ROW_COUNT;

        IF cnt = 0 THEN
                RETURN FALSE; 
        ELSIF cnt > 1 THEN
                RAISE EXCEPTION 'Data inconsistecy error detected, when trying to check, if code belongs to codifier in code key %! Multiple belongings are found, but only one must have been.', show_acodekeyl(par_acodekeyl);
	ELSE 
		RETURN TRUE; 
	END IF;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION code_belongs_to_codifier(par_acodekeyl t_addressed_code_key_by_lng) IS
'Keys of type patterned by "cf_*" are treated to check, if codifier allows code {"Common nominal codes sets"."undefined"}.
For keys of type patterned by "c_nm (*,-cf)" NULL is returned.
For keys of type "undef" NULL is returned. 
For keys of type "c_id", if codifier is NULL, then NULL is returned. 
';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION codifier_default_code(par_if_exists boolean, par_cf_keyl t_code_key_by_lng) 
RETURNS integer AS $$
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
                WHERE supercode_id = par_cf_keyl.code_key.code_id
                  AND dflt_subcode_isit;
            WHEN 'c_nm (-l,-cf)' THEN
                SELECT ct.subcode_id INTO d
                FROM sch_<<$app_name$>>.codes_tree AS ct
                   , sch_<<$app_name$>>.codes      AS c
                WHERE ct.supercode_id = c.code_id
                  AND c.code_text     = par_cf_keyl.code_key.code_text
                  AND ct.dflt_subcode_isit;
            WHEN 'c_nm (+l_id,-cf)' THEN
                SELECT ct.subcode_id INTO d
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes_names AS cn
                WHERE ct.supercode_id = cn.code_id
                  AND c.name          = par_cf_keyl.code_key.code_text
                  AND c.lng_of_name   = par_cf_keyl.lng_key.code_id
                  AND ct.dflt_subcode_isit;
            WHEN 'c_nm (+l_nm,-cf)' THEN
                SELECT ct.subcode_id INTO d
                FROM sch_<<$app_name$>>.codes_tree  AS ct
                   , sch_<<$app_name$>>.codes_names AS cn
                   , sch_<<$app_name$>>.codes       AS c_lng
                   , sch_<<$app_name$>>.codes       AS c_lng_cf
                   , sch_<<$app_name$>>.codes_tree  AS c_lng_ct
                WHERE ct.supercode_id = cn.code_id
                  AND c.name          = par_cf_keyl.code_key.code_text
                  AND c.lng_of_name   = c_lng.code_id
                  AND c_lng.code_text = par_cf_keyl.lng_key.code_text
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
                RETURN NULL; 
        ELSIF cnt > 1 THEN
                RAISE EXCEPTION 'An error occurred, when trying get a default code ID for codifier: %! More then one default, which is illegal.', show_codekeyl(par_cf_keyl);
                RETURN NULL; 
        END IF;

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
        ccc sch_<<$app_name$>>.codes%ROWTYPE:= NULL;
BEGIN
        SELECT c.*
        INTO ccc
        FROM sch_<<$app_name$>>.codes AS c
        WHERE c.code_id = code_id_of(par_if_exists, par_acodekeyl);

        RETURN ccc;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_code(par_if_exists boolean, par_acodekeyl t_addressed_code_key_by_lng) IS
'Wrapper around code_id_of(...).';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_codes_l(par_key t_code_key_by_lng) RETURNS SETOF sch_<<$app_name$>>.codes AS $$
DECLARE
        ccc sch_<<$app_name$>>.codes%ROWTYPE:= NULL;
BEGIN
        CASE codekeyl_type(par_key) 
            WHEN 'c_id' THEN
                RETURN QUERY
                        SELECT c.*
                        FROM sch_<<$app_name$>>.codes AS c
                        WHERE c.code_id = par_key.code_key.code_id;
            WHEN 'c_nm (-l,-cf)' THEN
                RETURN QUERY
                        SELECT c.*
                        FROM sch_<<$app_name$>>.codes AS c
                        WHERE c.code_text = par_key.code_key.code_text;
            WHEN 'c_nm (+l_id,-cf)' THEN
                RETURN QUERY
                        SELECT c.*
                        FROM sch_<<$app_name$>>.codes       AS c
                           , sch_<<$app_name$>>.codes_names AS cn
                        WHERE c.code_type   != 'plain code'
                          AND c.code_id      = cn.code_id
                          AND cn.name        = par_acodekeyl.code_key.code_text
                          AND cn.lng_of_name = par_acodekeyl.lng_key.code_id;
            WHEN 'c_nm (+l_nm,-cf)' THEN
                RETURN QUERY
                        SELECT c.*
                        FROM sch_<<$app_name$>>.codes       AS c
                           , sch_<<$app_name$>>.codes_names AS cn
                           , sch_<<$app_name$>>.codes       AS c_lng
                           , sch_<<$app_name$>>.codes       AS c_lng_cf
                           , sch_<<$app_name$>>.codes_tree  AS c_lng_ct
                        WHERE c.code_id           = cn.code_id
                          AND cn.name             = par_codekeyl.code_key.code_text
                          AND cn.lng_of_name      = c_lng.code_id
                          AND c_lng.code_text     = par_codekeyl.lng_key.code_text
                          AND c_lng_ct.subcode_id = c_lng.code_id
                          AND c_lng_ct.supercode_id = c_lng_cf.code_id
                          AND c_lng_cf.code_text  = 'Languages';
            WHEN 'undef' THEN
            ELSE
                RAISE EXCEPTION 'An error occurred in function "get_codes_l"! Unexpected "codekeyl_type(par_key)" output for code key: %!', show_codekeyl(par_key); 
        END CASE;

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
                RETURN NULL; 
        END IF;

        RETURN ccc;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_nonplaincode_by_str(par_codifier varchar) IS
'Returns NULL if nothing found.';

CREATE OR REPLACE FUNCTION get_code_by_str(par_codifier varchar, par_code varchar) RETURNS sch_<<$app_name$>>.codes AS $$
BEGIN
        RETURN get_code(TRUE, make_acodekeyl_str2(par_codifier, par_code));
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_nonplaincode_by_str(par_codifier varchar) IS
'get_code(TRUE, make_acodekeyl_str2(par_codifier, par_code))
Returns NULL if nothing found.';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_codes_of_codifier(par_acodekeyl t_addressed_code_key_by_lng) RETURNS SETOF sch_<<$app_name$>>.codes AS $$ 
DECLARE
        c_id integer;
BEGIN
        c_id := code_id_of(TRUE, par_acodekeyl);

        RETURN QUERY
                SELECT c.*
                FROM sch_<<$app_name$>>.codes AS c, sch_<<$app_name$>>.codes_tree AS ct
                WHERE c.code_id = ct.subcode_id
                  AND ct.supercode_id = c_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_codes_of_codifier(par_acodekeyl t_addressed_code_key_by_lng) IS
'Selects all subcodes from codes_tree, by supercode_id = code_id_of(TRUE,$1).';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_codifiers_of_code(par_acodekeyl t_addressed_code_key_by_lng) RETURNS SETOF sch_<<$app_name$>>.codes AS $$ 
DECLARE
        c_id integer;
BEGIN
        c_id := code_id_of(TRUE, par_acodekeyl);

        RETURN QUERY
                SELECT c.*
                FROM sch_<<$app_name$>>.codes AS c, sch_<<$app_name$>>.codes_tree AS ct
                WHERE c.code_id = ct.supercode_id
                  AND ct.subcode_id = c_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_codes_of_codifier(par_acodekeyl t_addressed_code_key_by_lng) IS
'Selects all supercodes from codes_tree, by subcode_id = code_id_of(TRUE,$1).';

-------------------------------------------------------------------------------

CREATE TYPE codes_tree_node (
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
        , par_only_ones_not_reachable_from_elsewhere 
                        boolean
        ) RETURNS SETOF codes_tree_node AS $$ 
DECLARE
        max_dpth             integer;
        root_c               sch_<<$app_name$>>.codes%ROWTYPE;
        root_codes_tree_node codes_tree_node;
        initial_scope        codes_tree_node[];
        shared_codes         integer[];
BEGIN
        root_c:= get_code(par_if_exists, par_cf_key);
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
                        WITH RECURSIVE subcodes(code_id, default_ist, tree_depth, nodes_path, path_terminated_with_cycle) AS (
                            SELECT root_codes_tree_node;
                          UNION
                            SELECT ct.subcode_id                  AS code_id
                                 , c.code_text                    AS code_text
                                 , c.code_type                    AS code_type
                                 , ct.dflt_subcode_isit           AS default_ist
                                 , sc.tree_depth + 1              AS tree_depth
                                 , sc.nodes_path || ct.subcode_id AS nodes_path
                                 , sc.nodes_path @> ARRAY[ct.subcode_id] AS path_terminated_with_cycle
                            FROM sch_<<$app_name$>>.codes_tree AS ct
                               , sch_<<$app_name$>>.subcodes   AS sc
                               , sch_<<$app_name$>>.codes      AS  c
                            WHERE NOT path_terminated_with_cycle
                              AND ct.supercode_id = sc.code_id
                              AND c.code_id = ct.subcode_id;
                        )
                        SELECT code_id, code_text, code_type, default_ist, tree_depth, nodes_path, path_terminated_with_cycle 
                        FROM subcodes
                        WHERE tree_depth != 0;
                );

        IF NOT par_only_ones_not_reachable_from_elsewhere THEN
                RETURN QUERY SELECT * FROM unnest(initial_scope) AS is;
        ELSE
                shared_subcodes := ARRAY(
                           SELECT subcode_id
                           FROM sch_<<$app_name$>>.codes_tree
                           WHERE     initial_scope @> ARRAY[subcode_id]
                             AND NOT initial_scope @> ARRAY[supercode_id]
                             AND     supercode_id != root_c.code_id;
                );

                RETURN QUERY 
                        SELECT root_codes_tree_node
                      UNION
                        SELECT * 
                        FROM unnest(initial_scope) AS is
                           , unnest(shared_subcodes) AS ss(shared_code)
                        WHERE initial_scope ss.shared_code;
        END IF;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION find_subcodes(
          par_if_exists boolean
        , par_cf_key t_addressed_code_key_by_lng
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
';
-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION remove_code(
        par_if_exists boolean
      , par_acodekeyl t_addressed_code_key_by_lng
      , par_only_ones_not_reachable_from_elsewhere 
                      boolean
      ) RETURNS integer AS $$ 
DECLARE
        cnt integer;
        find_results integer[];
BEGIN
        find_results:= ARRAY(SELECT DISTINCT code_id FROM find_subcodes(par_if_exists, par_cf_key, par_only_ones_not_reachable_from_elsewhere));
        DELETE FROM sch_<<$app_name$>>.codes WHERE find_results @> ARRAY[code_id];

        GET DIAGNOSTICS cnt = ROW_COUNT;

        RETURN cnt;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION remove_code(par_if_exists boolean, par_acodekeyl t_addressed_code_key_by_lng) IS
'Wrapper around find_subcodes(...). Returns count of rows deleted.';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION bind_code_to_codifier(
          par_c_acodekeyl  t_addressed_code_key_by_lng
        , par_cf_codekeyl t_code_key_by_lng
        , par_dflt boolean
        ) RETURNS integer AS $$ 
DECLARE
        c_id  integer;
        cf_id integer;
        cnt   integer;
BEGIN
        c_id:=  code_id_of(FALSE,                     par_c_acodekeyl );
        cf_id:= code_id_of(FALSE, generalize_codekeyl(par_cf_codekeyl));

        INSERT INTO sch_<<$app_name$>>.codes_tree (supercode_id, subcode_id, dflt_subcode_isit) 
        VALUES (cf_if, c_id, COALESCE(par_dflt, FALSE));
        
        GET DIAGNOSTICS cnt = ROW_COUNT;

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
        , par_dflt boolean
        ) RETURNS integer AS $$ 
DECLARE 
        c_id  integer;
        cf_id integer;
        cnt integer:= 0;
BEGIN
        c_id:=  code_id_of(FALSE, par_c_acodekeyl);
        cf_id:= code_id_of(FALSE, generalize_codekeyl(make_codekeyl(par_c_acodekeyl.key_lng, par_c_acodekeyl.code_key)));

        DELETE FROM sch_<<$app_name$>>.codes_tree WHERE supercode_id = cf_id AND subcode_id = c_id;

        GET DIAGNOSTICS cnt = ROW_COUNT;

        IF (cnt IS NULL OR cnt != 1) AND (NOT par_if_exists) THEN
                RAISE EXCEPTION 'An error occurred, when trying to unbind code %! Bad count (%) of rows modified.', show_acodekeyl(par_c_acodekeyl), cnt;
                RETURN cnt; 
        END IF;

        RETURN cnt;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION unbind_code_from_codifier(
          par_if_exists boolean
        , par_c_acodekeyl  t_addressed_code_key_by_lng
        , par_dflt boolean
        ) IS
'Wrapper around "code_id_of(FALSE,...)". Returns count of rows deleted.';

-------------------------------------------------------------------------------

CREATE TYPE code_construction_input AS (code_text varchar, code_type code_type);

CREATE OR REPLACE FUNCTION new_code(
          par_code_construct code_construction_input
        , par_super_code     t_code_key_by_lng
        , par_dflt_isit      boolean
        ) RETURNS integer AS $$ 
DECLARE
        cnt1 integer;
        cnt2 integer;
        c_id integer;
BEGIN
        IF par_code_construct.code_type = 'plain code' THEN
                c_id := nextval('sch_<<$app_name$>>.plain_codes_ids_seq');
        ELSE
                c_id := nextval('sch_<<$app_name$>>.codifiers_ids_seq');
        END IF;

        INSERT INTO sch_<<$app_name$>>.codes (code_id, code_text, code_type) 
        VALUES (c_id, par_code_construct.code_text, par_code_construct.code_type);

        GET DIAGNOSTICS cnt1 = ROW_COUNT;

        IF NOT (codekeyl_type(par_super_code) = 'undef') THEN
                cnt2:= bind_code_to_codifier(c_id, code_id_of(FALSE, generalize_codekeyl(par_super_code)), par_dflt_isit);
        END IF;

        RETURN c_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION new_code(
          par_code_construct code_construction_input
        , par_super_code     t_code_key_by_lng
        , par_dflt_isit      boolean
        ) IS
'Returns ID of newly created code. Parameter "par_dflt_isit" is used by function, only when "par_super_code" is not of type "undef" (not NULL).';

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
BEGIN
        cf_id:= code_id_of(FALSE, generalize_codekeyl(par_cf));

        dflt_correct := (par_cf_dflt_codestr IS NULL) OR (par_cf_dflt_codestr = '');

        FOR i IN 1..COALESCE(array_upper(par_codes_array, 1), 0) LOOP
                dflt_correct := dflt_correct OR ((par_codes_array[i]).code_text = par_cf_dflt_codestr);
        END LOOP;

        IF NOT dflt_correct THEN
                RAISE EXCEPTION 'An error occurred, when trying to add subcodes under a codifier %! The default code is specified to = "%", but it is not in the lists codes.', show_codekeyl(par_cf), par_cf_dflt_codestr;
                RETURN 0; 
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
        r result_of_making_new_codifier_w_subcodes;
BEGIN
        SELECT code_id INTO r.codifier_id
        FROM unnest(add_subcodes_under_codifier(par_super_cf, NULL :: varchar, VARIADIC ARRAY[par_cf_construct])) AS r(code_id);

        r.subcodes_ids_list:= add_subcodes_under_codifier(
                                        make_codekeyl_byid(r.codifier_id)
                                      , par_cf_dflt_codestr
                                      , VARIADIC par_codes_array
                                      );

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
BEGIN
        -- validate input data
        IF par_cf_new_type = 'plain code' THEN
                RAISE EXCEPTION 'An error occurred, in the function "make_codifier_from_plaincode", code %! The new type of code can not be "plain code".', show_codekeyl(par_cf);
                RETURN 0; 
        END IF;
        
        SELECT get_code_l(par_cf)
        INTO c;
        
        GET DIAGNOSTICS cnt = ROW_COUNT;

        IF cnt > 1 THEN
                RAISE EXCEPTION 'An error occurred, in the function "make_codifier_from_plaincode", code %! Can''t make a codifier, because target code has a nonunique name.', show_codekeyl(par_cf);
        ELSE IF cnt = 0 THEN
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
';

-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION make_codifier_from_plaincode_w_values(
          par_if_exists       boolean
        , par_reidentify      boolean
        , par_c               t_addressed_code_key_by_lng
        , par_cf_new_type     code_type
        , par_cf_dflt_codestr varchar
        , VARIADIC par_codes_array code_construction_input[] -- par_cf_dflt_codestr must persist in this array
        ) 
RETURNS result_of_making_new_codifier_w_subcodes AS $$
DECLARE
        r result_of_making_new_codifier_w_subcodes;
BEGIN
        r.codifier_id:= make_codifier_from_plaincode(par_if_exists, par_reidentify, par_c, VARIADIC par_cf_new_type);

        r.subcodes_ids_list:= add_subcodes_under_codifier(make_codekeyl_byid(r.codifier_id), par_cf_dflt_codestr, VARIADIC par_codes_array);

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

CREATE TYPE code_lngname_construction_input AS 
        ( lng         varchar
        , name        integer
        , description varchar
        );

CREATE OR REPLACE FUNCTION add_code_lng_names(
          par_if_exists boolean
        , par_c         t_addressed_code_key_by_lng
        , VARIADIC par_codesnames_array 
                        code_lngname_construction_input[] 
        ) 
RETURNS integer AS $$
DECLARE
        cnt integer;
        c_id integer;
BEGIN
        c_id := code_id_of(par_if_exists, par_c);

        IF c_id IS NULL THEN
                IF NOT par_if_exists THEN
                        RAISE EXCEPTION 'An error occurred, in the function "add_code_lng_names", code %! Function "code_id_of" unexpectedly returned NULL (with "if_exists" parameter set to FASE).', show_acodekeyl(par_c);
                END IF;

                RETURN 0;
        ELSE
                INSERT INTO codes_names (code_id, lng_of_name, name, description)
                SELECT c_id, v.lng_of_name, v.name, v.description
                FROM (SELECT c_lng.code_id AS lng_of_name, inp.name, inp.description
                      FROM unnest(par_codesnames_array)   AS inp
                         , sch_<<$app_name$>>.codes_names AS c_lng
                         , sch_<<$app_name$>>.codes       AS c_lng_cf
                         , sch_<<$app_name$>>.codes_tree  AS c_lng_ct
                        WHERE inp.lng               = c_lng.code_text 
                          AND c_lng_ct.subcode_id   = c_lng.code_id
                          AND c_lng_ct.supercode_id = c_lng_cf.code_id
                          AND c_lng_cf.code_text    = 'Languages';
                      ) AS v;

                GET DIAGNOSTICS cnt = ROW_COUNT;

                RETURN cnt;
        END IF;

END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION  add_code_lng_names(
          par_if_exists boolean
        , par_c         t_addressed_code_key_by_lng
        , VARIADIC par_codesnames_array 
                        code_lngname_construction_input[] 
        ) IS
'Adding entries in the "codes_names" table. 
Returns number of rows inserted.
';

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- Referencing functions:

GRANT EXECUTE ON FUNCTION make_codekey_null()TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_codekey_byid(par_code_id integer)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_codekey_bystr(par_code_text varchar)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_acodekey_null()TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_acodekey(par_cf_key t_code_key, par_c_key t_code_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_codekeyl(par_key_lng t_code_key, par_code_key t_code_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_codekeyl_null()TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_codekeyl_byid(par_code_id integer)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_codekeyl_bystr(par_code_text varchar)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_codekeyl_bystrl(par_lng_key t_code_key, par_code_text varchar)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_acodekeyl_null()TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_acodekeyl(par_key_lng t_code_key, par_cf_key t_code_key, par_c_key t_code_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_acodekeyl_byid(par_code_id integer)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_acodekeyl_bystr1(par_code_text varchar)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION make_acodekeyl_bystr2(par_codifier_text varchar, par_code_text varchar)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION show_codekey(par_key t_code_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION show_acodekey(par_key t_addressed_code_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION show_codekeyl(par_key t_code_key_by_lng)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION show_acodekeyl(par_key t_addressed_code_key_by_lng)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION generalize_codekey(par_key t_code_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION generalize_codekeyl(par_key t_code_key_by_lng)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION generalize_acodekey(par_key t_addressed_code_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION codekey_type(par_key t_code_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION acodekey_type(par_key t_addressed_code_key)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION codekeyl_type(par_key t_code_key_by_lng)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION acodekeyl_type(par_key t_addressed_code_key_by_lng)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;

-- Lookup functions:

GRANT EXECUTE ON FUNCTION code_id_of(par_if_exists boolean, par_acodekeyl t_addressed_code_key_by_lng)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION code_id_of_undefined()TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION code_id_of_unclassified()TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION code_id_of_error()TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION code_id_of_ambiguous()TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION code_belongs_to_codifier(par_acodekeyl t_addressed_code_key_by_lng)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION codifier_default_code(par_if_exists boolean, par_cf_keyl t_code_key_by_lng)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_code(par_if_exists boolean, par_key t_addressed_code_key_by_lng)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_codes_l(par_key t_code_key_by_lng)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_nonplaincode_by_str(par_codifier varchar)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_code_by_str(par_codifier varchar, par_code varchar)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_codes_of_codifier(par_acodekeyl t_addressed_code_key_by_lng)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_codifiers_of_code(par_acodekeyl t_addressed_code_key_by_lng)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION find_subcodes(par_if_exists boolean, par_cf_key t_addressed_code_key_by_lng, par_only_ones_not_reachable_from_elsewhere boolean)TO user_<<$app_name$>>_data_admin, user_<<$app_name$>>_data_reader;

-- Administration functions:

GRANT EXECUTE ON FUNCTION remove_code(par_if_exists boolean, par_acodekeyl t_addressed_code_key_by_lng, par_only_ones_not_reachable_from_elsewhere boolean)TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION bind_code_to_codifier(par_c_acodekeyl t_addressed_code_key_by_lng, par_cf_codekeyl t_code_key_by_lng, par_dflt boolean)TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION unbind_code_from_codifier(par_if_exists boolean, par_c_acodekeyl t_addressed_code_key_by_lng, par_dflt boolean)TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION new_code(par_code_construct code_construction_input, par_super_code t_code_key_by_lng, par_dflt_isit boolean)TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION add_subcodes_under_codifier(par_cf t_code_key_by_lng, par_cf_dflt_codestr varchar, VARIADIC par_codes_array code_construction_input[])TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION new_codifier_w_subcodes(par_super_cf t_code_key_by_lng, par_cf_construct code_construction_input, par_cf_dflt_codestr varchar, VARIADIC par_codes_array code_construction_input[])TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION make_codifier_from_plaincode(par_if_exists boolean, par_reidentify boolean, par_cf t_code_key_by_lng, par_cf_new_type code_type)TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION make_codifier_from_plaincode_w_values(par_if_exists boolean, par_reidentify boolean, par_c t_code_key_by_lng, par_cf_new_type code_type, par_cf_dflt_codestr varchar, VARIADIC par_codes_array code_construction_input[])TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION add_code_lng_names(par_if_exists boolean, par_c t_addressed_code_key_by_lng, VARIADIC par_codesnames_array code_lngname_construction_input[])TO user_<<$app_name$>>_data_admin;
