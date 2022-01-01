FROM centos:latest

MAINTAINER Junjie Mars <junjiemars@gmail.com>

# pre-requirements
# ...

RUN mkdir -p /run/lock/subsys && \
    yum -y install deltarpm && \
    echo '# enable deltarpm' >> /etc/yum.conf && \
    sed -i 's/tsflags=nodocs/#tsflags=nodocs/g' /etc/yum.conf && \
    yum install -y \
        bc \
        libaio \
        initscripts \
        net-tools \
        unzip && \
    yum clean all

# install oracle xe 11g2
ENV XE_RPM='oracle-xe-11.2.0-1.0.x86_64.rpm'
ENV XE_ZIP="${XE_RPM}.zip"
COPY $XE_ZIP /tmp/ 
RUN unzip -d/tmp/xe /tmp/$XE_ZIP && \
    yum localinstall -y /tmp/xe/Disk1/${XE_RPM} && \
    rm -rf ${XE_ZIP}

# configure xe 
ENV INS_ORA_PATH='/u01/app/oracle/product/11.2.0/xe'

# make xe.rsp
RUN echo -e '\
ORACLE_HTTP_PORT=8080\n\
ORACLE_LISTENER_PORT=1521\n\
ORACLE_PASSWORD=oracle\n\
ORACLE_CONFIRM_PASSWORD=oracle\n\
ORACLE_DBENABLE=y\n'\
> xe.rsp

# setup instance
RUN sed -i.ori 's,/var/lock/subsys,/var/lock,' /etc/init.d/oracle-xe && \
    /etc/init.d/oracle-xe configure responseFile=xe.rsp &> ins_xe.log || \
    echo -e "configure oracle-xe failed, panic!"

RUN source ${INS_ORA_PATH}/bin/oracle_env.sh

# start xe
CMD ["/etc/init.d/oracle-xe", "start"]

# start sshd service
CMD ["/usr/sbin/sshd", "-D"]

# run script
# ...

EXPOSE 22
EXPOSE 1521
EXPOSE 8080
