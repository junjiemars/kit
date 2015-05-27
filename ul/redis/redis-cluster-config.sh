#!/bin/bash

## build & install all nodes from source
## ===========================
SRC=/opt/bin/redis/redis.git
CONF=redis-cluster.conf
CONF_INC=redis-cluster-included.conf
RUN=( '/opt/bin/redis/n0' '/opt/bin/redis/n1' '/opt/bin/redis/n2' )
# include /path/to/local.conf
for n in "${RUN[@]}"; do
    mkdir -p $n/conf $n/db
    pushd $SRC
    make -f "${SRC}/Makefile" PREFIX=$n install
    popd
    cp $SRC/src/redis-trib.rb  $n/bin
    cp -r $SRC/utils $n/
    cp $SRC/redis.conf $n/conf/$CONF
    cp $CONF_INC $n/conf/
    conf=$(cat $n/conf/$CONF)
    echo -en "include $n/conf/$CONF_INC\n$conf" > $n/conf/$CONF
done

## start all nodes from the source
## ===========================
##redis-trib.rb create --replicas 1 127.0.0.1:7001 127.0.0.1:7002

## setup clusters

## configure clusters
