#!/bin/sh
#
# Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
#
# All rights reserved.
#
# For license and copyright information, see the file COPYRIGHT
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------

dn=`dirname $0`
cd $dn/.. # cd platforms/PostgreSQL

test -e ./structure.sql && test -e ./init_schema.sql && test -e ./init_db.sql && test -e ./data.sql 
if [ ! $? -eq 0 ]; then
        echo "Failed! Not all SQL scripts are found!";exit
fi

cd ../.. # cd package-root

usage="Usage: `basename $0` <db_name> <new_or_existing_db> <app_name> <new_or_existing_app>\nSee docs/HOWTO for more info."

case $# in
	4);;
	5);;
	*)echo -e $usage;exit;;
esac;

case "$2" in
	"new");;
	"existing");;
	*)
	echo -e "Second argument must be either 'new' or 'existing'."
	echo -e "You provided this: $2" | cat -A
	echo -e "$usage"
	exit
	;;
esac;

case "$4" in
	"new");;
	"existing");;
	*)
	echo -e "Fourth argument must be either 'new' or 'existing'."
	echo -e "You provided this: $2" | cat -A
	echo -e "$usage"
	exit
	;;
esac;

case $PGDATA in
	'')echo "Failed! PGDATA environment variable must be set.";exit;;
esac;


mkdir _install;cd _install;
cp ../platforms/PostgreSQL/*.sql ./
cp -Rp ../platforms/PostgreSQL/test ./

sed_script='1,$ {;s/<<$db_name$>>/'"$1"'/g;s/<<$app_name$>>/'"$3"'/g;s_<<$PGDATA$>>_'"$PGDATA"'_g;}'

sed -i "$sed_script" ./*.sql ./test/*.sql

date_time=`date +"%Y.%m.%d %H:%M:%S"`
db_inst_log="db_inst.sh.log"
echo -e "\033[1;37m---------START-OF-FILE-----------\033[0;37m" > $db_inst_log
echo -e "\033[1;37mDB package install log file.\033[0;37m" >> $db_inst_log
echo -e "\033[1;37mDate, time:\033[0;37m \033[1;34m$date_time \033[0;37m" >> $db_inst_log
echo -e "\033[1;37mRun arguments ["`whoami`"]:\033[0;37m \033[1;34m$0 $1 $2 $3 $4 $5\033[0;37m" >> $db_inst_log
echo >> $db_inst_log
case $2 in
	'new')
	echo -e "\033[1;37m-----------------------------------------------------------\033[0;37m" >> $db_inst_log
	echo -e "\033[1;37m-------Running DB initialization script init_db.sql\033[0;37m" >> $db_inst_log;
	psql -f init_db.sql 2>&1 | cat >> $db_inst_log;
	;;
	'existing')
	echo -e "\033[1;37m-----------------------------------------------------------\033[0;37m" >> $db_inst_log
	echo -e "\033[1;37m-------Omitting DB initialization script init_db.sql\033[0;37m" >> $db_inst_log;
	;;
esac;

echo >> $db_inst_log

case $4 in
	'new')
	echo -e "\033[1;37m-----------------------------------------------------------\033[0;37m" >> $db_inst_log
	echo -e "\033[1;37m-------Running DB schema initialization script init_schema.sql\033[0;37m" >> $db_inst_log;
	psql -f init_schema.sql 2>&1 | cat  >> $db_inst_log;
	;;
	'existing')
	echo -e "\033[1;37m-----------------------------------------------------------\033[0;37m" >> $db_inst_log
	echo -e "\033[1;37m-------Ommitting DB schema initialization script init_schema.sql\033[0;37m" >> $db_inst_log;
	;;
esac;

echo >> $db_inst_log

echo -e "\033[1;37m-----------------------------------------------------------\033[0;37m" >> $db_inst_log
echo -e "\033[1;37m-------Running DB script structure.sql\n\033[0;37m" >> $db_inst_log
psql -f structure.sql 2>&1 | cat  >> $db_inst_log
echo -e "\033[1;37m-------DB initial data insertion script (data.sql) is run by structure.sql\033[0;37m" >> $db_inst_log;

echo >> $db_inst_log


echo -e "\033[1;37m-----------------------------------------------------------\033[0;37m" >> $db_inst_log
echo -e "\033[1;37m-------Data definition scripts finished.\033[0;37m" >> $db_inst_log
echo -e "\033[1;37m-----------------------------------------------------------\033[0;37m" >> $db_inst_log
echo -e "\033[1;37m-------Performing tests:\033[0;37m" >> $db_inst_log
psql -f ./test/tests.sql 2>&1 | cat >> $db_inst_log

echo >> $db_inst_log

echo -e "\033[1;37m---EOF-------------------------\033[0;37m" >> $db_inst_log

# data.sql is called from structure.sql
case "$5" in
	"1")
	cat "./$db_inst_log" | less
	;;
esac

