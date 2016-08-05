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
ENV UR_HOME=/home/${SUDOUSER}

# create sudo user
RUN useradd -m -s/bin/bash ${SUDOUSER}
RUN echo 'Hell0' | passwd ${SUDOUSER} --stdin
RUN gpasswd -a ${SUDOUSER} wheel

# configure chmod
RUN chmod u+s `which ping` && \
    chmod u+s `which ping6`

# switch to ${SUDOUSER}
RUN ${SUDOUSER}

# cofigure bash env
RUN curl https://raw.githubusercontent.com/junjiemars/kit/master/ubuntu/.bashrc -o ${UR_HOME}/.bashrc && \
    curl https://raw.githubusercontent.com/junjiemars/kit/master/ul/setup-bash.sh | HOME=${UR_HOME} bash 

# configure emacs
RUN cd ${UR_HOME} ; \
    git clone https://github.com/junjiemars/.emacs.d.git && \
    echo 'export TERM=xterm' >> .bashrc 
RUN test -f ${UR_HOME}/.emacs && rm ${UR_HOME}/.emacs

# switch back to root
USER root

# start sshd service
CMD ["/usr/sbin/sshd", "-D"]

# run script
#

EXPOSE 22
EXPOSE 9000
