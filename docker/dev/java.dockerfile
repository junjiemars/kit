FROM centos:latest

MAINTAINER Junjie Mars <junjiemars@gmail.com>

# pre-requirements
#...

RUN yum -y update && \
    yum -y install deltarpm && \
    echo '# enable deltarpm' >> /etc/yum.conf && \
    sed -i 's/tsflags=nodocs/#tsflags=nodocs/g' /etc/yum.conf && \
    yum -y install \
        bc \
        bind-utils \
        coreutils \
        emacs \
        git \
        initscripts \
        nmap \
        man-db \
        man-pages \
        mtr \
        net-tools \
        openssh-server \
        sudo \
        unzip \
        vim-enhanced && \
    yum -y group install 'Development Tools' && \
    yum clean all


ENV SUDOUSER=u
ENV UR_HOME=/home/${SUDOUSER}

# create sudo user
RUN useradd -m -s/bin/bash ${SUDOUSER} && \
    echo 'Hell0' | passwd ${SUDOUSER} --stdin && \
    gpasswd -a ${SUDOUSER} wheel

# configure chmod
RUN chmod u+s `type -p ping` && \
    chmod u+s `type -p ping6`

# configure java
ENV JDK='jdk-8u91-linux-x64.rpm'
ENV JAVA_HOME='/usr/java/jdk1.8.0_91'
RUN curl -vkL -H'Cookie: oraclelicense=accept-securebackup-cookie' -O "http://download.oracle.com/otn-pub/java/jdk/8u91-b14/${JDK}" && \
    rpm -ivh ${JDK} && \
    rm ${JDK}
    
# chown home opt dirs
RUN chown -R ${SUDOUSER}:${SUDOUSER} ${UR_HOME} && \
    mkdir -p /opt/run/{bin,sbin,conf} && \
    chown -R ${SUDOUSER}:${SUDOUSER} /opt/run && \
    mkdir -p /opt/open && chown -R ${SUDOUSER}:${SUDOUSER} /opt/open && \
    mkdir -p /opt/apps && chown -R ${SUDOUSER}:${SUDOUSER} /opt/apps && \
    mkdir -p /opt/lab  && chown -R ${SUDOUSER}:${SUDOUSER} /opt/lab

# switch to ${SUDOUSER}
USER ${SUDOUSER}

# configure emacs
RUN cd ${UR_HOME} && \
    git clone --depth=1 --branch=master https://github.com/junjiemars/.emacs.d.git
RUN test -f ${UR_HOME}/.emacs && rm ${UR_HOME}/.emacs

# cofigure bash env
RUN curl https://raw.githubusercontent.com/junjiemars/kit/master/ubuntu/.bashrc -o ${UR_HOME}/.bashrc && \
    curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/setup-bash.sh | HOME=${UR_HOME} bash 

# download install-java-kits script
# HAS_ALL=YES install-java-kits.sh
RUN cd /opt/run/bin/ && \
    curl -vkL -O -C - https://raw.githubusercontent.com/junjiemars/kit/master/ul/install-java-kits.sh &&  \
    chown u+x install-java-kits.sh

# switch back to root
USER root

# start sshd service
CMD ["/usr/sbin/sshd", "-D"]

# run script
# ...
#

# set locale
# RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

EXPOSE 22
EXPOSE 53
EXPOSE 80
EXPOSE 8080-8090
