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

\echo NOTICE >>>>> cf_dedictbls.init.sql [BEGIN]

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION tableoid_is_in_this_schema(par_table_oid oid) RETURNS boolean
LANGUAGE SQL
AS $$   SELECT TRUE
        FROM pg_class AS p, pg_namespace AS pns
        WHERE p.relnamespace = pns.oid AND p.oid = $1 AND p.relkind = 'r' AND pns.nspname = 'sch_<<$app_name$>>';
$$;

-------------------------------

CREATE OR REPLACE FUNCTION dct_row_belongsnot_to_codifiers(par_table_oid oid, par_code_id integer) RETURNS boolean
LANGUAGE SQL
AS $$   SELECT TRUE
        FROM (SELECT dct.codifier_id
              FROM dedicated_codifiertables AS dct
              WHERE dct.table_oid = $1
             ) AS t1
                 LEFT OUTER JOIN
             (SELECT ct.supercode_id AS codifier_id, 1 AS pers
              FROM codes_tree AS ct
              WHERE ct.subcode_id = $2
             ) AS t2
                 USING (codifier_id)
           , codes_tree AS ct
        WHERE pers IS NULL
        LIMIT 1;
$$;

-------------------------------

CREATE OR REPLACE FUNCTION dct_code_text_is_valid(par_code_id integer, par_code_text varchar) RETURNS boolean
LANGUAGE SQL
AS $$   SELECT TRUE
        FROM codes AS c
        WHERE ROW($1, $2) = ROW(c.code_id, c.code_text)
$$;
-------------------------------

CREATE OR REPLACE FUNCTION dedicated_codifiertable_by_tabname(par_table_name regclass) RETURNS SETOF sch_<<$app_name$>>.dedicated_codifiertables
LANGUAGE SQL
AS $$
        SELECT ic.*
        FROM sch_<<$app_name$>>.dedicated_codifiertables AS ic
           , pg_class AS pc
           , pg_namespace AS pns
        WHERE ic.table_oid    = pc.oid
          AND pc.relname      = $1 :: name
          AND pc.relnamespace = pns.oid
          AND pns.nspname     = 'sch_<<$app_name$>>'
          AND pc.relkind      = 'r'
$$;

-------------------------------

CREATE OR REPLACE FUNCTION new_dedicated_codifiertable(par_cf_key t_code_key_by_lng, par_tablename name, par_table_exists boolean, par_fullindexing boolean) RETURNS integer
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE cf_code sch_<<$app_name$>>.codes%ROWTYPE;
        t_oid oid;
        rows_cnt integer;
BEGIN
        cf_code:= get_codifier(FALSE, par_cf_key);

        IF NOT par_table_exists THEN
                EXECUTE 'CREATE TABLE ' || quote_ident(par_tablename :: varchar) || ' ('
                     || '  code_id     integer PRIMARY KEY'
                     || ', code_text   varchar NOT NULL UNIQUE USING INDEX TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs'
                     || ', FOREIGN KEY (code_id) REFERENCES codes(code_id) ON DELETE CASCADE ON UPDATE CASCADE'
                     || ', CONSTRAINT cnstr_dct_row_belongs_to_codifiers CHECK (dct_row_belongsnot_to_codifiers(tableoid, code_id) IS DISTINCT FROM TRUE)'
                     || ', CONSTRAINT cnstr_dct_code_text_is_valid CHECK (dct_code_text_is_valid(code_id, code_text) IS NOT DISTINCT FROM TRUE)'
                     || ') TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>';

                EXECUTE 'COMMENT ON TABLE ' || quote_ident(par_tablename :: varchar) || ' IS ''Dedicated codifier-table. Registered in "dedicated_codifiertables" table. Do not DROP it directly, use "remove_dedicated_codifiertable(par_cf_key t_code_key_by_lng, par_tablename regclass)" function instead !!!''';

                EXECUTE 'GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE ' || quote_ident(par_tablename :: varchar) || ' TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin';
                EXECUTE 'GRANT SELECT                         ON TABLE ' || quote_ident(par_tablename :: varchar) || ' TO user_db<<$db_name$>>_app<<$app_name$>>_data_reader';
        END IF;

        SELECT pc.oid INTO t_oid
        FROM pg_class AS pc
           , pg_namespace AS pns
        WHERE pc.relname      = par_tablename :: name
          AND pc.relnamespace = pns.oid
          AND pns.nspname     = 'sch_<<$app_name$>>'
          AND pc.relkind      = 'r';

        GET DIAGNOSTICS rows_cnt = ROW_COUNT;
        IF rows_cnt < 1 THEN
                RAISE EXCEPTION 'Error in function "new_dedicated_codifiertable"! Dedicated codifier-table ("%") not found!', par_tablename;
        END IF;

        INSERT INTO dedicated_codifiertables (codifier_id, codifier_text, table_oid, full_indexing)
        VALUES(cf_code.code_id, cf_code.code_text, t_oid, par_fullindexing);

        IF par_fullindexing THEN
                EXECUTE 'INSERT INTO ' || quote_ident(par_tablename :: varchar) || '(code_id, code_text) '
                     || 'SELECT c.code_id, c.code_text '
                     || 'FROM codes AS c, codes_tree AS ct '
                     || 'WHERE ct.supercode_id = ' || cf_code.code_id || ' AND ct.subcode_id = c.code_id';
        END IF;

        RETURN 1;
END;
$$;

COMMENT ON FUNCTION new_dedicated_codifiertable(par_cf_key t_code_key_by_lng, par_tablename name, par_table_exists boolean, par_fullindexing boolean) IS
'If "par_table_exists" is FALSE, then new table is created, else existing one is used.
If "par_fullindexing" is TRUE, then dedicated codifier-table is posed as one with full copy of codifier content (1 level of); all data is copied in dedicated codifier-table immediately.
Notice: if "par_table_exists" is FALSE, then function will only work, given caller role has permission to create tables in given schema.
';

-------------------------------

CREATE OR REPLACE FUNCTION remove_dedicated_codifiertable(par_cf_key t_code_key_by_lng, par_tablename regclass, par_drop_table boolean) RETURNS integer
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE cf_code sch_<<$app_name$>>.codes%ROWTYPE;
        tab_oid oid;
        tab_name regclass;
BEGIN   IF par_drop_table IS NULL THEN
                RAISE EXCEPTION 'Parameter "par_drop_table" is not allowed to be NULL.';
        END IF;
        IF par_cf_key IS NULL AND NOT par_drop_table THEN
                RAISE EXCEPTION 'Parameter "par_cf_key" is not allowed to be NULL, or "par_drop_table" should be TRUE.';
        END IF;

        SELECT pc.oid INTO tab_oid
        FROM pg_class AS pc, pg_namespace AS pns
        WHERE pc.relname      = par_tablename :: name
          AND pc.relnamespace = pns.oid
          AND pns.nspname     = 'sch_<<$app_name$>>'
          AND pc.relkind      = 'r';

        IF NOT par_drop_table THEN
                cf_code:= get_codifier(FALSE, par_cf_key);
                IF (SELECT TRUE FROM dedicated_codifiertables AS t WHERE ROW(t.table_oid, t.codifier_id) = ROW(tab_oid, cf_code.code_id)) IS DISTINCT FROM TRUE THEN
                        RAISE EXCEPTION 'Dedicated codifier-table not found for keys: codifier: %; table: "%".', cf_code, par_tablename;
                END IF;

                DELETE FROM dedicated_codifiertables
                WHERE table_oid = tab_oid
                  AND codifier_id = cf_code.code_id;
        ELSE
                EXECUTE 'DELETE FROM ' || quote_ident(par_tablename :: varchar);

                DELETE FROM dedicated_codifiertables
                WHERE table_oid = tab_oid;

                EXECUTE 'DROP TABLE ' || quote_ident(par_tablename :: varchar);
        END IF;

        RETURN 1;
END;
$$;

COMMENT ON FUNCTION remove_dedicated_codifiertable(par_cf_key t_code_key_by_lng, par_tablename regclass, par_drop_table boolean) IS
'If "par_drop_table" is TRUE, then "par_cf_key" is ignored. The table gets dropped only when "par_drop_table" is TRUE.
Notice: if "par_drop_table" is TRUE, then function will only work, given caller role has permission to drop tables in given schema.
';

-------------------------------

CREATE OR REPLACE FUNCTION check_cf_accord_w_dedicated_codifiertable(par_dedicated_codifiertable_id integer, par_codifier_key t_code_key, par_table_oid oid) RETURNS boolean
LANGUAGE plpgsql
SET search_path = sch_<<$app_name$>> -- , comn_funs, public
AS $$
DECLARE dct_row sch_<<$app_name$>>.dedicated_codifiertables%ROWTYPE;
        cf_code t_code_key;
        t_name varchar;
        c_id integer; rows_cnt integer;
        rec record;
BEGIN
        IF par_codifier_key.code_id IS DISTINCT FROM (get_nonplaincode_by_str(par_codifier_key.code_text)).code_id THEN
                RAISE EXCEPTION 'Error in table "dedicated_codifiertables"! Codifier text does not accord with codifier ID! Dedicated codifier-table ID: %.', par_dedicated_codifiertable_id;
        END IF;

        SELECT pc.relname :: varchar INTO t_name
        FROM pg_class AS pc
           , pg_namespace AS pns
        WHERE par_table_oid   = pc.oid
          AND pc.relnamespace = pns.oid
          AND pns.nspname     = 'sch_<<$app_name$>>'
          AND pc.relkind      = 'r';

        EXECUTE 'SELECT dct.code_id '
             || 'FROM ' || quote_ident(t_name) || ' AS dct '
             || 'WHERE dct.code_id NOT IN (SELECT ct.subcode_id FROM codes_tree AS ct WHERE ct.supercode_id = ' || par_codifier_key.code_id || ') '
             || 'LIMIT 1 '
        INTO c_id;

        GET DIAGNOSTICS rows_cnt = ROW_COUNT;
        IF rows_cnt > 0 THEN
                RAISE EXCEPTION 'Error in table "dedicated_codifiertables"! Dedicated codifier-table contains code that doesn''t belong to codifier! Dedicated codifier-table ID: %; Codifier ID: %; Code ID: %.', par_dedicated_codifiertable_id, par_codifier_key.code_id, c_id;
        END IF;

        RETURN TRUE;
END;
$$;

COMMENT ON FUNCTION check_cf_accord_w_dedicated_codifiertable(par_dedicated_codifiertable_id integer, par_codifier_key t_code_key, par_table_oid oid) IS
'Checks row in the "dedicated_codifiertables" table:
(1) Codifier text accords with codifier ID.
(2) All codes listed in the subject table are subcodes to subject codifier.
';

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

GRANT EXECUTE ON FUNCTION remove_dedicated_codifiertable(par_cf_key t_code_key_by_lng, par_tablename regclass, par_drop_table boolean)  TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION new_dedicated_codifiertable(par_cf_key t_code_key_by_lng, par_tablename name, par_table_exists boolean, par_fullindexing boolean)  TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION dedicated_codifiertable_by_tabname(par_table_name regclass)  TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION check_cf_accord_w_dedicated_codifiertable(par_dedicated_codifiertable_id integer, par_codifier_key t_code_key, par_table_oid oid)  TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION tableoid_is_in_this_schema(par_table_oid oid) TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION dct_row_belongsnot_to_codifiers(par_table_oid oid, par_code_id integer)  TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION dct_code_text_is_valid(par_code_id integer, par_code_text varchar)  TO user_db<<$db_name$>>_app<<$app_name$>>_data_admin;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

\echo NOTICE >>>>> cf_dedictbls.init.sql [END]
