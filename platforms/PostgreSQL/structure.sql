-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
-- 
-- All rights reserved.
-- 
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\c <<$db_name$>> user_<<$app_name$>>_owner

SET search_path TO sch_<<$app_name$>>, public; -- sets only for current session

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

DROP FUNCTION IF EXISTS get_codes_by_codestr(par_codifier varchar, par_code varchar);
DROP FUNCTION IF EXISTS get_one_code_by_codestr(par_codifier varchar, par_code varchar);
DROP FUNCTION IF EXISTS get_code_by_codeid(par_code_id integer);
DROP FUNCTION IF EXISTS get_codifiers_by_codifierstr(par_codifier varchar);
DROP FUNCTION IF EXISTS get_one_codifier_by_codifierstr(par_codifier varchar);
DROP FUNCTION IF EXISTS get_codifier_by_codifierid(par_codifier_id integer);

DROP TYPE IF EXISTS codifier_view;

DROP INDEX IF EXISTS codes_in_codes_idx;
DROP INDEX IF EXISTS codifiers_of_codes_idx;

ALTER TABLE codes
    DROP CONSTRAINT cnstr_codes_fk_codifiers;
ALTER TABLE codifiers
    DROP CONSTRAINT cnstr_codifiers_fk_codes;

DROP TABLE IF EXISTS codifiers;
DROP TABLE IF EXISTS codes_names;
DROP TABLE IF EXISTS codes;

DROP SEQUENCE IF EXISTS plain_codes_ids_seq;
DROP SEQUENCE IF EXISTS usual_codifier_ids_seq;
DROP SEQUENCE IF EXISTS statuses_sets_ids_seq;
DROP SEQUENCE IF EXISTS other_codifiers_ids_seq;

DROP TYPE IF EXISTS codifier_types;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

CREATE TYPE codifier_types AS ENUM ('codifier', 'statuses-set', 'undefined', 'unclassified');

CREATE SEQUENCE plain_codes_ids_seq 
        INCREMENT BY 10
        MINVALUE 10000 
        MAXVALUE 2147483640
        START WITH 10000 
        NO CYCLE;

CREATE SEQUENCE usual_codifier_ids_seq 
        INCREMENT BY 10
        MINVALUE 10 
        MAXVALUE 2990
        START WITH 10 
        NO CYCLE;

CREATE SEQUENCE statuses_sets_ids_seq
        INCREMENT BY 10
        MINVALUE 3000 
        MAXVALUE 5990
        START WITH 3000 
        NO CYCLE;

CREATE SEQUENCE other_codifiers_ids_seq 
        INCREMENT BY 10
        MINVALUE 6000 
        MAXVALUE 9990
        START WITH 6000 
        NO CYCLE;
       
-- usual codifiers         :    10 -       2999
-- status sets             :  3000 -       5999
-- other types of codifiers:  6000 -       9999 
-- plain codes             : 10000 - 2147483647
-------
-- root codifier                       : 0
-- codifier of usual codifiers         : 1
-- codifier of status sets             : 2
-- codifier of other types of codifiers: 3
-------
-- these codes ranges constraints aren't automatically checked
CREATE TABLE codes (
        code_id     integer NOT NULL PRIMARY KEY 
      , codifier_id integer NOT NULL
      , code        varchar NOT NULL
      , additional_field_1 varchar NULL
      , additional_field_2 varchar NULL
      , additional_field_3 varchar NULL
      , additional_field_4 varchar NULL
      , additional_field_5 varchar NULL
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

CREATE INDEX codes_in_codes_idx ON codes(code) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;
CREATE INDEX codifiers_of_codes_idx ON codes(codifier_id) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>_idxs;

CREATE TABLE codifiers (
        codifier_code_id integer        NOT NULL PRIMARY KEY
      , codifier_type    codifier_types NOT NULL DEFAULT 'undefined'
      , default_code_id  integer            NULL REFERENCES codes (code_id)
) TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

INSERT INTO codes (
        code_id
      , codifier_id
      , code
) VALUES (0, 0, 'Root codifier');

INSERT INTO codifiers (
        codifier_code_id
      , codifier_type
      , default_code_id
) VALUES (0, 'codifier', 0);

ALTER TABLE codes 
    ADD CONSTRAINT cnstr_codes_fk_codifiers 
        FOREIGN KEY(codifier_id) REFERENCES codifiers (codifier_code_id) ON DELETE RESTRICT;

ALTER TABLE codifiers
    ADD CONSTRAINT cnstr_codifiers_fk_codes 
        FOREIGN KEY(codifier_code_id) REFERENCES codes (code_id) ON DELETE RESTRICT;

CREATE TABLE codes_names (
        code_id     integer NOT NULL PRIMARY KEY 
      , FOREIGN KEY (code_id)     REFERENCES codes(code_id) ON DELETE CASCADE ON UPDATE CASCADE
      , FOREIGN KEY (lng_of_name) REFERENCES languages(iso639_3_code) ON DELETE RESTRICT ON UPDATE CASCADE
) INHERITS (named_in_languages) 
  TABLESPACE tabsp_<<$db_name$>>_<<$app_name$>>;

ALTER TABLE codes_names ALTER COLUMN entity SET DEFAULT 'code';

-------------------------------------

CREATE OR REPLACE FUNCTION get_codes_by_codestr(par_codifier varchar, par_code varchar) RETURNS SETOF codes AS $$
        SELECT c.* 
        FROM codes AS c, 
            (SELECT c2.code_id FROM codes AS c2 WHERE c2.code = $1) AS MatchedCodifiers 
        WHERE MatchedCodifiers.code_id=c.codifier_id
          AND c.code = $2;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_one_code_by_codestr(par_codifier varchar, par_code varchar) RETURNS codes AS $$
    SELECT * FROM get_codes_by_codestr ($1, $2) LIMIT 1;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_code_by_codeid(par_code_id integer) RETURNS codes AS $$
        SELECT c.* 
        FROM codes AS c
        WHERE c.code_id=$1;
$$ LANGUAGE SQL;

CREATE TYPE codifier_view AS (
        codifier_code_id  integer 
      , super_codifier_id integer 
      , codifier_code     varchar 
      , codifier_type     codifier_types
      , default_code_id   integer 
);

CREATE OR REPLACE FUNCTION get_codifiers_by_codifierstr(par_codifier varchar) RETURNS SETOF codifier_view AS $$
        SELECT cf.codifier_code_id
             , c.codifier_id AS super_codifier_id
             , c.code AS codifier_code
             , cf.codifier_type
             , cf.default_code_id
        FROM codes AS c, codifiers AS cf 
        WHERE c.code = $1 AND c.code_id = cf.codifier_code_id;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_one_codifier_by_codifierstr(par_codifier varchar) RETURNS codifier_view AS $$
    SELECT * FROM get_codifiers_by_codifierstr ($1) LIMIT 1;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_codifier_by_codifierid(par_codifier_id integer) RETURNS codifier_view AS $$
        SELECT cf.codifier_code_id
             , c.codifier_id AS super_codifier_id
             , c.code AS codifier_code
             , cf.codifier_type
             , cf.default_code_id
        FROM codes AS c, codifiers AS cf 
        WHERE c.code_id = $1 AND c.code_id = cf.codifier_code_id;
$$ LANGUAGE SQL;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE codes       TO user_<<$app_name$>>_data_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE codes_names TO user_<<$app_name$>>_data_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE codifiers   TO user_<<$app_name$>>_data_admin;
GRANT SELECT                         ON TABLE codes       TO user_<<$app_name$>>_data_reader;
GRANT SELECT                         ON TABLE codes_names TO user_<<$app_name$>>_data_reader;
GRANT SELECT                         ON TABLE codifiers   TO user_<<$app_name$>>_data_reader;

GRANT EXECUTE ON FUNCTION get_codes_by_codestr(par_codifier varchar, par_code varchar)    TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION get_one_code_by_codestr(par_codifier varchar, par_code varchar) TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION get_code_by_codeid(par_code_id integer)                         TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION get_codifiers_by_codifierstr(par_codifier varchar)              TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION get_one_codifier_by_codifierstr(par_codifier varchar)           TO user_<<$app_name$>>_data_admin;
GRANT EXECUTE ON FUNCTION get_codifier_by_codifierid(par_codifier_id integer)             TO user_<<$app_name$>>_data_admin;

GRANT EXECUTE ON FUNCTION get_codes_by_codestr(par_codifier varchar, par_code varchar)    TO user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_one_code_by_codestr(par_codifier varchar, par_code varchar) TO user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_code_by_codeid(par_code_id integer)                         TO user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_codifiers_by_codifierstr(par_codifier varchar)              TO user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_one_codifier_by_codifierstr(par_codifier varchar)           TO user_<<$app_name$>>_data_reader;
GRANT EXECUTE ON FUNCTION get_codifier_by_codifierid(par_codifier_id integer)             TO user_<<$app_name$>>_data_reader;

-- Sometimes we want to insert some data, before creating triggers.
\i data.sql 

-- CREATE TRIGGER ...
