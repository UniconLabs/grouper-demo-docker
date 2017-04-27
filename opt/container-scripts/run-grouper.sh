#!/bin/bash
set -x

service mysql start

service slapd start

if [ -z "$disable" ]
then
    disabled_components=
else
    IFS=',' read -ra disabled_components <<< "$disable"
fi

if [ -z "$enable" ]
then
    enabled_components=
else
    IFS=',' read -ra enabled_components <<< "$enable"
fi

if [[ "${disabled_components[@]}" =~ "UI" ]]
then
  mv /opt/apache-tomcat-6.0.44/webapps/grouper/ /opt/apache-tomcat-6.0.44/grouper-disabled
  rm /opt/apache-tomcat-6.0.44/webapps/grouper.war
fi

if [[ "${disabled_components[@]}" =~ "WS" ]]
then
    mv /opt/apache-tomcat-6.0.44/webapps/grouper-ws/ /opt/apache-tomcat-6.0.44/ws-disabled
    rm /opt/apache-tomcat-6.0.44/webapps/grouper-ws.war
fi

rm -rf /opt/apache-tomcat-6.0.44/work/*

if [[ ! "${disabled_components[@]}" =~ "TOMCAT" ]]
then
    /opt/apache-tomcat-6.0.44/bin/startup.sh
fi

cd /opt/grouper.apiBinary-2.3.0/
bin/gsh /bootstrap.gsh

if [[ ! "${disabled_components[@]}" =~ "SAMPLE-JOBS" ]]
then
    bin/gsh /sample-jobs-bootstrap.gsh
fi

if [[ "${enabled_components[@]}" =~ "TIER" ]]
then
    bin/gsh /tier-bootstrap.gsh
fi

if [[ ! "${disabled_components[@]}" =~ "DAEMON" ]]
then
    bin/gsh -loader &
fi

tail -f /opt/grouper.apiBinary-2.3.0/logs/grouper_error.log
