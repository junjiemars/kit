FROM centos:latest

MAINTAINER Junjie Mars <junjiemars@gmail.com>

# pre-requirements
#...

RUN yum -y update && \
    yum -y install deltarpm && \
    echo '# enable deltarpm' >> /etc/yum.conf && \
    yum -y install \
        sudo \
        openssh-server \
        net-tools \
        git \
        bc \
        initscripts \
        vim-enhanced \
        coreutils \
        bind-utils \
        emacs && \
    yum -y group install 'Development Tools' && \
    yum clean all


ENV SUDOUSER=u
ENV HOME_DIR=/home/${SUDOUSER}

# create sudo user
RUN useradd -m -s/bin/bash ${SUDOUSER}
RUN echo 'Hell0' | passwd ${SUDOUSER} --stdin
RUN gpasswd -a ${SUDOUSER} wheel

# configure chmod
RUN chmod u+s `which ping` && \
    chmod u+s `which ping6` &&  \

# cofigure bash env
RUN curl https://raw.githubusercontent.com/junjiemars/kit/master/ubuntu/.bashrc -o ${HOME_DIR}/.bashrc ; \
    curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/.bash_aliases -o ${HOME_DIR}/.bash_aliases ; \
    curl https://raw.githubusercontent.com/junjiemars/kit/master/ubuntu/.bash_apps -o ${HOME_DIR}/.bash_apps

# configure vim
RUN cd ${HOME_DIR} && \
    echo 'set tabstop=2' >> .vimrc && \
    echo 'set shiftwidth=2' >> .vimrc && \
    echo 'set encoding=utf8' >> .vimrc && \
    echo 'set fileencoding=utf8' >> .vimrc

# configure emacs
RUN cd ${HOME_DIR} ; \
    git clone https://github.com/junjiemars/.emacs.d.git && \
    echo 'export TERM=xterm' >> .bashrc && \
    chown -R ${SUDOUSER}:${SUDOUSER} .emacs.d
RUN test -f ${HOME_DIR}/.emacs && rm ${HOME_DIR}/.emacs

# configure java
#...
#
RUN chown -R ${SUDOUSER}:${SUDOUSER} ${HOME_DIR}

# start sshd service
CMD ["/usr/sbin/sshd", "-D"]

# Run script
#

EXPOSE 22
