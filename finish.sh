#!/bin/sh
# The last part of the Common Services build script. This is in a separate file so that the newest version from the repository
# is always run. 

REV=$((`svn info svn+ssh://cos.sizl.org/svn/common-services | \
grep "^Last Changed Rev" | \
perl -pi -e "s/Last Changed Rev: //"`-`svn info svn+ssh://cos.sizl.org/svn/common-services/tags | \
grep "^Last Changed Rev" | \
perl -pi -e "s/Last Changed Rev: //"`))
echo $REV > app/views/layouts/_revision.html.erb
echo "http://maps.cs.hut.fi/cos/" > app/views/layouts/_servername.html.erb
date > app/views/layouts/_build_date.html.erb

#stripe the socket lines out from database.yml
grep -v socket config/database.yml > config/database.yml_mod
mv config/database.yml_mod config/database.yml

#restart the servers
script/server -d -e production
sudo /etc/init.d/httpd restart
