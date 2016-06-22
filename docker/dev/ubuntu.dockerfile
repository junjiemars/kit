FROM ubuntu:latest

MAINTAINER Junjie Mars <junjiemars@gmail.com>

# pre-requirements
# ...
#

RUN apt-get -y update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get -y install \
		  apt-utils \
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
		rm -rf /var/lib/apt/lists/* && \
		echo "\nexport TERM=xterm" >> /etc/bash.bashrc


ENV SUDOUSER=u
ENV HOME_DIR=/home/${SUDOUSER}

# create sudo user
RUN useradd -m -s/bin/bash ${SUDOUSER} && \
		echo ${SUDOUSER}:Hell0 | chpasswd && \
		echo "\n\n##allow user:${SUDOUSER} to sudo" >> /etc/sudoers && \
		echo "${SUDOUSER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# cofigure bash env
RUN curl https://raw.githubusercontent.com/junjiemars/kit/master/ubuntu/.bashrc -o ${HOME_DIR}/.bashrc ; \
    curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/.bash_aliases -o ${HOME_DIR}/.bash_aliases ; \
    curl https://raw.githubusercontent.com/junjiemars/kit/master/ubuntu/.bash_apps -o ${HOME_DIR}/.bash_app 

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

# chown ${HOME_DIR}
RUN chown -R ${SUDOUSER}:${SUDOUSER} ${HOME_DIR}

# start sshd service
RUN mkdir /var/run/sshd && \
		sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
CMD ["/usr/sbin/sshd", "-D"]

# Run script
# ...
#

# set locale
#RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
#ENV LANGUAGE en_US:en
#ENV LC_ALL en_US.UTF-8

EXPOSE 22
EXPOSE 9000
