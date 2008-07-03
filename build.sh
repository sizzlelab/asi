#!/bin/sh
# A crude Common Services build script specific to the maps.cs.hut.fi machine.

killall mongrel_rails
cd /
rm -rf /usr/local/common-services
svn export file:///svn/common-services/trunk /usr/local/common-services
cd /usr/local/common-services
chmod a+x finish.sh
./finish.sh