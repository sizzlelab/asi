#!/bin/sh
# The last part of the Common Services build script. This is in a separate file so that the newest version from the repository
# is always run. 

SERVERNAME="http://cos.sizl.org/"

REV=$((`svn info svn+ssh://alpha.sizl.org/svn/common-services | \
grep "^Last Changed Rev" | \
perl -pi -e "s/Last Changed Rev: //"`-`svn info svn+ssh://alpha.sizl.org/svn/common-services/tags | \
grep "^Last Changed Rev" | \
perl -pi -e "s/Last Changed Rev: //"`))
echo $REV > app/views/layouts/_revision.html.erb
echo $SERVERNAME > app/views/layouts/_servername.html.erb
date > app/views/layouts/_build_date.html.erb
rake db:migrate
rake test
rake db:migrate RAILS_ENV=production
script/server -d -e production
sudo /etc/init.d/apache2 restart