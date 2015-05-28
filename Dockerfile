FROM tomcat:6

RUN apt-get -yq update && apt-get -yq install \
  cutycapt \
  patch \
  postgresql-client \
  libpg-java \
  xvfb

RUN mkdir -p /usr/local/tomcat/webapps/libreplan
RUN wget -q -O /usr/local/tomcat/webapps/libreplan/libreplan.war http://downloads.sourceforge.net/project/libreplan/LibrePlan/libreplan_1.3.0.war
ADD libreplan.xml /usr/local/tomcat/webapps/libreplan/libreplan.xml
ADD catalina.policy.patch catalina.policy.patch
RUN patch -o /usr/local/tomcat/conf/catalina.policy /usr/local/tomcat/conf/catalina.policy catalina.policy.patch

CMD ["catalina.sh", "run"]
