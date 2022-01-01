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
      ant \
      automake \
	    bc \
	    build-essential \
      clang \
      cmake \
      curl \
	    coreutils \
      dialog \
	    dnsutils \
	    emacs-nox \
      gradle \
	    gdb \
	    git \
	    inetutils-ping \
	    inetutils-traceroute \
	    info \
	    install-info \
      less \
      libssl-dev \
      libtool \
      libtool-bin \
      lldb \
      llvm \
		  locales \
		  locales-all \
	    man-db \
	    manpages \
	    manpages-dev \
      maven \
	    mtr-tiny \
	    netcat \
	    net-tools \
	    nmap \
	    openssh-server \
      python \
      python-pip \
      python2.7-dev \
      python-setuptools \
      rsync \
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

# chown /home and /opt dirs
RUN mkdir -p ${UR_HOME}/.m2 && \
    chown -R ${SUDOUSER}:${SUDOUSER} ${UR_HOME} && \
    mkdir -p /opt/run/bin && \
    mkdir -p /opt/run/sbin && \
    mkdir -p /opt/open && \
    mkdir -p /opt/apps && \
    mkdir -p /opt/lab  && \
    chown -R ${SUDOUSER}:${SUDOUSER} /opt

# configure gdb
RUN cd ${UR_HOME} && \
    echo 'set disable-randomization off' >> .gdbinit && \
    chown -R ${SUDOUSER}:${SUDOUSER} ${UR_HOME}

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

# download java kits script
RUN curl -o /opt/run/bin/install-java-kits.sh \
    https://raw.githubusercontent.com/junjiemars/kit/master/ul/install-java-kits.sh && \
    chmod u+x /opt/run/bin/install-java-kits.sh

# ssh localhost password-less
RUN ssh-keygen -t rsa -P '' -f ${UR_HOME}/.ssh/id_rsa && \
    cat ${UR_HOME}/.ssh/id_rsa.pub > ${UR_HOME}/.ssh/authorized_keys && \
    chmod 600 ${UR_HOME}/.ssh/authorized_keys


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
