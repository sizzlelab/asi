#!/bin/sh
# A crude Common Services build script specific to the alpha.sizl.org machine.
# Note that you must run this script twice until changes to this file take effect;
# changes to finish.sh take effect immediately.

COS_PATH=/var/datat/cos/common-services

mongrel_rails cluster::stop -C $COS_PATH/config/mongrel_cluster.yml
rake thinking_sphinx:stop RAILS_ENV=production

cd /
rm -rf $COS_PATH
svn export --force file:///svn/common-services/trunk $COS_PATH
cd $COS_PATH

mongrel_rails cluster::configure -e production -p 3000 -N 3 -c $COS_PATH -a 127.0.0.1
chmod a+x alpha-finish.sh
chgrp -R adm .
chmod -R 2770 .
umask 007
./alpha-finish.sh