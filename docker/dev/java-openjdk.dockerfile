FROM openjdk:8

LABEL authors="Junjie Mars <junjiemars@gmail.com>"


# pre-requirements
# ...
#

ENV TERM=xterm


RUN apt-get -y update && \
    apt-get -y install netselect-apt && \
    mv /etc/apt/sources.list /etc/apt/sources.list.ori && \
    netselect-apt -o /etc/apt/sources.list && \
    apt-get -y update && \
    apt-get -y install \
      automake \
	    bc \
	    build-essential \
      cmake \
      curl \
	    coreutils \
      dialog \
	    dnsutils \
	    emacs-nox \
	    gdb \
	    git \
	    inetutils-ping \
	    inetutils-traceroute \
	    info \
	    initscripts \
	    install-info \
      libssl-dev \
      libtool \
      libtool-bin \
		  locales \
		  locales-all \
	    man-db \
	    manpages \
	    manpages-dev \
	    mtr-tiny \
	    netcat \
	    net-tools \
	    nmap \
	    openssh-server \
      python \ 
      python2.7-dev \
      python-setuptools \
      software-properties-common \
	    sudo \
      unzip \
	    vim-nox \
      wget \
      zip && \
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
    mkdir -p /opt/run/bin && \
    mkdir -p /opt/run/sbin && \
    mkdir -p /opt/open && \
    mkdir -p /opt/apps && \
    mkdir -p /opt/lab  && \
    chown -R ${SUDOUSER}:${SUDOUSER} /opt

# configure gdb
RUN cd ${UR_HOME} && \
    echo 'set disable-randomization off' >> .gdbinit

# default locale 
RUN locale-gen en_US.UTF-8


# switch to ${SUDOUSER}
USER ${SUDOUSER}

# configure bash env
RUN curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/setup-bash.sh \
    | HOME=${UR_HOME} bash 

# configure emacs
RUN cd ${UR_HOME} ; \
    git clone --depth=1 --branch=master https://github.com/junjiemars/.emacs.d.git

# # download java kits script
# RUN curl -o ${UR_HOME}/install-java-kits.sh \
#     https://raw.githubusercontent.com/junjiemars/kit/master/ul/install-java-kits.sh
# # install java kits
RUN curl https://raw.githubusercontent.com/junjiemars/kit/docker/ul/install-java-kits.sh \
    | PREFIX=/opt HAS_ALL=YES bash


# switch back to ${SUDOUSER}
USER root

# start sshd service
RUN mkdir /var/run/sshd && \
    sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
CMD ["/usr/sbin/sshd", "-D"]

# run script
#

EXPOSE 22
EXPOSE 53
