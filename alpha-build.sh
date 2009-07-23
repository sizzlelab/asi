#!/bin/sh
# A crude Common Services build script specific to the alpha.sizl.org machine.
# Note that you must run this script twice until changes to this file take effect;
# changes to finish.sh take effect immediately.

COS_PATH=/var/datat/cos/common-services

#sudo mongrel_rails stop -P $COS_PATH/tmp/pids/mongrel.pid
sudo mongrel_rails cluster::stop -C $COS_PATH/config/mongrel_cluster.yml
rake thinking_sphinx:stop RAILS_ENV=production

cd /
rm -rf $COS_PATH
svn export --force file:///svn/common-services/trunk $COS_PATH
cd $COS_PATH

#the following is to fall back to rails 2.1 compatible version of the plugin
#svn export -r 254 --force file:///svn/common-services/trunk/vendor/plugins/has_many_polymorphs/lib/has_many_polymorphs/reflection.rb $COS_PATH/vendor/plugins/has_many_polymorphs/lib/has_many_polymorphs/reflection.rb

mongrel_rails cluster::configure -e production -p 3000 -N 3 -c $COS_PATH -a 127.0.0.1
chmod a+x alpha-finish.sh
chgrp -R adm .
chmod -R 2770 .
umask 007
./alpha-finish.sh