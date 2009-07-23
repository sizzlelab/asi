#!/bin/sh
# The last part of the Common Services build script. This is in a separate
# file so that the newest version from the repository is always run.
# NOTE: This script must be run from the same directory where the COS is
# located (see COS_PATH from alpha-build.sh)


SERVERNAME="http://cos.alpha.sizl.org"
# for regexp use, the same name in escaped form
ESCAPED_SERVERNAME="http\:\/\/cos\.alpha\.sizl\.org"

#change COS to use alpha's Ressi
sed -i "s/localhost\:9000/cos\.alpha\.sizl\.org\/ressi\//" config/environment.rb

# turn on email validation
#sed -i "s/VALIDATE_EMAILS = false/VALIDATE_EMAILS = true/" config/environment.rb

#change relative url root to SERVERNAME
#sed -i "s/relative_url_root = \"http\:\/\/cos\.sizl\.org\"/relative_url_root = \"$ESCAPED_SERVERNAME\"/" config/environments/production.rb

#change SERVER_DOMAIN constant to SERVERNAME
sed -i "s/SERVER_DOMAIN = \"http\:\/\/cos\.sizl\.org\"/SERVER_DOMAIN = \"$ESCAPED_SERVERNAME\"/" config/environments/production.rb

REV=$((`svn info file:///svn/common-services | \
grep "^Last Changed Rev" | \
perl -pi -e "s/Last Changed Rev: //"`-`svn info file:///svn/common-services/tags | \
grep "^Last Changed Rev" | \
perl -pi -e "s/Last Changed Rev: //"`))
echo $REV > app/views/layouts/_revision.html.erb
#echo $SERVERNAME > app/views/layouts/_servername.html.erb
date > app/views/layouts/_build_date.html.erb
rake db:migrate
rake cruise
rake db:migrate RAILS_ENV=production
rake thinking_sphinx:stop RAILS_ENV=production
rake thinking_sphinx:configure RAILS_ENV=production
rake thinking_sphinx:index RAILS_ENV=production
rake thinking_sphinx:start RAILS_ENV=production
#script/server -d -e production
mongrel_rails cluster::start
sudo /etc/init.d/apache2 restart

crontab config/crontab