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
ENV HOME_DIR=/home/${SUDOUSER}

# create sudo user
RUN useradd -m -s/bin/bash ${SUDOUSER} && \
    echo 'Hell0' | passwd ${SUDOUSER} --stdin && \
    gpasswd -a ${SUDOUSER} wheel

# configure chmod
RUN chmod u+s `which ping` && \
    chmod u+s `which ping6`

# configure emacs
RUN cd ${HOME_DIR} ; \
    git clone --depth=1 https://github.com/junjiemars/.emacs.d.git && \
    chown -R ${SUDOUSER}:${SUDOUSER} .emacs.d
RUN test -f ${HOME_DIR}/.emacs && rm ${HOME_DIR}/.emacs

# configure vim 
RUN curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/.vimrc -o ${HOME_DIR}/.vimrc 
 
# configure java
ENV JDK='jdk-8u91-linux-x64.rpm'
RUN curl -vkL -H'Cookie: oraclelicense=accept-securebackup-cookie' -O "http://download.oracle.com/otn-pub/java/jdk/8u91-b14/${JDK}" && \
    rpm -ivh ${JDK} && \
    rm ${JDK}
    
# cofigure bash env
RUN curl https://raw.githubusercontent.com/junjiemars/kit/master/ubuntu/.bashrc -o ${HOME_DIR}/.bashrc && \
    curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/setup-bash.sh | HOME=${HOME_DIR} bash 

# chown home opt dirs
RUN chown -R ${SUDOUSER}:${SUDOUSER} ${HOME_DIR} && \
    mkdir -p /opt/run/{bin,sbin,conf} && \
    chown -R ${SUDOUSER}:${SUDOUSER} /opt/run && \
    mkdir -p /opt/open && chown -R ${SUDOUSER}:${SUDOUSER} /opt/open && \
    mkdir -p /opt/apps && chown -R ${SUDOUSER}:${SUDOUSER} /opt/apps && \
    mkdir -p /opt/lab  && chown -R ${SUDOUSER}:${SUDOUSER} /opt/lab

# install and setup building tools and programming environment 
ENV HAS_ALL="HAS_ANT=1 HAS_MAVEN=1 HAS_BOOT=1 HAS_GRADLE=1 HAS_GROOVY=1 HAS_SCALA=1 "
RUN . $HOME/.bashrc && \
    curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/install-java-kits.sh | "$HAS_ALL" bash

# start sshd service
CMD ["/usr/sbin/sshd", "-D"]

# Run script
# ...
#

# set locale
# RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

EXPOSE 22
EXPOSE 8000-9000
