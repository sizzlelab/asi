#!/bin/sh
# A crude Common Services build script specific to the maps.cs.hut.fi machine.

killall mongrel_rails
cd /
rm -rf /usr/local/common-services
svn export file:///svn/common-services/trunk /usr/local/common-services
cd /usr/local/common-services
REV=$((`svn info file:///svn/common-services | grep "^Last Changed Rev" | perl -pi -e "s/Last Changed Rev: //"`-`svn info file:///svn/common-services/tags | grep "^Last Changed \
Rev" | perl -pi -e "s/Last Changed Rev: //"`))
echo $REV > app/views/layouts/_revision.html.erb
echo "http://maps.cs.hut.fi/cos/" > app/views/layouts/_servername.html.erb
date > app/views/layouts/_build_date.html.erb
script/server -d -e production
sudo /etc/init.d/httpd restart

