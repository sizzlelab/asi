#!/bin/sh
# A crude Common Services build script specific to the maps.cs.hut.fi machine.
# Note that you must run this script twice until changes to this file take effect;
# changes to finish.sh take effect immediately.

COS_PATH=/usr/local/common-services

killall mongrel_rails
cd /
rm -rf $COS_PATH
svn export svn+ssh://maps.cs.hut.fi/svn/common-services/trunk $COS_PATH
cd $COS_PATH
chmod a+x alpha-finish.sh
./alpha-finish.sh