#!/bin/sh
# A crude Common Services build script specific to the maps.cs.hut.fi machine.
# Note that you must run this script twice until changes to this file take effect;
# changes to finish.sh take effect immediately.

COS_PATH=/var/datat/cos/common-services

sudo mongrel_rails stop -P $COS_PATH/tmp/pids/mongrel.pid
cd /
rm -rf $COS_PATH
svn export --force svn+ssh://alpha.sizl.org/svn/common-services/trunk $COS_PATH
cd $COS_PATH
#the following is to fall back to rails 2.1 compatible version of the plugin
svn export -r 254 --force svn+ssh://alpha.sizl.org/svn/common-services/trunk/vendor/plugins/has_many_polymorphs/lib/has_many_polymorphs/reflection.rb $COS_PATH/vendor/plugins/has_many_polymorphs/lib/has_many_polymorphs/reflection.rb 
chmod a+x beta-finish.sh
chgrp -R adm .
chmod -R 2770 . 
umask 007
./beta-finish.sh