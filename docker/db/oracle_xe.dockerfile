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
ENV ORACLE_HOME='/u01/app/oracle/product/11.2.0/xe'
ENV ORACLE_SID='XE'
ENV PATH="${ORACLE_HOME}/bin:${PATH}"

# make xe.rsp
RUN echo -e '\
ORACLE_HTTP_PORT=8080\n\
ORACLE_LISTENER_PORT=1521\n\
ORACLE_PASSWORD=oracle\n\
ORACLE_CONFIRM_PASSWORD=oracle\n\
ORACLE_DBENABLE=y\n'\
>> ${ORACLE_HOME}/config/scripts/xe.rsp

# make xe.ora
RUN echo -e '\
open_cursors=300\n\
db_name=XE\n\
control_files=("/u01/app/oracle/oradata/XE/control.dbf")\n\
DB_RECOVERY_FILE_DEST=/u01/app/oracle/fast_recovery_area\n\
DB_RECOVERY_FILE_DEST_SIZE=10G\n\
job_queue_processes=4\n\
compatible=11.2.0.0.0\n\
diagnostic_dest=/u01/app/oracle\n\
sessions=20\n\
audit_file_dest=/u01/app/oracle/admin/XE/adump\n\
remote_login_passwordfile=EXCLUSIVE\n\
dispatchers="(PROTOCOL=TCP) (SERVICE=XEXDB)"\n\
shared_servers=4\n\
undo_management=AUTO\n\
undo_tablespace=UNDOTBS1\n'\
>> ${ORACLE_HOME}/config/scripts/init.ora

# make initXETemp.ora
RUN echo -e '\
open_cursors=300\n\
db_name=XE\n\
control_files=("/u01/app/oracle/oradata/XE/control.dbf")\n\
DB_RECOVERY_FILE_DEST_SIZE=10G\n\
DB_RECOVERY_FILE_DEST=/u01/app/oracle/fast_recovery_area\n\
compatible=11.2.0.0.0\n\
diagnostic_dest=/u01/app/oracle\n\
sessions=20\n\
audit_file_dest=/u01/app/oracle/admin/XE/adump\n\
remote_login_passwordfile=EXCLUSIVE\n\
dispatchers="(PROTOCOL=TCP) (SERVICE=XEXDB)"\n\
undo_management=AUTO\n\
undo_tablespace=UNDOTBS1\n\
_no_recovery_through_resetlogs=true\n'\
>> ${ORACLE_HOME}/config/scripts/initXETemp.ora

# setup instance
RUN chown oracle:dba ${ORACLE_HOME}/config/scripts/*.ora ${ORACLE_HOME}/config/scripts/xe.rsp
RUN chmod 755 ${ORACLE_HOME}/config/scripts/*.ora ${ORACLE_HOME}/config/scripts/xe.rsp 
RUN /etc/init.d/oracle-xe configure responseFile="${ORACLE_HOME}/config/scripts/xe.rsp"

# make start.sh
RUN echo -e '\
#!/bin/bash\n\
sed -i.ori -E "s/HOST = [^)]+/HOST = $HOSTNAME/g" $ORACLE_HOME/network/admin/listener.ora\n\
sed -i.ori -E "s/HOST = [^)]+/HOST = $HOSTNAME/g" $ORACLE_HOME/network/admin/tnsnames.ora\n\
while true; do\n\
    pmon=`ps -ef | grep [p]mon_$ORACLE_SID`\n\
    if [ "$pmon" == "" ]; then\n\
        date\n\
        /etc/init.d/oracle-xe start\n\
    fi\n\
    sleep 5m\n\
done\n'\
>> /start.sh

# start sshd service
CMD ["/usr/sbin/sshd", "-D"]

# run script
CMD ["/start.sh"]

EXPOSE 22
EXPOSE 1521
EXPOSE 8080
