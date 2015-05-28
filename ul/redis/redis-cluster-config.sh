#!/bin/bash

START=2

## build & install all nodes from source
## ===========================
SRC=/opt/redis/redis.git
CONF=redis-cluster.conf
CONF_INC=redis-cluster-included.conf
PORT_BASE=7000
PORT_INCR=1
RUN=( '/opt/redis/n0' '/opt/redis/n1' '/opt/redis/n2' )
PORT=$PORT_BASE
if [ "$START" -gt 2 ]; then
    for n in "${RUN[@]}"; do
        mkdir -p $n/conf $n/db $n/log
        pushd $SRC
        make -f "${SRC}/Makefile" PREFIX=$n install
        popd
        echo $PWD
        cp $SRC/src/redis-trib.rb  $n/bin
        cp -r $SRC/utils $n/
        cp $SRC/redis.conf $n/conf/$CONF
        cp $CONF_INC $n/conf/
        conf=$(cat $n/conf/$CONF)
        ##insert before the first line
        ##echo -en "include $n/conf/$CONF_INC\n$conf" > $n/conf/$CONF
        echo -en "include $n/conf/$CONF_INC\n" >> $n/conf/$CONF
        if [ "$PORT_INCR" -gt 0 ]; then
            PORT=$(($PORT+$PORT_INCR))
        fi
        sed -i "s/\${port}/$PORT/" $n/conf/$CONF_INC
        sed -i "s%\${dir}%$n/db/%" $n/conf/$CONF_INC
        sed -i "s%\${pid}%$n/log/pid%" $n/conf/$CONF_INC
        sed -i "s%\${logfile}%$n/log/$port.log%" $n/conf/$CONF_INC
    done
fi

## start all nodes from the source
## ===========================
IP=( '127.0.0.1:' '127.0.0.1:' '127.0.0.1:' )
PORT=$PORT_BASE
if [ "$START" -ge 2 ]; then
    for i in "${!IP[@]}"; do
        if [ "$PORT_INCR" -gt 0 ]; then
            PORT=$(($PORT+$PORT_INCR))
        fi
        IP[$i]=${IP[$i]}$PORT
    done
    for n in "${RUN[@]}"; do
        $($n/bin/redis-server $n/conf/$CONF --loglevel verbose )
    done
fi

## create cluster
## ===========================
REPLICAS=" --replicas 0 "
if [ "$START" -ge 3 ]; then
    echo ${IP[@]}
    #$SRC/src/redis-trib.rb create $REPLICAS ${IP[@]}
fi

## setup clusters

## configure clusters
