-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
-- 
-- All rights reserved.
-- 
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

-- Must be called from inside of "structure.sql", orelse uncomment these 2 lines:
-- \c <<$db_name$>> user_<<$app_name$>>_owner
-- SET search_path TO sch_<<$app_name$>>, public; -- sets only for current session

-- INSERT INTO ...

-- usual codifiers         :    10 -       2999
-- status sets             :  3000 -       5999
-- other types of codifiers:  6000 -       9999 
-- plain codes             : 10000 - 2147483647
-------
-- root codifier                       : 0
-- codifier of usual codifiers         : 1
-- codifier of status sets             : 2
-- codifier of other types of codifiers: 3

INSERT INTO codes (
        code_ID
      , codifier_ID
      , code
) VALUES 
        (1, 0, 'Usual codifiers')
      , (2, 0, 'Statuses sets')
      , (3, 0, 'Other types of codifiers')
      ;

INSERT INTO codifiers (
        codifier_code_ID
      , codifier_type
      , default_code_id
) VALUES 
        (1, 'codifier', NULL)
      , (2, 'codifier', NULL)
      , (3, 'codifier', NULL)
      ;

INSERT INTO codes_names (
        code_ID
      , entity
      , lng_of_name
      , name
      , description
) VALUES 
        (0, 'codifier', 'eng', 'Root codifier'                       , 'Root codifier of all codifiers. Known codes: 0, 1, 2, 3.')
      , (1, 'codifier', 'eng', 'Codifier of usual codifiers'         , 'Codifier of usual codifiers. Subordinate codes space: 10-2999 (no automatic check for this constraint).')
      , (2, 'codifier', 'eng', 'Codifier of statuses sets'           , 'Codifier of statuses sets. Subordinate codes space: 3000-5999 (no automatic check for this constraint).')
      , (3, 'codifier', 'eng', 'Codifier of other types of codifiers', 'Codifier of other types of codifiers (not statuses sets, nor usual codifiers). Subordinate codes space: 6000-9999 (no automatic check for this constraint).')
      ;
