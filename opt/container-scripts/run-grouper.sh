#!/bin/sh
set -x

service mysql start

service slapd start

rm -rf /opt/apache-tomcat-6.0.44/work/*

/opt/apache-tomcat-6.0.44/bin/startup.sh

cd /opt/grouper.apiBinary-2.3.0/
bin/gsh -loader &

tail -f /opt/grouper.apiBinary-2.3.0/logs/grouper_error.log
