#!/bin/bash
set -x

/usr/sbin/ns-slapd -D /etc/dirsrv/slapd-dir
mysqld_safe &

while ! curl -s localhost:3306 > /dev/null; do echo waiting for mysql to start; sleep 2; done;
while ! curl -s "ldap://localhost:389" > /dev/null; do echo waiting for 389-ds to start; sleep 2; done;

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
  mv /opt/tomcat/webapps/grouper/ /opt/apache-tomcat/grouper-disabled
  rm /opt/tomcat/webapps/grouper.war
fi

if [[ "${disabled_components[@]}" =~ "WS" ]]
then
    mv /opt/tomcat/webapps/grouper-ws/ /opt/tomcat/ws-disabled
    rm /opt/tomcat/webapps/grouper-ws.war
fi

rm -rf /opt/tomcat/work/*

if [[ ! "${disabled_components[@]}" =~ "TOMCAT" ]]
then
    /opt/tomcat/bin/startup.sh
fi

cd /opt/grouper.apiBinary-2.3.0/
bin/gsh /seed-data/bootstrap.gsh

if [[ ! "${disabled_components[@]}" =~ "SAMPLE-JOBS" ]]
then
    bin/gsh /seed-data/sample-jobs-bootstrap.gsh
fi

if [[ "${enabled_components[@]}" =~ "TIER" ]]
then
    bin/gsh /seed-data/tier-bootstrap.gsh
fi

if [[ ! "${disabled_components[@]}" =~ "DAEMON" ]]
then
    bin/gsh -loader &
fi

tail -f /opt/grouper.apiBinary-2.3.0/logs/grouper_error.log
