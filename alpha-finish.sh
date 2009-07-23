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

#change SERVER_DOMAIN constant to SERVERNAME
sed -i "s/SERVER_DOMAIN = \"http\:\/\/cos\.sizl\.org\"/SERVER_DOMAIN = \"$ESCAPED_SERVERNAME\"/" config/environments/production.rb

REV=$((`svn info file:///svn/common-services | \
grep "^Last Changed Rev" | \
perl -pi -e "s/Last Changed Rev: //"`-`svn info file:///svn/common-services/tags | \
grep "^Last Changed Rev" | \
perl -pi -e "s/Last Changed Rev: //"`))

echo $REV > app/views/layouts/_revision.html.erb
date > app/views/layouts/_build_date.html.erb

rake db:migrate RAILS_ENV=production

rake thinking_sphinx:configure RAILS_ENV=production
rake thinking_sphinx:index RAILS_ENV=production
rake thinking_sphinx:start RAILS_ENV=production

mongrel_rails cluster::start

crontab config/crontab