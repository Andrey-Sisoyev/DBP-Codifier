#!/bin/sh  
#
# Copyright (C) 2010 Andrejs Sisojevs <andrejs.sisojevs@nextmail.ru>
#
# All rights reserved.
#
# For information about license see COPYING file in the root directory of current nominal package
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------

if [ "$1" = "--pack" ]; then
        echo "Error! The package is already packed! "
        exit 1
fi

cd `dirname $0`

unpacked_dir='unpacked-dist'
variant_dir='variant'

function unpack()
{
        if [ "$1" = "--clean" ]; then
                rm -rf $unpacked_dir
        fi

        mkdir "$unpacked_dir"
        if [ ! $? -eq 0 ]; then
               echo "Can't create '$unpacked_dir' directory, where to make a unpacked version (consider using 'clean' modifier to 'rm -rf ...', if direrectory already exists)."
               echo "Aborting."
               exit 1 
        fi

        tar xjf invariant.tar.bz2 -C "$unpacked_dir/"

        cp            "./HOWTO"    "$unpacked_dir/docs/"
        cp            "./NEWS"     "$unpacked_dir/docs/"
        cp            "./PKG-INFO" "$unpacked_dir/docs/"
        cp            "./COPYING"  "$unpacked_dir/"
        cp -Rp "$variant_dir/docs" "$unpacked_dir/"

        cp -Rp "$variant_dir/pkg"  "$unpacked_dir/platforms/PostgreSQL/"
        cp -Rp "$variant_dir/data" "$unpacked_dir/platforms/PostgreSQL/"
        cp -Rp "$variant_dir/test" "$unpacked_dir/platforms/PostgreSQL/"

        sed -i "s_variant/docs/licence/COPYRIGHT_docs/licence/COPYRIGHT_" "$unpacked_dir/COPYING"
        sed -i "s_variant/docs/licence/COPYRIGHT_docs/licence/COPYRIGHT_" "$unpacked_dir/docs/PKG-INFO"
}

if [ $# -eq 0 ] || [ "$1" = "--man" ]; then
        cat ./HOWTO | less
elif [ "$1" = "--help" ] || [ "$1" == "-?" ] || [ "$1" == "?" ]; then
        cat ./HOWTO
elif [ "$1" = "--unpack" ]; then
        unpack "$2"
else
        unpack --clean
	$unpacked_dir/db_inst.sh $1 $2 $3 $4 $5 $6 $7
fi
