-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
-- 
-- All rights reserved.
-- 
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\c <<$db_name$>> user_<<$app_name$>>_owner

SET search_path TO sch_<<$app_name$>>, public; -- sets only for current session
\set ECHO queries

SELECT * FROM codes;
SELECT * FROM codifiers;
SELECT * FROM codes_names;

SELECT * FROM get_codes_by_codestr('Root codifier', 'Usual codifiers');
SELECT get_one_code_by_codestr('Root codifier', 'Usual codifiers');
SELECT get_code_by_codeid(2);
SELECT * FROM get_codifiers_by_codifierstr('Usual codifiers');
SELECT get_one_codifier_by_codifierstr('Usual codifiers');
SELECT get_codifier_by_codifierid(2);

-- make sure this script doesn't output too much data - it all goes to log.

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
