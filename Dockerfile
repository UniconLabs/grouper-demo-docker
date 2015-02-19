FROM ubuntu

MAINTAINER John Gasper <jgasper@unicon.net>

ENV JAVA_HOME /opt/jdk1.7.0_75
ENV JETTY_HOME /opt/jetty
ENV JETTY_BASE /opt/iam-jetty-base
ENV ANT_HOME /opt/apache-ant-1.9.4
ENV PATH $PATH:$JRE_HOME/bin:/opt/container-scripts:$ANT_HOME/bin

#MySql shamelessly stolen from https://github.com/dockerfile/mysql/blob/master/Dockerfile
RUN \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server && \
  sed -i 's/^\(bind-address\s.*\)/# \1/' /etc/mysql/my.cnf && \
  sed -i 's/^\(log_error\s.*\)/# \1/' /etc/mysql/my.cnf && \
  echo "mysqld_safe &" > /tmp/config && \
  echo "mysqladmin --silent --wait=30 ping || exit 1" >> /tmp/config && \
  echo "mysql -e 'GRANT ALL PRIVILEGES ON *.* TO \"root\"@\"%\" WITH GRANT OPTION;'" >> /tmp/config && \
  echo "mysql -e 'CREATE DATABASE grouper;'" >> /tmp/config && \
  bash /tmp/config && \
  rm -f /tmp/config

# install slapd using debian unattended mode
RUN echo 'slapd/root_password password password' | debconf-set-selections && \
    echo 'slapd/root_password_again password password' | debconf-set-selections && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y ldap-utils slapd wget tar unzip dos2unix

ADD ldap-data/init.ldif /
ADD ldap-data/users.ldif /

RUN service slapd start \
    && mkdir -p /var/ldap/example \
    && chown -R openldap /var/ldap \
    && ldapadd -Y EXTERNAL -H ldapi:/// -f init.ldif \
    && ldapadd -H ldapi:/// -f users.ldif -x -D "cn=admin,dc=example,dc=edu" -w password \
    && rm /*.ldif

# Download Java, verify the hash, and install
RUN set -x; \
    java_version=7u75; \
    wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" \
    http://download.oracle.com/otn-pub/java/jdk/$java_version-b13/jdk-$java_version-linux-x64.tar.gz \
    && echo "6f1f81030a34f7a9c987f8b68a24d139  jdk-$java_version-linux-x64.tar.gz" | md5sum -c - \
    && tar -zxvf jdk-$java_version-linux-x64.tar.gz -C /opt \
    && rm jdk-$java_version-linux-x64.tar.gz


# Download Jetty, verify the hash, and install, initialize a new base
RUN set -x; \
    jetty_version=9.2.7.v20150116; \
    wget -O jetty.zip "https://eclipse.org/downloads/download.php?file=/jetty/$jetty_version/dist/jetty-distribution-$jetty_version.zip&r=1" \
    && echo "0d7dc3e4c72d63bd34fabef8c96dabf7b744a15d  jetty.zip" | sha1sum -c - \
    && unzip jetty.zip -d /opt \
    && mv /opt/jetty-distribution-$jetty_version /opt/jetty \
    && rm jetty.zip \
    && cp /opt/jetty/bin/jetty.sh /etc/init.d/jetty \
    && mkdir -p /opt/iam-jetty-base/modules \
    && mkdir -p /opt/iam-jetty-base/lib/ext \
    && cd /opt/iam-jetty-base \
    && touch start.ini \
    && /opt/jdk1.7.0_75/bin/java -jar ../jetty/start.jar --add-to-startd=http,https,deploy,ext,annotations,jstl,logging
 
RUN wget http://www.us.apache.org/dist/ant/binaries/apache-ant-1.9.4-bin.zip \
    && unzip apache-ant-1.9.4-bin.zip -d /opt \
    && echo "ec57a35eb869a307abdfef8712f3688fff70887f  apache-ant-1.9.4-bin.zip" | sha1sum -c - \
    && rm apache-ant-1.9.4-bin.zip \
    && chmod +x /opt/apache-ant-1.9.4/bin/ant

# Download the Grouper Installer and install
RUN set -x; \  
    wget http://software.internet2.edu/grouper/release/2.2.1/grouper.apiBinary-2.2.1.tar.gz \
    && tar -zxvf grouper.apiBinary-2.2.1.tar.gz -C /opt \
    && wget http://software.internet2.edu/grouper/release/2.2.1/grouper.ui-2.2.1.tar.gz \
    && tar -zxvf grouper.ui-2.2.1.tar.gz -C /opt \
    && wget http://software.internet2.edu/grouper/release/2.2.1/grouper.ws-2.2.1.tar.gz \
    && tar -zxvf grouper.ws-2.2.1.tar.gz -C /opt \
    && rm grouper.apiBinary-2.2.1.tar.gz grouper.ui-2.2.1.tar.gz grouper.ws-2.2.1.tar.gz

ADD grouper-api/ /opt/grouper.apiBinary-2.2.1/
ADD grouper-ui/ /opt/grouper.ui-2.2.1/
ADD grouper-ws/ /opt/grouper.ws-2.2.1/

RUN service mysql start \
    && cd /opt/grouper.apiBinary-2.2.1 \
    && echo "y" | bin/gsh -registry -check \
    && cd /opt/grouper.ui-2.2.1 \
    && /opt/apache-ant-1.9.4/bin/ant war

ADD iam-jetty-base/ /opt/iam-jetty-base/

# Clean up the install
RUN apt-get -y remove wget tar unzip dos2unix; apt-get clean all

#ADD container-scripts/ /opt/container-scripts/
#RUN chmod -R +x /opt/container-scripts/

EXPOSE 389 3306 8080 8443

CMD ["run-shibboleth.sh"]
