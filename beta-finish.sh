#!/bin/sh
# The last part of the Common Services build script. This is in a separate 
# file so that the newest version from the repository is always run. 
# NOTE: This script must be run from the same directory where the COS is 
# located (see COS_PATH from beta-build.sh)

SERVERNAME="http://cos.sizl.org/"

#change COS to use production Ressi
sed -i "s/localhost\:9000/cos\.sizl\.org\/ressi\//" config/environment.rb

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
#script/server -d -e production
mongrel_rails cluster::start
sudo /etc/init.d/apache2 restart