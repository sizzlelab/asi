#!/bin/sh
# A crude Common Services build script specific to the maps.cs.hut.fi machine.
# Note that you must run this script twice until changes to this file take effect;
# changes to finish.sh take effect immediately.

COS_PATH=/var/datat/cos/common-services

killall mongrel_rails
cd /
rm -rf $COS_PATH
svn export file:///svn/common-services/trunk $COS_PATH
cd $COS_PATH
chmod a+x alpha-finish.sh
chgrp -R adm .
chmod -R g+ws . 
./alpha-finish.sh