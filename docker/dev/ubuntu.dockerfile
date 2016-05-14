FROM ubuntu:latest

MAINTAINER Junjie Mars <junjiemars@gmail.com>

# pre-requirements
#...

RUN apt-get -y update && \
    apt-get -y install \
        sudo \
        openssh-server \
				build-essential \
        net-tools \
        git \
				curl \
        bc \
        initscripts \
        coreutils \
				dnsutils \
				inetutils-ping \
				inetutils-traceroute \
        emacs \
        vim && \
    apt-get -y autoclean 


ENV SUDOUSER=u
ENV HOME_DIR=/home/${SUDOUSER}

# create sudo user
RUN useradd -m -s/bin/bash ${SUDOUSER} && \
		echo ${SUDOUSER}:Hell0 | chpasswd 

# cofigure bash env
RUN cd ${HOME_DIR} ; \
    curl -O https://raw.githubusercontent.com/junjiemars/kit/master/ubuntu/.bashrc ; \
    curl -O https://raw.githubusercontent.com/junjiemars/kit/master/ul/.bash_aliases ; \
    curl -O https://raw.githubusercontent.com/junjiemars/kit/master/ubuntu/.bash_apps

# configure vim
RUN cd ${HOME_DIR} ; \
    echo 'set tabstop=2' >> .vimrc && \
    echo 'set shiftwidth=2' >> .vimrc && \
    echo 'set encoding=utf8' >> .vimrc && \
    echo 'set fileencoding=utf8' >> .vimrc

# configure emacs
RUN cd ${HOME_DIR} ; \
    git clone https://github.com/junjiemars/.emacs.d.git  && \
    echo 'export TERM=xterm' >> .bashrc && \
    chown -R ${SUDOUSER}:${SUDOUSER} .emacs.d

# configure java
#...
#
RUN chown -R ${SUDOUSER}:${SUDOUSER} ${HOME_DIR}

# start sshd service
RUN mkdir /var/run/sshd && \
		sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
CMD ["/usr/sbin/sshd", "-D"]

# Run script
#

EXPOSE 22
