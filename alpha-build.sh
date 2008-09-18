#!/bin/sh
# A crude Common Services build script specific to the maps.cs.hut.fi machine.
# Note that you must run this script twice until changes to this file take effect;
# changes to finish.sh take effect immediately.

COS_PATH=/var/datat/cos/common-services

sudo mongrel_rails stop -P $COS_PATH/tmp/pids/mongrel.pid
cd /
rm -rf $COS_PATH
svn export --force file:///svn/common-services/trunk $COS_PATH
cd $COS_PATH
chmod a+x alpha-finish.sh
chgrp -R adm .
chmod -R 2770 . 
umask 007
./alpha-finish.sh