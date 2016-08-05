FROM ubuntu:latest

MAINTAINER Junjie Mars <junjiemars@gmail.com>

# pre-requirements
# ...
#

RUN apt-get -y update && \
    apt-get -y install \
	    bc \
	    build-essential \
	    coreutils \
	    curl \
	    dnsutils \
	    emacs-nox \
	    gdb \
	    git \
	    inetutils-ping \
	    inetutils-traceroute \
	    info \
	    initscripts \
	    install-info \
	    man-db \
	    manpages \
	    manpages-dev \
	    mtr-tiny \
	    netcat \
	    net-tools \
	    nmap \
	    openssh-server \
	    sudo \
	    vim-nox && \
	    rm -rf /var/lib/apt/lists/* 


ENV SUDOUSER=u
ENV UR_HOME=/home/${SUDOUSER}

# create sudo user
RUN useradd -m -s/bin/bash ${SUDOUSER} && \
    echo ${SUDOUSER}:Hell0 | chpasswd && \
    echo "\n\n##allow user:${SUDOUSER} to sudo" >> /etc/sudoers && \
    echo "${SUDOUSER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# configure gdb
RUN cd ${UR_HOME} ; \
    echo 'set disable-randomization off' >> .gdbinit

# switch to ${SUDOUSER}
USER ${SUDOUSER}

# cofigure bash env
RUN curl https://raw.githubusercontent.com/junjiemars/kit/master/ubuntu/.bashrc -o ${UR_HOME}/.bashrc && \
    curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/setup-bash.sh | HOME=${UR_HOME} bash 

# configure emacs
RUN cd ${UR_HOME} ; \
    git clone https://github.com/junjiemars/.emacs.d.git  && \
    echo 'export TERM=xterm' >> .bashrc
RUN test -f ${UR_HOME}/.emacs && rm ${UR_HOME}/.emacs

# switch back to ${SUDOUSER}
USER root

# start sshd service
RUN mkdir /var/run/sshd && \
    sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
CMD ["/usr/sbin/sshd", "-D"]

# run script
# ...
#

# set locale
#RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
#ENV LANGUAGE en_US:en
#ENV LC_ALL en_US.UTF-8

EXPOSE 22
EXPOSE 8000-9000
