FROM centos:centos7

MAINTAINER Junjie Mars <junjiemars@gmail.com>

# pre-requirements
#...

RUN yum install -y \
    sudo \
    openssh-server \
    net-tools \
    git \
    bc \
    initscripts \
    vim \
    coreutils

ENV user foo

# create sudo user ${SUDOUSER}
ENV SUDOUSER=u
RUN useradd -m -s/bin/bash ${SUDOUSER}
RUN echo '${SUDOUSER}' | passwd ${SUDOUSER} --stdin
RUN gpasswd -a ${SUDOUSER} wheel

# cofigure bash env
RUN cd /home/${SUDOUSER} ;\
    curl -O https://raw.githubusercontent.com/junjiemars/kit/master/ubuntu/.bashrc ;\
    curl -O https://raw.githubusercontent.com/junjiemars/kit/master/ubuntu/.bash_aliases ;\
    curl -O https://raw.githubusercontent.com/junjiemars/kit/master/ubuntu/.bash_apps

# Configure instance
#ENV PATH        $ORACLE_HOME/bin:$PATH

# start sshd service
CMD ["/usr/sbin/sshd", "-D"]

# Run script
#

EXPOSE 22
