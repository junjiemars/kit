#!/bin/bash

RUN=2
DEBUG=${DEBUG:=0}
BUILD=${BUILD:=0}
IFS=', ' read -a NODES <<< "jira:/opt/redis/n0:/opt/redis/redis.git,/opt/bin/redis/n1:/opt/bin/redis/redis.git,/opt/bin/redis/n2"
MODE=${MODE:=2} ## 0:master, 1:sentinel, 2:cluster

## build & install all nodes from source
## ===========================
echo ${NODES[0]}
IFS=':' read -a X <<< "${NODES[0]}"
echo ${X[@]}
echo ${#X[@]}
echo "${X[0]}"
echo "${X[1]}"
#SRC=${SRC:=$PWD}
CONF=redis.conf
CONF_INC=redis-included.conf
CONF_INC_DIR=$PWD
TRIB=redis-trib.rb
PORT_BASE=7000
PORT_INCR=${PORT_INCR:=1}
PORT=$PORT_BASE
install() {
##if [ "$RUN" -gt 1 ]; then
    for n in "${NODES[@]}"; do
        if [ "$PORT_INCR" -gt 0 ];then
            PORT=$(($PORT+$PORT_INCR))
        fi
        IFS=':' read -a u <<< "$n"
        ##!the last: "${u[((${#u[@]}-1))]}"
        if [ "${#u[@]}" -gt 2 ];then
            uid=${u[0]}
            dst=${u[1]}
            src=${u[2]}
            ssh $uid "mkdir -p $dst $dst/conf $dst/db $dst/log;" \
                "make PREFIX=$dst -C$src install"
            ssh $uid "test -e $src/src/redis-trib.rb"
            if [ $(ssh -q $uid [[ -f $src/src/$TRIB ]];echo $?) -eq 0 ];then
                cp $src/src/$TRIB $dst/bin
            fi
            ssh $uid "cp -r $src/utils $dst;" \
                "cp $src/$CONF $dst/conf/"
            scp $CONF_INC_DIR/$CONF_INC $uid:$dst/conf/
            ssh $uid "sed -ie 's/\${port}/${PORT}/' ${dst}/conf/$CONF_INC"
            ssh $uid "sed -ie 's%\${dir}%${dst}/db/%' ${dst}/conf/$CONF_INC"
            ssh $uid "sed -ie 's%\${pid}%${dst}/log/pid%' ${dst}/conf/$CONF_INC"
            ssh $uid "sed -ie 's%\${logfile}%${dst}/log/${PORT}.log%' ${dst}/conf/$CONF_INC"
            ssh $uid "echo -en 'include ${dst}/conf/${CONF_INC}\n' >> ${dst}/conf/$CONF"
        else
            dst=${u[0]}
            if [ "${#u[@]}" -eq 2 ];then
                src=${u[1]}
            else
                src=$PWD
            fi
            mkdir -p $dst;make PREFIX=$dst -C$src install
            if [[ -f $src/src/$TRIB ]];then
                cp $src/src/$TRIB $dst/bin
            fi
            cp -r $src/utils $dst/
            cp $src/$CONF $dst/conf/
            cp $CONF_INC_DIR/$CONF_INC $dst/conf/
            sed -ie "s/\${port}/$PORT/" $dst/conf/$CONF_INC
            sed -ie "s%\${dir}%$dst/db/%" $dst/conf/$CONF_INC
            sed -ie "s%\${pid}%$dst/log/pid%" $dst/conf/$CONF_INC
            sed -ie "s%\${logfile}%$dst/log/$PORT.log%" $dst/conf/$CONF_INC
            echo -en "include $dst/conf/$CONF_INC\n" >> $dst/conf/$CONF
        fi
    done
##fi
}
install

## start all nodes from the source
## ===========================
##IP=( '127.0.0.1:' '127.0.0.1:' '127.0.0.1:' )
##PORT=$PORT_BASE
##if [ "$RUN" -ge 2 ]; then
##    for i in "${!IP[@]}"; do
##        if [ "$PORT_INCR" -gt 0 ]; then
##            PORT=$(($PORT+$PORT_INCR))
##        fi
##        IP[$i]=${IP[$i]}$PORT
##    done
##    for n in "${NODES[@]}"; do
##        $($dst/bin/redis-server $dst/conf/$CONF --loglevel verbose )
##    done
##fi
##
#### create cluster
#### ===========================
##REPLICAS=" --replicas 0 "
##if [ "$RUN" -ge 3 ]; then
##    echo ${IP[@]}
##    #$SRC/src/redis-trib.rb create $REPLICAS ${IP[@]}
##fi

## setup clusters

## configure clusters
