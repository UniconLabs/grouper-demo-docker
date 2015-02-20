#!/bin/sh
set -x

service mysql start

service slapd start

service jetty start

cd /opt/grouper.apiBinary-2.2.1/
bin/gsh -loader
