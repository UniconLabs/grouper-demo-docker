FROM ubuntu

MAINTAINER John Gasper <jgasper@unicon.net>

ENV JAVA_HOME /opt/jdk1.7.0_79
ENV ANT_HOME /opt/apache-ant-1.9.4
ENV PATH $PATH:$JRE_HOME/bin:/opt/container-scripts:$ANT_HOME/bin

RUN apt-get update \
    && apt-get install -y slapd wget tar unzip dos2unix expect

RUN java_version=7u79; \    
    echo 'Downloading the JDK...' \    
    && wget -q --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" \
    http://download.oracle.com/otn-pub/java/jdk/$java_version-b15/jdk-$java_version-linux-x64.tar.gz \
    && echo 'Downloading Tomcat...'\
    && wget -q http://www.eng.lsu.edu/mirrors/apache/tomcat/tomcat-6/v6.0.43/bin/apache-tomcat-6.0.43.zip \
    && echo 'Downloading Ant...'\
    && wget -q http://www.us.apache.org/dist/ant/binaries/apache-ant-1.9.4-bin.zip \
    && echo 'Downloading grouper installer...'\
    && wget -q http://software.internet2.edu/grouper/release/2.2.1/grouperInstaller.jar \
    && echo 'Downloading grouper API...'\
    && wget -q http://software.internet2.edu/grouper/release/2.2.1/grouper.apiBinary-2.2.1.tar.gz \
    && echo 'Downloading grouper UI...'\
    && wget -q http://software.internet2.edu/grouper/release/2.2.1/grouper.ui-2.2.1.tar.gz \
    && echo 'Downloading grouper Web Services...'\
    && wget -q http://software.internet2.edu/grouper/release/2.2.1/grouper.ws-2.2.1.tar.gz \
    && echo 'Downloading grouper client...'\
    && wget -q http://software.internet2.edu/grouper/release/2.2.1/grouper.clientBinary-2.2.1.tar.gz \
    && echo 'Downloading grouper PSP...'\
    && wget -q http://software.internet2.edu/grouper/release/2.2.1/grouper.psp-2.2.1.tar.gz \
    && echo 'Downloading grouper Quickstart...'\
    && wget -q http://software.internet2.edu/grouper/release/2.2.1/quickstart.xml \
    \
    && echo "9222e097e624800fdd9bfb568169ccad  jdk-$java_version-linux-x64.tar.gz" | md5sum -c - \
    && tar -zxvf jdk-$java_version-linux-x64.tar.gz -C /opt \
    && rm jdk-$java_version-linux-x64.tar.gz \ 
    \
    && echo "314ae7781516a678f44e3067e0006c35  apache-tomcat-6.0.43.zip" | md5sum -c - \
    && unzip apache-tomcat-6.0.43.zip -d /opt \    
    && rm apache-tomcat-6.0.43.zip \
    \
    && unzip apache-ant-1.9.4-bin.zip -d /opt \
    && echo "ec57a35eb869a307abdfef8712f3688fff70887f  apache-ant-1.9.4-bin.zip" | sha1sum -c - \
    && rm apache-ant-1.9.4-bin.zip \
    && chmod +x /opt/apache-ant-1.9.4/bin/ant \
    \
    && tar -zxvf grouper.apiBinary-2.2.1.tar.gz -C /opt \
    && tar -zxvf grouper.ui-2.2.1.tar.gz -C /opt \
    && tar -zxvf grouper.ws-2.2.1.tar.gz -C /opt \
    && tar -zxvf grouper.clientBinary-2.2.1.tar.gz -C /opt \
    && tar -zxvf grouper.psp-2.2.1.tar.gz -C /opt \
    && cp -R /opt/grouper.psp-2.2.1/lib/custom/* /opt/grouper.apiBinary-2.2.1/lib/custom \
    && rm grouper.apiBinary-2.2.1.tar.gz grouper.ui-2.2.1.tar.gz grouper.ws-2.2.1.tar.gz grouper.psp-2.2.1.tar.gz grouper.clientBinary-2.2.1.tar.gz
 
ADD seed-data/ /

#MySql shamelessly stolen from https://github.com/dockerfile/mysql/blob/master/Dockerfile
# install slapd using debian unattended mode
RUN \
  DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server && \
  sed -i 's/^\(bind-address\s.*\)/# \1/' /etc/mysql/my.cnf && \
  sed -i 's/^\(log_error\s.*\)/# \1/' /etc/mysql/my.cnf && \
  echo "mysqld_safe &" > /tmp/config && \
  echo "mysqladmin --silent --wait=30 ping || exit 1" >> /tmp/config && \
  echo "mysql -e 'GRANT ALL PRIVILEGES ON *.* TO \"root\"@\"%\" WITH GRANT OPTION;'" >> /tmp/config && \
  echo "mysql -e 'CREATE DATABASE grouper;'" >> /tmp/config && \
  bash /tmp/config && \
  rm -f /tmp/config && \
  mysql grouper < /sisData.sql \
  && echo 'slapd/root_password password password' | debconf-set-selections \
  && echo 'slapd/root_password_again password password' | debconf-set-selections \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y ldap-utils slapd

RUN service slapd start \
    && mkdir -p /var/ldap/example \
    && chown -R openldap /var/ldap \
    && ldapadd -Y EXTERNAL -H ldapi:/// -f init.ldif \
    && ldapadd -Y EXTERNAL -H ldapi:/// -f eduPerson.schema \
    && ldapadd -H ldapi:/// -f users.ldif -x -D "cn=admin,dc=example,dc=edu" -w password \
    && rm /*.ldif /eduPerson.schema quickstart.xml
    
ADD opt/ /opt/

RUN set -x; \
    chmod -R +x /opt/container-scripts/; \
    chmod -R +x /opt/apache-tomcat-6.0.43/bin/*.sh; \
    JAVA_HOME=/opt/jdk1.7.0_79; \
    service mysql start \
    && service slapd start \
    && echo Building the wars before patching so embedded api patching works properly \
    && cd /opt/grouper.ui-2.2.1 \
    && /opt/apache-ant-1.9.4/bin/ant war \
    && cp dist/grouper.war /opt/apache-tomcat-6.0.43/webapps \
    && cd /opt/grouper.ws-2.2.1/grouper-ws/ \
    && /opt/apache-ant-1.9.4/bin/ant dist \
    && cp build/dist/grouper-ws.war /opt/apache-tomcat-6.0.43/webapps \ 
    && mkdir /tmp/grp-api/ /tmp/grp-ui/ /tmp/grp-psp/ /tmp/grp-ws/ \   
    && expect /opt/patch-scripts/api-patch \
    && cd /opt/grouper.apiBinary-2.2.1 \
    && bin/gsh -registry -check -runscript -noprompt \
    && bin/gsh /bootstrap.gsh \
    && expect /opt/patch-scripts/psp-patch \
    && /opt/apache-tomcat-6.0.43/bin/startup.sh \
    && sleep 20s \
    && /opt/apache-tomcat-6.0.43/bin/shutdown.sh \
    && expect /opt/patch-scripts/ui-patch \
    && expect /opt/patch-scripts/ws-patch \
    && rm -fr /tmp/grp-ui/ /tmp/grp-api//tmp/grp-psp/ /tmp/grp-ws/ /opt/apache-tomcat-6.0.43/work/

EXPOSE 389 3306 8080

CMD ["run-grouper.sh"]
