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

-- one hunded sch_<<$app_name$>>.codes reserved for the most fundamental codifiers roots
CREATE SEQUENCE codifiers_ids_seq -- WARNIG!!! Some alterations are in the data.sql
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

INSERT INTO codes (code_id, code_type, code_text) VALUES (0, 'metacodifier', 'Root codifier');

CREATE INDEX codestexts_in_codes_idx ON codes(code_text) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;

CREATE TABLE codes_tree (
        supercode_id      integer NOT NULL REFERENCES codes (code_id) ON DELETE CASCADE ON UPDATE CASCADE
      , subcode_id        integer NOT NULL REFERENCES codes (code_id) ON DELETE CASCADE ON UPDATE CASCADE
      , dflt_subcode_isit boolean NOT NULL DEFAULT FALSE
      , PRIMARY KEY (supercode_id, subcode_id)
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

CREATE INDEX codifiers_idx ON codes_tree(supercode_id) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;

CREATE TABLE codes_names (
        code_id     integer NOT NULL PRIMARY KEY 
      , FOREIGN KEY (code_id)     REFERENCES codes(code_id) ON DELETE CASCADE ON UPDATE CASCADE
      , FOREIGN KEY (lng_of_name) REFERENCES languages(iso639_3_code) ON DELETE RESTRICT ON UPDATE CASCADE
) INHERITS (named_in_languages) 
  TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

ALTER TABLE codes_names ALTER COLUMN entity SET DEFAULT 'code';

-------------------------------------

GRANT USAGE ON SEQUENCE codifiers_ids_seq   TO user_<<$app_name$>>_data_admin;
GRANT USAGE ON SEQUENCE plain_codes_ids_seq TO user_<<$app_name$>>_data_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE codes       TO user_<<$app_name$>>_data_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE codes_names TO user_<<$app_name$>>_data_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE codes_tree  TO user_<<$app_name$>>_data_admin;
GRANT SELECT                         ON TABLE codes       TO user_<<$app_name$>>_data_reader;
GRANT SELECT                         ON TABLE codes_names TO user_<<$app_name$>>_data_reader;
GRANT SELECT                         ON TABLE codes_tree  TO user_<<$app_name$>>_data_reader;

-------------------------------------

\i functions.init.sql 

-------------------------------------

CREATE OR REPLACE FUNCTION codes_tree_onmodify() RETURNS trigger AS $tri_codes_tree_onmodify$ -- upd, ins
DECLARE
        new_cfr_name varchar;
        subcode_name varchar;
        cnt integer;
        code_t code_type;
BEGIN
        SELECT code_text, code_type
        INTO new_cfr_name, code_t
        FROM sch_<<$app_name$>>.codes AS c
        WHERE c.code_id = NEW.supercode_id;

        IF code_t = 'plain code' THEN
                RAISE EXCEPTION 'An error occurred, when trying to register a plain code with the name "%" in the table "sch_<<$app_name$>>.codes_tree"! Plain sch_<<$app_name$>>.codes (code_type field) are not allowed to have subcodes, to become codifiers.', new_cfr_name;
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
                RAISE EXCEPTION 'An error occurred, when trying to register a subcode with the name "%" in the codifier "%"! The codifier already contains such code. No duplicate sch_<<$app_name$>>.codes are allowed in one codifier.', subcode_name, new_cfr_name;
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

CREATE OR REPLACE FUNCTION codes_onmodify() RETURNS trigger AS $tri_codes_onmodify$ -- upd, ins
DECLARE
        c sch_<<$app_name$>>.codes%ROWTYPE;
BEGIN
        IF NEW.code_type != 'plain code' THEN
                c:= get_nonplaincode_by_codestr (NEW.code_text);
                IF NOT (c IS NULL) AND c.code_id != NEW.code_id THEN
                        RAISE EXCEPTION 'An failure occurred, when an % operation attempted on a nonplain code with the name "%" in the table "sch_<<$app_name$>>.codes"! There already is a nonplain code with such name (ID: %) - duplicates are allowed only for plain sch_<<$app_name$>>.codes and under different codifiers.', TG_OP, c.code_text, c.code_id;
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

-- CREATE ...
-- GRANT ...

-- Sometimes we want to insert some data, before creating triggers.
\i ../data/data.sql 

-- CREATE TRIGGER ...
