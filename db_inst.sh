#!/bin/sh
#
# Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
#
# All rights reserved.
#
# For license and copyright information, see the file COPYRIGHT
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------

cd `dirname $0`
./platforms/PostgreSQL/Linux/db_inst.sh $1 $2 $3 $4 $5
