FROM centos:latest

MAINTAINER Junjie Mars <junjiemars@gmail.com>

# pre-requirements
#...

RUN yum -y update && \
    yum -y install deltarpm && \
    echo '# enable deltarpm' >> /etc/yum.conf && \
    sed -i 's/tsflags=nodocs/#tsflags=nodocs/g' /etc/yum.conf && \
    yum -y install \
        bc \
        bind-utils \
        coreutils \
        emacs \
        git \
        initscripts \
        man-db \
        man-pages \
        net-tools \
        openssh-server \
        sudo \
        vim-enhanced \
        mtr \
	nmap && \
    yum -y group install 'Development Tools' && \
    yum clean all


ENV SUDOUSER=u
ENV HOME_DIR=/home/${SUDOUSER}

# create sudo user
RUN useradd -m -s/bin/bash ${SUDOUSER} && \
    echo 'Hell0' | passwd ${SUDOUSER} --stdin && \
    gpasswd -a ${SUDOUSER} wheel

# configure chmod
RUN chmod u+s `which ping` && \
    chmod u+s `which ping6`

# cofigure bash env
RUN curl https://raw.githubusercontent.com/junjiemars/kit/master/ubuntu/.bashrc -o ${HOME_DIR}/.bashrc ; \
    curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/.bash_aliases -o ${HOME_DIR}/.bash_aliases ; \
    curl https://raw.githubusercontent.com/junjiemars/kit/master/ubuntu/.bash_apps -o ${HOME_DIR}/.bash_apps

# configure vim
RUN cd ${HOME_DIR} && \
    echo 'set tabstop=2' >> .vimrc && \
    echo 'set shiftwidth=2' >> .vimrc && \
    echo 'set expandtab' >> .vimrc && \
    echo 'set encoding=utf8' >> .vimrc && \
    echo 'set fileencoding=utf8' >> .vimrc

# configure emacs
RUN cd ${HOME_DIR} ; \
    git clone https://github.com/junjiemars/.emacs.d.git && \
    echo 'export TERM=xterm' >> .bashrc && \
    chown -R ${SUDOUSER}:${SUDOUSER} .emacs.d
RUN test -f ${HOME_DIR}/.emacs && rm ${HOME_DIR}/.emacs

# configure java
ENV JDK='jdk-8u91-linux-x64.rpm'
RUN curl -vkL -H'Cookie: oraclelicense=accept-securebackup-cookie' -O "http://download.oracle.com/otn-pub/java/jdk/8u91-b14/${JDK}" && \
    rpm -ivh ${JDK} && \
    rm ${JDK}
    
# chown home dir
RUN chown -R ${SUDOUSER}:${SUDOUSER} ${HOME_DIR}

# start sshd service
CMD ["/usr/sbin/sshd", "-D"]

# Run script
# ...
#

# set locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

EXPOSE 22
EXPOSE 9000
