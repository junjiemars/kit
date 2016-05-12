FROM centos:centos7

MAINTAINER Junjie Mars <junjiemars@gmail.com>

# pre-requirements
#...

RUN yum install -y deltarpm

RUN yum install -y \
    sudo \
    openssh-server \
    net-tools \
    git \
    bc \
    initscripts \
    vim-enhanced \
    coreutils

RUN yum group install -y \
    'Development Tools'

# create sudo user
ENV SUDOUSER=u
RUN useradd -m -s/bin/bash ${SUDOUSER}
RUN echo 'Hell0' | passwd ${SUDOUSER} --stdin
RUN gpasswd -a ${SUDOUSER} wheel

# cofigure bash env
RUN cd /home/${SUDOUSER} ;\
    curl -O https://raw.githubusercontent.com/junjiemars/kit/master/ubuntu/.bashrc ;\
    curl -O https://raw.githubusercontent.com/junjiemars/kit/master/ul/.bash_aliases ;\
    curl -O https://raw.githubusercontent.com/junjiemars/kit/master/ubuntu/.bash_apps ;\
    chown -R ${SUDOUSER}:${SUDOUSER} /home/${SUDOUSER}

# configure java
#ENV PATH        $ORACLE_HOME/bin:$PATH

# start sshd service
CMD ["/usr/sbin/sshd", "-D"]

# Run script
#

EXPOSE 22
