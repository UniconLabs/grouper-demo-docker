FROM centos:centos7

MAINTAINER John Gasper <jgasper@unicon.net>

ENV JAVA_HOME=/opt/jdk-home \
    ANT_HOME=/opt/ant \
    PATH=$PATH:$JAVA_HOME/bin:/opt/container-scripts:$ANT_HOME/bin \
    GROUPER_VERSION=2.3.0

RUN yum install -y epel-release \
    && yum install -y 389-ds-base mariadb-server mariadb dos2unix expect unzip vim wget \
    && yum clean all

RUN java_version=8.0.131; \
    zulu_version=8.21.0.1; \
    java_md5_hash=1931ed3beedee0b16fb7fd37e069b162; \
    tomcat_version=8.0.45; \
    tomcat_sha1_hash=ed27fc0564bafd5a81a6975b9aa6dd29101d8ff8; \
    ant_version=1.10.1; \
    ant_sha1_hash=fa9acb3b1987f8acf2aa7a87894d1fd9da80e871; \
    \
    echo 'Downloading the JDK...' \    
    && wget -q http://cdn.azul.com/zulu/bin/zulu$zulu_version-jdk$java_version-linux_x64.tar.gz \
    && echo 'Downloading Tomcat...'\
    && wget -q https://archive.apache.org/dist/tomcat/tomcat-8/v$tomcat_version/bin/apache-tomcat-$tomcat_version.zip \
    && echo 'Downloading Ant...'\
    && wget -q https://archive.apache.org/dist/ant/binaries/apache-ant-$ant_version-bin.zip \
    && echo 'Downloading grouper installer...'\
    && wget -q http://software.internet2.edu/grouper/release/$GROUPER_VERSION/grouperInstaller.jar \
    && echo 'Downloading grouper API...'\
    && wget -q http://software.internet2.edu/grouper/release/$GROUPER_VERSION/grouper.apiBinary-$GROUPER_VERSION.tar.gz \
    && echo 'Downloading grouper UI...'\
    && wget -q http://software.internet2.edu/grouper/release/$GROUPER_VERSION/grouper.ui-$GROUPER_VERSION.tar.gz \
    && echo 'Downloading grouper Web Services...'\
    && wget -q http://software.internet2.edu/grouper/release/$GROUPER_VERSION/grouper.ws-$GROUPER_VERSION.tar.gz \
    && echo 'Downloading grouper client...'\
    && wget -q http://software.internet2.edu/grouper/release/$GROUPER_VERSION/grouper.clientBinary-$GROUPER_VERSION.tar.gz \
    && echo 'Downloading grouper PSP...'\
    && wget -q http://software.internet2.edu/grouper/release/$GROUPER_VERSION/grouper.psp-$GROUPER_VERSION.tar.gz \
    && echo 'Downloading grouper Quickstart...'\
    && wget -q http://software.internet2.edu/grouper/release/$GROUPER_VERSION/quickstart.xml \
    \
    && echo "$java_md5_hash  zulu$zulu_version-jdk$java_version-linux_x64.tar.gz" | md5sum -c - \
    && tar -zxvf zulu$zulu_version-jdk$java_version-linux_x64.tar.gz -C /opt \
    && rm zulu$zulu_version-jdk$java_version-linux_x64.tar.gz \
    && ln -s /opt/zulu$zulu_version-jdk$java_version-linux_x64/ /opt/jdk-home \
    \
    && echo "$tomcat_sha1_hash  apache-tomcat-$tomcat_version.zip" | sha1sum -c - \
    && unzip apache-tomcat-$tomcat_version.zip -d /opt 1>/dev/null \    
    && rm -r apache-tomcat-$tomcat_version.zip /opt/apache-tomcat-$tomcat_version/webapps/* \
    && ln -s /opt/apache-tomcat-$tomcat_version /opt/tomcat \
    \
    && unzip apache-ant-$ant_version-bin.zip -d /opt 1>/dev/null \
    && echo "$ant_sha1_hash  apache-ant-$ant_version-bin.zip" | sha1sum -c - \
    && rm -r apache-ant-$ant_version-bin.zip /opt/apache-ant-$ant_version/manual/ \
    && ln -s /opt/apache-ant-$ant_version /opt/ant \
    && chmod +x /opt/apache-ant-$ant_version/bin/ant \
    \
    && tar -zxf grouper.apiBinary-$GROUPER_VERSION.tar.gz -C /opt \
    && tar -zxf grouper.ui-$GROUPER_VERSION.tar.gz -C /opt \
    && tar -zxf grouper.ws-$GROUPER_VERSION.tar.gz -C /opt \
    && tar -zxf grouper.clientBinary-$GROUPER_VERSION.tar.gz -C /opt \
    && tar -zxf grouper.psp-$GROUPER_VERSION.tar.gz -C /opt \
    && cp -R /opt/grouper.psp-$GROUPER_VERSION/lib/custom/* /opt/grouper.apiBinary-$GROUPER_VERSION/lib/custom \
    && rm grouper.apiBinary-$GROUPER_VERSION.tar.gz grouper.ui-$GROUPER_VERSION.tar.gz grouper.ws-$GROUPER_VERSION.tar.gz grouper.psp-$GROUPER_VERSION.tar.gz grouper.clientBinary-$GROUPER_VERSION.tar.gz
 
COPY seed-data/ /seed-data/

RUN mysql_install_db \
  && chown -R mysql:mysql /var/lib/mysql/ \
  && sed -i 's/^\(bind-address\s.*\)/# \1/' /etc/my.cnf \
  && sed -i 's/^\(log_error\s.*\)/# \1/' /etc/my.cnf \
  && sed -i 's/\[mysqld\]/\[mysqld\]\ncharacter_set_server = utf8/' /etc/my.cnf \
  && sed -i 's/\[mysqld\]/\[mysqld\]\ncollation_server = utf8_general_ci/' /etc/my.cnf \
  && sed -i 's/\[mysqld\]/\[mysqld\]\nport = 3306/' /etc/my.cnf \
  && cat  /etc/my.cnf \
  && echo "/usr/bin/mysqld_safe &" > /tmp/config \
  && echo "mysqladmin --silent --wait=30 ping || exit 1" >> /tmp/config \
  && echo "mysql -e 'GRANT ALL PRIVILEGES ON *.* TO \"root\"@\"%\" WITH GRANT OPTION;'" >> /tmp/config \
  && echo "mysql -e 'CREATE DATABASE grouper CHARACTER SET utf8 COLLATE utf8_bin;'" >> /tmp/config \
  && bash /tmp/config \
  && rm -f /tmp/config \
  && mysql grouper < /seed-data/sisData.sql

RUN useradd ldapadmin \
    && rm -fr /var/lock /usr/lib/systemd/system \
    # The 389-ds setup will fail because the hostname can't reliable be determined, so we'll bypass it and then install. \
    && sed -i 's/checkHostname {/checkHostname {\nreturn();/g' /usr/lib64/dirsrv/perl/DSUtil.pm \
    # Not doing SELinux \
    && sed -i 's/updateSelinuxPolicy($inf);//g' /usr/lib64/dirsrv/perl/* \
    # Do not restart at the end \
    && sed -i '/if (@errs = startServer($inf))/,/}/d' /usr/lib64/dirsrv/perl/* \
    && setup-ds.pl --silent --file /seed-data/ds-setup.inf \
    && /usr/sbin/ns-slapd -D /etc/dirsrv/slapd-dir \ 
    && while ! curl -s ldap://localhost:389 > /dev/null; do echo waiting for ldap to start; sleep 1; done; \
    ldapadd -H ldap:/// -f /seed-data/users.ldif -x -D "cn=Directory Manager" -w password
    
COPY opt/ /opt/

RUN set -x; \
    chmod -R +x /opt/container-scripts/; \
    chmod -R +x /opt/tomcat/bin/*.sh; \
    JAVA_HOME=/opt/jdk-home; \
    (/usr/sbin/ns-slapd -D /etc/dirsrv/slapd-dir &); \
    (/usr/bin/mysqld_safe &); \
    while ! curl -s ldap://localhost:389 > /dev/null; do echo waiting for ldap to start; sleep 1; done; \
    while ! curl -s localhost:3306 > /dev/null; do echo waiting for mysqld to start; sleep 3; done; \
    echo Building the wars before patching so embedded api patching works properly \
    && cd /opt/grouper.ui-$GROUPER_VERSION \
    && /opt/ant/bin/ant war \
    && mv dist/grouper.war /opt/tomcat/webapps \
    && cd /opt/grouper.ws-$GROUPER_VERSION/grouper-ws/ \
    && /opt/ant/bin/ant dist \
    && mv build/dist/grouper-ws.war /opt/tomcat/webapps \ 
    && echo Extracting Tomcats war files for patching \
    && mkdir /opt/tomcat/webapps/grouper /opt/tomcat/webapps/grouper-ws \
    && cd /opt/tomcat/webapps/grouper \
    && $JAVA_HOME/bin/jar xvf ../grouper.war \
    && cd /opt/tomcat/webapps/grouper-ws \
    && $JAVA_HOME/bin/jar xvf ../grouper-ws.war \
    && cd /opt/grouper.apiBinary-$GROUPER_VERSION \
    && bin/gsh -registry -check -runscript -noprompt \
    && mkdir /tmp/grp-api/ /tmp/grp-ui/ /tmp/grp-psp/ /tmp/grp-ws/ \
    && cd / \
    && cp /opt/patch-scripts/grouper.installer-api.properties /grouper.installer.properties \
    && $JAVA_HOME/bin/java -cp .:/grouperInstaller.jar edu.internet2.middleware.grouperInstaller.GrouperInstaller \
    && cd /opt/grouper.apiBinary-$GROUPER_VERSION \
    && bin/gsh -registry -check -runscript -noprompt \
    && cd / \
    && cp /opt/patch-scripts/grouper.installer-psp.properties /grouper.installer.properties \
    && $JAVA_HOME/bin/java -cp .:/grouperInstaller.jar edu.internet2.middleware.grouperInstaller.GrouperInstaller \
    && cp /opt/patch-scripts/grouper.installer-ui.properties /grouper.installer.properties \
    && $JAVA_HOME/bin/java -cp .:/grouperInstaller.jar edu.internet2.middleware.grouperInstaller.GrouperInstaller \
    && cp /opt/patch-scripts/grouper.installer-ws.properties /grouper.installer.properties \
    && $JAVA_HOME/bin/java -cp .:/grouperInstaller.jar edu.internet2.middleware.grouperInstaller.GrouperInstaller \
    && rm -fr /tmp/grp-ui/ /tmp/grp-api/ /tmp/grp-psp/ /tmp/grp-ws/  \
    && rm -r /opt/tomcat/webapps/grouper.war /opt/tomcat/webapps/grouper-ws.war

EXPOSE 389 3306 8080

CMD ["run-grouper.sh"]
