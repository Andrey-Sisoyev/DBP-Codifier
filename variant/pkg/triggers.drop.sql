-- Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
--
-- All rights reserved.
--
-- For license and copyright information, see the file COPYRIGHT

--------------------------------------------------------------------------
--------------------------------------------------------------------------

\echo NOTICE >>>>> triggers.drop.sql [BEGIN]

DROP TRIGGER IF EXISTS tri_codes_tree_onmodify ON codes_tree;
DROP TRIGGER IF EXISTS tri_codes_onmodify ON codes;

DROP FUNCTION IF EXISTS codes_onmodify();
DROP FUNCTION IF EXISTS codes_tree_onmodify();

\echo NOTICE >>>>> triggers.drop.sql [END]