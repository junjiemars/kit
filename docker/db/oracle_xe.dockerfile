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
ENV XE_ZIP='oracle-xe-11.2.0-1.0.x86_64.rpm.zip'
RUN curl -vkL -H'Cookie: oraclelicense=accept-securebackup-cookie' -O "http://download.oracle.com/otn/linux/oracle11g/xe/${XE_ZIP}" && \
    unzip -d/tmp/xe ${XE_ZIP} && \
    yum localinstall -y /tmp/xe/oracle-xe-11.2.0-1.0.x86_64.rpm && \
    rm -rf /tmp/xe ${XE_ZIP} 

# configure xe 
ENV XE_PATH='/u01/app/oracle/product/11.2.0/xe/config/scripts'

# make xe.rsp
RUN cat <<END > ${XE_PATH}/xe.rsp
ORACLE_HTTP_PORT=8080
ORACLE_LISTENER_PORT=1521
ORACLE_PASSWORD=oracle
ORACLE_CONFIRM_PASSWORD=oracle
ORACLE_DBENABLE=y
END

# make xe.ora
RUN cat <<END > ${XE_PATH}/init.ora
open_cursors=300
db_name=XE
control_files=("/u01/app/oracle/oradata/XE/control.dbf")
DB_RECOVERY_FILE_DEST=/u01/app/oracle/fast_recovery_area
DB_RECOVERY_FILE_DEST_SIZE=10G
job_queue_processes=4
compatible=11.2.0.0.0
diagnostic_dest=/u01/app/oracle
sessions=20
audit_file_dest=/u01/app/oracle/admin/XE/adump
remote_login_passwordfile=EXCLUSIVE
dispatchers="(PROTOCOL=TCP) (SERVICE=XEXDB)"
shared_servers=4
undo_management=AUTO
undo_tablespace=UNDOTBS1
END

# make initXETemp.ora
RUN cat <<END >"${XE_PATH}/initXETemp.ora"
open_cursors=300
db_name=XE
control_files=("/u01/app/oracle/oradata/XE/control.dbf")
DB_RECOVERY_FILE_DEST_SIZE=10G
DB_RECOVERY_FILE_DEST=/u01/app/oracle/fast_recovery_area
compatible=11.2.0.0.0
diagnostic_dest=/u01/app/oracle
sessions=20
audit_file_dest=/u01/app/oracle/admin/XE/adump
remote_login_passwordfile=EXCLUSIVE
dispatchers="(PROTOCOL=TCP) (SERVICE=XEXDB)"
undo_management=AUTO
undo_tablespace=UNDOTBS1
_no_recovery_through_resetlogs=true
END

# setup instance
RUN chown oracle:dba ${XE_PATH}/*.ora ${XE_PATH}/xe.rsp && \
    chmod 755 ${XE_PATH}/*.ora ${XE_PATH}/xe.rsp && \
    /etc/init.d/oracle-xe configure responseFile="${ORACLE_HOME}/config/scripts/xe.rsp"

# make start.sh
RUN cat <<-END > /start.sh
#!/bin/bash
sed -i -E "s/HOST = [^)]+/HOST = $HOSTNAME/g" $ORACLE_HOME/network/admin/listener.ora
sed -i -E "s/HOST = [^)]+/HOST = $HOSTNAME/g" $ORACLE_HOME/network/admin/tnsnames.ora
while true; do
    pmon=`ps -ef | grep pmon_$ORACLE_SID | grep -v grep`
    if [ "$pmon" == "" ]
    then
        date
        /etc/init.d/oracle-xe start
    fi
    sleep 1m
done;
END

# run script
CMD /start.sh

EXPOSE 1521
EXPOSE 8080