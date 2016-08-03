FROM centos:latest

MAINTAINER Junjie Mars <junjiemars@gmail.com>

# pre-requirements
#...

RUN yum -y update && \
    yum -y install deltarpm && \
    echo '# enable deltarpm' >> /etc/yum.conf && \
    sed -i 's/tsflags=nodocs/#tsflags=nodocs/g' /etc/yum.conf && \
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
        mtr \
        nmap \
        emacs \
        man-db \
        man-pages && \
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
    chmod u+s `which ping6`

# cofigure bash env
RUN curl https://raw.githubusercontent.com/junjiemars/kit/master/ubuntu/.bashrc -o ${HOME_DIR}/.bashrc && \
    curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/setup-bash.sh | HOME=${HOME_DIR} bash 

# configure emacs
RUN cd ${HOME_DIR} ; \
    git clone https://github.com/junjiemars/.emacs.d.git && \
    echo 'export TERM=xterm' >> .bashrc && \
    chown -R ${SUDOUSER}:${SUDOUSER} .emacs.d
RUN test -f ${HOME_DIR}/.emacs && rm ${HOME_DIR}/.emacs

# chown ${HOME_DIR} 
RUN chown -R ${SUDOUSER}:${SUDOUSER} ${HOME_DIR}

# start sshd service
CMD ["/usr/sbin/sshd", "-D"]

# run script
#

EXPOSE 22
EXPOSE 9000
