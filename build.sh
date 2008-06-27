#!/bin/sh
cd /
rm -rf /usr/local/common-services
svn export file:///svn/common-services/trunk /usr/local/common-services
cd /usr/local/common-services
script/server -d -e production
sudo /etc/init.d/httpd restart

