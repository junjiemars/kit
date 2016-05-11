FROM centos:centos7

MAINTAINER Junjie Mars <junjiemars@gmail.com>

# Pre-requirements
#...

RUN yum install -y \
    sudo \
    openssh-server \
    git \
    bc \
    initscripts \
    vim \
    net-tools

ENV user foo

# Create sudo user ${user}
RUN useradd -m -s/bin/bash ${user}
RUN echo '${user}' | passwd ${user} --stdin
RUN gpasswd -a ${user} wheel

# Configure instance
#ENV PATH        $ORACLE_HOME/bin:$PATH

# Start sshd service
CMD ["/usr/sbin/sshd", "-D"]

# Run script
#

EXPOSE 22
