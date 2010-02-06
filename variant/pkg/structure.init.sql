-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
-- 
-- All rights reserved.
-- 
-- For information about license see COPYING file in the root directory of current nominal package

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\c <<$db_name$>> user_<<$app_name$>>_owner

SET search_path TO sch_<<$app_name$>>, public; -- sets only for current session

INSERT INTO dbp_packages (package_name, package_version, dbp_standard_version) 
                   VALUES('<<$pkg.name$>>', '<<$pkg.ver$>>', '<<$pkg.std_ver$>>');

-- ^^^ don't change this !!

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

CREATE TYPE code_type AS ENUM ('metacodifier', 'codifier', 'statuses-set', 'composite code part', 'plain code', 'undefined', 'unclassified');

COMMENT ON TYPE code_type IS
'Type "plain code" is special. Code of such type can''t have subcodes.
';

-- one hunded sch_<<$app_name$>>.codes reserved for the most fundamental codifiers roots
CREATE SEQUENCE codifiers_ids_seq -- WARNING!!! Some alterations are there in the data.sql
        INCREMENT BY 10
        MINVALUE 100
        START WITH 100
        NO CYCLE;

-- one hunded sch_<<$app_name$>>.codes reserved for the most fundamental codifiers roots
CREATE SEQUENCE plain_codes_ids_seq 
        INCREMENT BY 10
        MINVALUE 10000
        START WITH 10000
        NO CYCLE;

CREATE TABLE codes (
        code_id            integer   NOT NULL PRIMARY KEY
      , code_type          code_type NOT NULL
      , code_text          varchar   NOT NULL
      , additional_field_1 varchar       NULL
      , additional_field_2 varchar       NULL
      , additional_field_3 varchar       NULL
      , additional_field_4 varchar       NULL
      , additional_field_5 varchar       NULL
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

CREATE INDEX codestexts_in_codes_idx ON codes(code_text) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;

CREATE TABLE codes_tree (
        supercode_id      integer NOT NULL REFERENCES codes (code_id) ON DELETE CASCADE ON UPDATE CASCADE
      , subcode_id        integer NOT NULL REFERENCES codes (code_id) ON DELETE CASCADE ON UPDATE CASCADE
      , dflt_subcode_isit boolean NOT NULL DEFAULT FALSE
      , PRIMARY KEY (supercode_id, subcode_id)
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

CREATE INDEX codifiers_idx ON codes_tree(supercode_id) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;

-------------------------------------

CREATE TABLE named_in_languages (
          lng_of_name integer
        , FOREIGN KEY (lng_of_name) REFERENCES codes(code_id) ON DELETE RESTRICT ON UPDATE CASCADE
) INHERITS (names)
  TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

CREATE TABLE codes_names (
        code_id     integer NOT NULL 
      , PRIMARY KEY (code_id, lng_of_name)
      , FOREIGN KEY (code_id)     REFERENCES codes(code_id) ON DELETE CASCADE  ON UPDATE CASCADE
      , FOREIGN KEY (lng_of_name) REFERENCES codes(code_id) ON DELETE RESTRICT ON UPDATE CASCADE
) INHERITS (named_in_languages) 
  TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

ALTER TABLE codes_names ALTER COLUMN entity SET DEFAULT 'code';

-------------------------------------

\i functions.init.sql 

-------------------------------------

ALTER TABLE named_in_languages 
        ADD CONSTRAINT named_in_languages_lng_codekey 
                CHECK (code_belongs_to_codifier(
                                FALSE
                              , make_acodekeyl(
                                          make_codekey_null()
                                        , make_codekey_bystr('Languages')
                                        , make_codekey_byid(lng_of_name)
                      )         )       );

-------------------------------------

GRANT USAGE ON SEQUENCE codifiers_ids_seq   TO user_<<$app_name$>>_data_admin;
GRANT USAGE ON SEQUENCE plain_codes_ids_seq TO user_<<$app_name$>>_data_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE codes              TO user_<<$app_name$>>_data_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE codes_names        TO user_<<$app_name$>>_data_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE codes_tree         TO user_<<$app_name$>>_data_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE named_in_languages TO user_<<$app_name$>>_data_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE codes_names        TO user_<<$app_name$>>_data_admin;

GRANT SELECT                         ON TABLE codes              TO user_<<$app_name$>>_data_reader;
GRANT SELECT                         ON TABLE codes_names        TO user_<<$app_name$>>_data_reader;
GRANT SELECT                         ON TABLE codes_tree         TO user_<<$app_name$>>_data_reader;
GRANT SELECT                         ON TABLE named_in_languages TO user_<<$app_name$>>_data_reader;
GRANT SELECT                         ON TABLE codes_names        TO user_<<$app_name$>>_data_reader;

-------------------------------------

CREATE OR REPLACE FUNCTION codes_tree_onmodify() RETURNS trigger AS $tri_codes_tree_onmodify$ -- upd, ins
DECLARE
        new_cfr_name varchar;
        subcode_name varchar;
        cnt integer;
        lng integer;
        code_t code_type;
BEGIN
        SELECT code_text, code_type
        INTO new_cfr_name, code_t
        FROM sch_<<$app_name$>>.codes AS c
        WHERE c.code_id = NEW.supercode_id;

        IF code_t = 'plain code' THEN
                RAISE EXCEPTION 'An error occurred, when trying to register a plain code with the name "%" in the table "sch_<<$app_name$>>.codes_tree"! Plain codes (code_type field) are not allowed to have subcodes, to become codifiers.', new_cfr_name;
                IF    TG_OP = 'INSERT' THEN
                        RETURN NULL;
                ELSIF TG_OP = 'UPDATE' THEN
                        RETURN OLD;
                END IF;
        ELSE
                IF NEW.dflt_subcode_isit = TRUE THEN
                        
                        SELECT COUNT(subcode_id)
                        INTO cnt 
                        FROM sch_<<$app_name$>>.codes_tree AS ct
                        WHERE ct.supercode_id = NEW.supercode_id
                          AND ct.dflt_subcode_isit = TRUE
                          AND ct.subcode_id != NEW.subcode_id;
                        
                        IF cnt > 0 THEN
                                RAISE EXCEPTION 'An error occurred, when trying to register a default code with the name "%" in the table "sch_<<$app_name$>>.codes_tree" ! There already is a default code for this codifier, two defaults in one codifier are not allowed. Please, drop current default for this codified before setting new one.', new_cfr_name;
                                IF    TG_OP = 'INSERT' THEN
                                        RETURN NULL;
                                ELSIF TG_OP = 'UPDATE' THEN
                                        RETURN OLD;
                                END IF;
                        END IF;
                END IF;
        END IF;

        SELECT code_text
        INTO subcode_name
        FROM sch_<<$app_name$>>.codes AS c
        WHERE c.code_id = NEW.subcode_id;

        SELECT count(*)
        INTO cnt
        FROM sch_<<$app_name$>>.codes AS c, sch_<<$app_name$>>.codes_tree AS ct
        WHERE ct.supercode_id = NEW.supercode_id
          AND c.code_id = ct.subcode_id
          AND c.code_id != NEW.subcode_id
          AND c.code_text = subcode_name;
        
        IF cnt > 0 THEN
                RAISE EXCEPTION 'An error occurred, when trying to register a subcode with the name "%" in the codifier "%"! The codifier already contains such code. No duplicate codes are allowed in one codifier.', subcode_name, new_cfr_name;
                IF    TG_OP = 'INSERT' THEN
                        RETURN NULL;
                ELSIF TG_OP = 'UPDATE' THEN
                        RETURN OLD;
                END IF;
        END IF;

        lng := NULL;

        SELECT tn.lng_of_name, cn.name
        INTO lng, subcode_name
        FROM sch_<<$app_name$>>.codes_names AS cn
           , sch_<<$app_name$>>.codes_tree  AS ct
           , (SELECT name, lng_of_name
              FROM sch_<<$app_name$>>.codes_names AS cn
              WHERE cn.code_id = NEW.subcode_id
             ) AS tn
        WHERE ct.supercode_id = NEW.supercode_id
          AND cn.code_id      = ct.subcode_id
          AND cn.code_id     != NEW.subcode_id
          AND cn.name         = tn.name
          AND tn.lng_of_name  = cn.lng_of_name
        LIMIT 1;
        
        IF lng IS NOT NULL THEN
                RAISE EXCEPTION 'An error occurred, when trying to register a subcode with the with name "%" in language "%" in the codifier "%"! The codifier already contains a code, that has same name in same language. No duplicate codes are allowed in one codifier.', subcode_name, (get_code(TRUE, make_acodekeyl_byid(lng))).code_text, new_cfr_name;
                IF    TG_OP = 'INSERT' THEN
                        RETURN NULL;
                ELSIF TG_OP = 'UPDATE' THEN
                        RETURN OLD;
                END IF;
        END IF;

        RETURN NEW;
END;
$tri_codes_tree_onmodify$ LANGUAGE plpgsql;

CREATE TRIGGER tri_codes_tree_onmodify AFTER INSERT OR UPDATE ON sch_<<$app_name$>>.codes_tree
    FOR EACH ROW EXECUTE PROCEDURE codes_tree_onmodify();

-------------------------------------

CREATE OR REPLACE FUNCTION codes_onmodify() RETURNS trigger AS $tri_codes_onmodify$ -- upd, ins
DECLARE
        c sch_<<$app_name$>>.codes%ROWTYPE;
        dup_c_id integer;
        dup_cf_id integer;
        cond boolean;
BEGIN
        cond:= TG_OP = 'INSERT'; IF NOT cond THEN cond:= NEW.code_text IS DISTINCT FROM OLD.code_text; END IF;
        IF cond THEN
                dup_c_id:= NULL;
                SELECT s_ct.subcode_id, s_ct.supercode_id
                INTO dup_c_id, dup_cf_id
                FROM sch_<<$app_name$>>.codes      AS s_c
                   , sch_<<$app_name$>>.codes_tree AS s_ct
                   , sch_<<$app_name$>>.codes_tree AS t_ct
                WHERE s_ct.supercode_id = t_ct.supercode_id
                  AND s_ct.subcode_id   = s_c.code_id
                  AND s_c.code_text     = NEW.code_text
                  AND NEW.code_id       = t_ct.subcode_id
                  AND s_c.code_id      != NEW.code_id
                LIMIT 1;

                IF dup_c_id IS NOT NULL THEN
                        RAISE EXCEPTION 'An error occurred, when an % operation attempted on a code with ID "%" in the table "sch_<<$app_name$>>.codes"! Can''t set "code_text" field to new value "%", because it violates uniqueness constraint of "code_text" of codes under one codifier. Under codifier "%" there already is another code with such name, ID: %.', TG_OP, COALESCE(OLD.code_id, NEW.code_id), NEW.code_text, (get_code(FALSE, make_acodekeyl_byid(dup_cf_id))).code_text, dup_c_id;
                        IF    TG_OP = 'INSERT' THEN
                                RETURN NULL;
                        ELSIF TG_OP = 'UPDATE' THEN
                                RETURN OLD;
                        END IF;
                END IF;
        END IF;
        
        IF NEW.code_type != 'plain code' THEN
                c:= get_nonplaincode_by_str (NEW.code_text);
                IF NOT (c IS NULL) AND c.code_id != NEW.code_id THEN
                        RAISE EXCEPTION 'An error occurred, when an % operation attempted on a nonplain code with the name "%" in the table "sch_<<$app_name$>>.codes"! There already is a nonplain code with such name (ID: %) - duplicates are allowed only for plain codes and under different codifiers.', TG_OP, c.code_text, c.code_id;
                        IF    TG_OP = 'INSERT' THEN
                                RETURN NULL;
                        ELSIF TG_OP = 'UPDATE' THEN
                                RETURN OLD;
                        END IF;
                END IF;
        END IF;

        RETURN NEW;
END;
$tri_codes_onmodify$ LANGUAGE plpgsql;

CREATE TRIGGER tri_codes_onmodify AFTER INSERT OR UPDATE ON sch_<<$app_name$>>.codes
    FOR EACH ROW EXECUTE PROCEDURE codes_onmodify();

-------------------------------------

CREATE OR REPLACE FUNCTION codes_names_onmodify() RETURNS trigger AS $codes_names_onmodify$ -- upd, ins
DECLARE
        cn sch_<<$app_name$>>.codes_names%ROWTYPE;
        co sch_<<$app_name$>>.codes%ROWTYPE;
        dup_c_id integer;
        dup_cf_id integer;
        cond boolean;
BEGIN
        cond:= TG_OP = 'INSERT'; IF NOT cond THEN cond:= NEW.name IS DISTINCT FROM OLD.name; END IF;
        IF cond THEN
                dup_c_id:= NULL;
                SELECT s_ct.subcode_id, s_ct.supercode_id
                INTO dup_c_id, dup_cf_id
                FROM sch_<<$app_name$>>.codes_names AS s_cn
                   , sch_<<$app_name$>>.codes_tree  AS s_ct
                   , sch_<<$app_name$>>.codes_tree  AS t_ct
                WHERE s_ct.supercode_id = t_ct.supercode_id
                  AND s_ct.subcode_id   = s_cn.code_id
                  AND s_cn.name         = NEW.name
                  AND NEW.code_id       = t_ct.subcode_id
                  AND s_cn.code_id     != NEW.code_id
                LIMIT 1;

                IF dup_c_id IS NOT NULL THEN
                        IF    TG_OP = 'INSERT' THEN
                                RAISE EXCEPTION 'An error occurred, when an % operation attempted on a code with ID "%" in the table "sch_<<$app_name$>>.codes_names"! Can''t set "name" field to new value "%", because it violates uniqueness constraint of "name" of codes under one codifier. Under codifier "%" there already is another code with such name, ID: %.', TG_OP, NEW.code_id, NEW.name, (get_code(FALSE, make_acodekeyl_byid(dup_cf_id))).code_text, dup_c_id;
                        ELSIF TG_OP = 'UPDATE' THEN
                                RAISE EXCEPTION 'An error occurred, when an % operation attempted on a code with ID "%" in the table "sch_<<$app_name$>>.codes_names"! Can''t set "name" field to new value "%", because it violates uniqueness constraint of "name" of codes under one codifier. Under codifier "%" there already is another code with such name, ID: %.', TG_OP, OLD.code_id, NEW.name, (get_code(FALSE, make_acodekeyl_byid(dup_cf_id))).code_text, dup_c_id;
                        END IF;
                END IF;
        END IF;
        
        co:= get_code(FALSE, make_acodekeyl_byid(NEW.code_id));

        IF co.code_type != 'plain code' THEN
                dup_cf_id:= NULL;

                SELECT c.code_id
                INTO dup_cf_id
                FROM sch_<<$app_name$>>.codes_names AS co_n
                   , sch_<<$app_name$>>.codes       AS c
                WHERE c.code_id != NEW.code_id
                  AND c.code_type != 'plain code'
                  AND co_n.code_id = c.code_id
                  AND co_n.lng_of_name = NEW.lng_of_name
                  AND co_n.name = NEW.name;

                IF dup_cf_id IS NOT NULL THEN
                        RAISE EXCEPTION 'An error occurred, when an % operation attempted on a nonplain code with the name "%" (language: %) in the table "sch_<<$app_name$>>.codes_names"! There already is a nonplain code with such name (ID: %) - duplicates are allowed only for plain codes and under different codifiers.', TG_OP, NEW.name, (get_code(FALSE, make_acodekeyl_byid(NEW.lng_of_name))).code_text, dup_cf_id;
                END IF;
        END IF;

        RETURN NEW;
END;
$codes_names_onmodify$ LANGUAGE plpgsql;

CREATE TRIGGER tri_codes_names_onmodify AFTER INSERT OR UPDATE ON sch_<<$app_name$>>.codes_names
    FOR EACH ROW EXECUTE PROCEDURE codes_names_onmodify();

-- CREATE ...
-- GRANT ...

-- Sometimes we want to insert some data, before creating triggers.
\i ../data/data.sql 

-- CREATE TRIGGER ...
