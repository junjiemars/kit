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
        clang \
        clang-devel \
        coreutils \
        emacs \
        git \
        initscripts \
        lldb \
        lldb-devel \
        man-db \
        man-pages \
        mtr \
        net-tools \
        nmap \
        openssh-server \
        vim-enhanced && \
    yum -y group install 'Development Tools' && \
    yum clean all


ENV SUDOUSER=u
ENV UR_HOME=/home/${SUDOUSER}

# create sudo user
RUN useradd -m -s/bin/bash ${SUDOUSER}
RUN echo 'Hell0' | passwd ${SUDOUSER} --stdin
RUN gpasswd -a ${SUDOUSER} wheel

# configure chmod
RUN chmod u+s `type -p ping` && \
    chmod u+s `type -p ping6`

# chown home opt dirs
RUN chown -R ${SUDOUSER}:${SUDOUSER} ${UR_HOME} && \
    mkdir -p /opt/run/{bin,sbin,conf} && \
    chown -R ${SUDOUSER}:${SUDOUSER} /opt/run && \
    mkdir -p /opt/open && chown -R ${SUDOUSER}:${SUDOUSER} /opt/open && \
    mkdir -p /opt/apps && chown -R ${SUDOUSER}:${SUDOUSER} /opt/apps && \
    mkdir -p /opt/lab  && chown -R ${SUDOUSER}:${SUDOUSER} /opt/lab

# switch to ${SUDOUSER}
USER ${SUDOUSER}

# cofigure bash env
RUN curl https://raw.githubusercontent.com/junjiemars/kit/master/ubuntu/.bashrc -o ${UR_HOME}/.bashrc && \
    curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/setup-bash.sh | HOME=${UR_HOME} bash 

# configure emacs
RUN cd ${UR_HOME} ; \
    git clone https://github.com/junjiemars/.emacs.d.git && \
    echo 'export TERM=xterm' >> .bashrc 
RUN test -f ${UR_HOME}/.emacs && rm ${UR_HOME}/.emacs

# switch back to root
USER root

# start sshd service
CMD ["/usr/sbin/sshd", "-D"]

# run script
#

EXPOSE 22
EXPOSE 8000-9000
