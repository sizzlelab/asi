#!/bin/sh
# The last part of the Common Services build script. This is in a separate file so that the newest version from the repository
# is always run. 

SERVERNAME="http://maps.cs.hut.fi/cos"
# for regexp use, the same name in escaped form
ESCAPED_SERVERNAME="http\:\/\/maps\.cs\.hut\.fi\/cos"

#change relative url root to SERVERNAME
#sed -i "s/relative_url_root = \"http\:\/\/cos\.sizl\.org\"/relative_url_root = \"$ESCAPED_SERVERNAME\"/" config/environments/production.rb

#change SERVER_DOMAIN constant to SERVERNAME
sed -i "s/SERVER_DOMAIN =  \"http\:\/\/cos\.sizl\.org\"/SERVER_DOMAIN = \"$ESCAPED_SERVERNAME\"/" config/environments/production.rb


REV=$((`svn info svn+ssh://alpha.sizl.org/svn/common-services | \
grep "^Last Changed Rev" | \
perl -pi -e "s/Last Changed Rev: //"`-`svn info svn+ssh://alpha.sizl.org/svn/common-services/tags | \
grep "^Last Changed Rev" | \
perl -pi -e "s/Last Changed Rev: //"`))
echo $REV > app/views/layouts/_revision.html.erb
echo $SERVERNAME > app/views/layouts/_servername.html.erb
date > app/views/layouts/_build_date.html.erb

#stripe the socket lines out from database.yml
#grep -v socket config/database.yml > config/database.yml_mod

# change the socket line to match maps-server configuration
sed "s/socket: \/var\/run\/mysqld\/mysqld\.sock/socket: \/var\/lib\/mysql\/mysql\.sock/" config/database.yml > config/database.yml_mod
mv config/database.yml_mod config/database.yml

rake db:migrate RAILS_ENV=production

#restart the servers
script/server -d -p 3001 -e production
sudo /etc/init.d/httpd restart
#rake db:migrate
#rake test
