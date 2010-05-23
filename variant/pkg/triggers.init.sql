-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> triggers.init.sql [BEGIN]

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION codes_onmodify() RETURNS trigger
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $tri_codes_onmodify$ -- upd, ins
DECLARE
        c sch_<<$app_name$>>.codes%ROWTYPE;
        idxtab_name regclass;
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
                END IF;
        END IF;

        IF NEW.code_type != 'plain code' THEN
                c:= get_nonplaincode_by_str (NEW.code_text);
                IF NOT (c IS NULL) AND c.code_id != NEW.code_id THEN
                        RAISE EXCEPTION 'An error occurred, when an % operation attempted on a nonplain code with the name "%" in the table "sch_<<$app_name$>>.codes"! There already is a nonplain code with such name (ID: %) - duplicates are allowed only for plain codes and under different codifiers.', TG_OP, c.code_text, c.code_id;
                END IF;
        END IF;

        IF TG_OP = 'UPDATE' THEN
            IF OLD.code_text IS DISTINCT FROM NEW.code_text THEN
                    UPDATE sch_<<$app_name$>>.dedicated_codifiertables SET codifier_text = NEW.code_text WHERE codifier_id = NEW.code_id;

                    FOR idxtab_name IN
                        SELECT DISTINCT pc.relname :: regclass
                        FROM sch_<<$app_name$>>.dedicated_codifiertables AS ic
                           , sch_<<$app_name$>>.codes_tree AS ct
                           , pg_class AS pc
                           , pg_namespace AS pns
                        WHERE ct.subcode_id   = NEW.code_id
                          AND ic.codifier_id  = ct.supercode_id
                          AND ic.table_oid    = pc.oid
                          AND pc.relnamespace = pns.oid
                          AND pns.nspname     = 'sch_<<$app_name$>>'
                          AND pc.relkind      = 'r'
                    LOOP
                        EXECUTE 'UPDATE sch_<<$app_name$>>.' || quote_ident(idxtab_name :: varchar) || ' SET code_text = ' || quote_literal(NEW.code_text) || ' WHERE code_id = ' || NEW.code_id;
                    END LOOP;
            END IF;
        END IF;

        RETURN NEW;
END;
$tri_codes_onmodify$;

CREATE TRIGGER tri_codes_onmodify AFTER INSERT OR UPDATE ON sch_<<$app_name$>>.codes
    FOR EACH ROW EXECUTE PROCEDURE codes_onmodify();

-------------------------------------

CREATE OR REPLACE FUNCTION codes_tree_onmodify() RETURNS trigger
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $tri_codes_tree_onmodify$ -- upd, ins, del
DECLARE new_cfr_name varchar;
        subcode_name varchar;
        subcode_namel varchar;
        cnt integer;
        lng integer;
        idxtab_name regclass;
        code_t code_type;
BEGIN
        CASE TG_OP
            WHEN 'DELETE' THEN
                FOR idxtab_name IN
                        SELECT pc.relname
                        FROM sch_<<$app_name$>>.dedicated_codifiertables AS ic
                           , pg_class AS pc
                           , pg_namespace AS pns
                        WHERE ic.codifier_id = OLD.supercode_id
                          AND ic.table_oid    = pc.oid
                          AND pc.relnamespace = pns.oid
                          AND pns.nspname     = 'sch_<<$app_name$>>'
                          AND pc.relkind      = 'r'
                LOOP
                        EXECUTE 'DELETE FROM sch_<<$app_name$>>.' || quote_ident(idxtab_name :: varchar) || ' WHERE code_id = ' || OLD.subcode_id;
                END LOOP;

                RETURN OLD;
            WHEN 'INSERT', 'UPDATE' THEN
                SELECT code_text, code_type
                INTO new_cfr_name, code_t
                FROM sch_<<$app_name$>>.codes AS c
                WHERE c.code_id = NEW.supercode_id;

                IF code_t = 'plain code' THEN
                        RAISE EXCEPTION 'An error occurred, when trying to register a plain code with the name "%" in the table "sch_<<$app_name$>>.codes_tree"! Plain codes (code_type field) are not allowed to have subcodes, to become codifiers.', new_cfr_name;
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
                END IF;

                lng := NULL;

                SELECT tn.lng_of_name, cn.name
                INTO lng, subcode_namel
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
                        RAISE EXCEPTION 'An error occurred, when trying to register a subcode with the with name "%" in language "%" in the codifier "%"! The codifier already contains a code, that has same name in same language. No duplicate codes are allowed in one codifier.', subcode_namel, (get_code(TRUE, make_acodekeyl_byid(lng))).code_text, new_cfr_name;
                END IF;

                IF TG_OP = 'INSERT' THEN
                    FOR idxtab_name IN
                        SELECT DISTINCT pc.relname :: regclass
                        FROM sch_<<$app_name$>>.dedicated_codifiertables AS ic
                           , pg_class AS pc
                           , pg_namespace AS pns
                        WHERE ic.codifier_id  = NEW.supercode_id
                          AND ic.table_oid    = pc.oid
                          AND ic.full_indexing
                          AND pc.relnamespace = pns.oid
                          AND pns.nspname     = 'sch_<<$app_name$>>'
                          AND pc.relkind      = 'r'
                    LOOP
                        EXECUTE 'INSERT INTO sch_<<$app_name$>>.' || quote_ident(idxtab_name :: varchar) || '(code_id, code_text) VALUES(' || NEW.subcode_id || ', ' || quote_literal(subcode_name) || ')';
                    END LOOP;
                ELSE -- TG_OP = 'UPDATE'
                    IF ROW(OLD.supercode_id, OLD.subcode_id) IS DISTINCT FROM ROW(OLD.supercode_id, OLD.subcode_id) THEN
                            FOR idxtab_name IN
                                SELECT pc.relname :: regclass
                                FROM sch_<<$app_name$>>.dedicated_codifiertables AS ic
                                   , pg_class AS pc
                                   , pg_namespace AS pns
                                WHERE ic.codifier_id = OLD.supercode_id
                                  AND ic.table_oid    = pc.oid
                                  AND pc.relnamespace = pns.oid
                                  AND pns.nspname     = 'sch_<<$app_name$>>'
                                  AND pc.relkind      = 'r'
                            LOOP
                                EXECUTE 'DELETE FROM sch_<<$app_name$>>.' || quote_ident(idxtab_name :: varchar) || ' WHERE code_id = ' || OLD.subcode_id;
                            END LOOP;
                            -----
                            FOR idxtab_name IN
                                SELECT DISTINCT pc.relname :: regclass
                                FROM sch_<<$app_name$>>.dedicated_codifiertables AS ic
                                   , pg_class AS pc
                                   , pg_namespace AS pns
                                WHERE ic.codifier_id  = NEW.supercode_id
                                  AND ic.table_oid    = pc.oid
                                  AND ic.full_indexing
                                  AND pc.relnamespace = pns.oid
                                  AND pns.nspname     = 'sch_<<$app_name$>>'
                                  AND pc.relkind      = 'r'
                            LOOP
                                EXECUTE 'INSERT INTO sch_<<$app_name$>>.' || quote_ident(idxtab_name :: varchar) || '(code_id, code_text) VALUES(' || NEW.subcode_id || ', ' || quote_literal(subcode_name) || ')';
                            END LOOP;
                    END IF;
                END IF;

                RETURN NEW;
        END CASE;
END;
$tri_codes_tree_onmodify$;

CREATE TRIGGER tri_codes_tree_onmodify AFTER INSERT OR UPDATE OR DELETE ON sch_<<$app_name$>>.codes_tree
    FOR EACH ROW EXECUTE PROCEDURE codes_tree_onmodify();

-------------------------------------

CREATE OR REPLACE FUNCTION codes_names_onmodify() RETURNS trigger
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $codes_names_onmodify$ -- upd, ins
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
$codes_names_onmodify$;

CREATE TRIGGER tri_codes_names_onmodify AFTER INSERT OR UPDATE ON sch_<<$app_name$>>.codes_names
    FOR EACH ROW EXECUTE PROCEDURE codes_names_onmodify();

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

GRANT EXECUTE ON FUNCTION codes_tree_onmodify()   TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION codes_onmodify()        TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION codes_names_onmodify()  TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

\echo NOTICE >>>>> triggers.init.sql [END]