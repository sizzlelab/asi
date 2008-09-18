#!/bin/sh
# A crude Common Services build script specific to the maps.cs.hut.fi machine.
# Note that you must run this script twice until changes to this file take effect;
# changes to finish.sh take effect immediately.

COS_PATH=/usr/local/cos/common-services

sudo mongrel_rails stop -P $COS_PATH/tmp/pids/mongrel.pid
cd /
rm -rf $COS_PATH
svn export svn+ssh://alpha.sizl.org/svn/common-services/trunk $COS_PATH
cd $COS_PATH
chmod a+x maps-finish.sh
chmod -R 2770 . 
umask 007
./maps-finish.sh
