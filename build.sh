#!/bin/sh
# A crude Common Services build script specific to the maps.cs.hut.fi machine.
# Note that you must run this script twice until changes to this file take effect;
# changes to finish.sh take effect immediately.

killall mongrel_rails
cd /
rm -rf /usr/local/common-services
svn export file:///svn/common-services/trunk /usr/local/common-services
cd /usr/local/common-services
chmod a+x finish.sh
./finish.sh