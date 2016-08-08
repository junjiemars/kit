FROM ubuntu:latest

MAINTAINER Junjie Mars <junjiemars@gmail.com>

# pre-requirements
# ...
#

ENV TERM=xterm

# choose mirror based on geo
RUN sed -i.ori 's#http:\/\/archive.ubuntu.com\/ubuntu\/#mirror:\/\/mirrors.ubuntu.com\/mirrors.txt#' /etc/apt/sources.list && \
    apt-get -y update && \
    apt-get -y install curl

RUN curl -s ipinfo.io | grep '"country": "CN",' && \
    sed -i 's#mirror:\/\/mirrors.ubuntu.com\/mirrors.txt#http:\/\/jp.archive.ubuntu.com\/ubuntu\/#' /etc/apt/sources.list 

RUN apt-get -y update && \
    apt-get -y install \
	    bc \
	    build-essential \
	    coreutils \
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

# chown home opt dirs
RUN chown -R ${SUDOUSER}:${SUDOUSER} ${UR_HOME} && \
    mkdir -p /opt/run/{bin,sbin,conf} && \
    chown -R ${SUDOUSER}:${SUDOUSER} /opt/run && \
    mkdir -p /opt/open && chown -R ${SUDOUSER}:${SUDOUSER} /opt/open && \
    mkdir -p /opt/apps && chown -R ${SUDOUSER}:${SUDOUSER} /opt/apps && \
    mkdir -p /opt/lab  && chown -R ${SUDOUSER}:${SUDOUSER} /opt/lab

# configure gdb
RUN cd ${UR_HOME} && \
    echo 'set disable-randomization off' >> .gdbinit

# switch to ${SUDOUSER}
USER ${SUDOUSER}

# cofigure bash env
RUN curl https://raw.githubusercontent.com/junjiemars/kit/master/ubuntu/.bashrc -o ${UR_HOME}/.bashrc && \
    curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/setup-bash.sh | HOME=${UR_HOME} bash 

# configure emacs
RUN cd ${UR_HOME} ; \
    git clone --depth=1 --branch=master https://github.com/junjiemars/.emacs.d.git  && \
    echo 'export TERM=xterm' >> .bashrc
#RUN test -f ${UR_HOME}/.emacs && rm ${UR_HOME}/.emacs

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
EXPOSE 53
EXPOSE 80
EXPOSE 8080-8090
