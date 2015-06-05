FROM centos
MAINTAINER Junjie Ma <junjie@mail.xwtec.cn>

# install prerequists
RUN yum -y install tar
RUN yum -y install net-tools
COPY welcome.sh /opt/
WORKDIR /opt
RUN /bin/bash welcome.sh

# setup Java
RUN mkdir /opt/java
COPY jdk-8u45-linux-x64.tar.gz /opt/java/
WORKDIR /opt/java/
RUN tar -xvzf jdk-8u45-linux-x64.tar.gz
COPY java.sh /opt/java/
RUN cat java.sh >> ~/.bashrc
RUN source ~/.bashrc
RUN echo $PATH
RUN echo $JAVA_HOME

# setup Tomcat 7x
RUN mkdir /opt/tomcat
COPY apache-tomcat-7.0.62.tar.gz /opt/tomcat/
WORKDIR /opt/tomcat/
RUN tar -xvzf apache-tomcat-7.0.62.tar.gz 
RUN mv apache-tomcat-7.0.62 7062
COPY tomcat-start.sh /opt/
RUN chmod u+x /opt/tomcat-start.sh

# setup ports
WORKDIR /opt
EXPOSE 8000 9990
CMD ["/opt/tomcat-start.sh"]
