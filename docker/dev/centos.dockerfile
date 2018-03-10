FROM centos:latest

LABEL authors="Junjie Mars <junjiemars@gmail.com>"

# pre-requirements
#...

RUN yum -y update && \
    yum -y install deltarpm && \
    echo '# enable deltarpm' >> /etc/yum.conf && \
    sed -i 's/tsflags=nodocs/#tsflags=nodocs/g' /etc/yum.conf && \
    yum -y install \
        bash-completion \   
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
        sudo \
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

# default locale
RUN localedef -i en_US -f UTF-8 en_US.UTF-8

# chown home opt dirs
RUN chown -R ${SUDOUSER}:${SUDOUSER} ${UR_HOME} && \
    mkdir -p /opt/run/bin && \
		mkdir -p /opt/run/sbin && \
    mkdir -p /opt/run/conf && \
    chown -R ${SUDOUSER}:${SUDOUSER} /opt/run && \
    mkdir -p /opt/open && chown -R ${SUDOUSER}:${SUDOUSER} /opt/open && \
    mkdir -p /opt/apps && chown -R ${SUDOUSER}:${SUDOUSER} /opt/apps && \
    mkdir -p /opt/lab  && chown -R ${SUDOUSER}:${SUDOUSER} /opt/lab

# generate ssh keys
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key && \
    ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key && \
    ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key


# switch to ${SUDOUSER}
USER ${SUDOUSER}

# configure bash env
RUN curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/setup-bash.sh \
    | HOME=${UR_HOME} bash 

# configure emacs
RUN cd ${UR_HOME} && \
    git clone --depth=1 --branch=master https://github.com/junjiemars/.emacs.d.git && \
    test ! -f ${UR_HOME}/.emacs || rm ${UR_HOME}/.emacs


# switch back to root
USER root

# start sshd service
CMD ["/usr/sbin/sshd", "-D"]

# run script
#

EXPOSE 22
EXPOSE 53
