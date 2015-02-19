#!/bin/sh
set -x

export JAVA_HOME=/opt/jre1.7.0_71
export JETTY_HOME=/opt/jetty/
export JETTY_BASE=/opt/iam-jetty-base/
export PATH=$PATH:$JAVA_HOME/bin

echo "Updating the Shibboleth webapp artifacts."
cp /jar-location/ucla-shibboleth.jar /opt/shibboleth-identityprovider-2.4.3/lib/

echo "Rebuilding the idp.war file"
cd /opt/shibboleth-identityprovider-2.4.3
./install.sh -Didp.home.input=/opt/shibboleth-idp -Dinstall.config=no

/etc/init.d/jetty run
