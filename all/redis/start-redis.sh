#!/bin/bash

REDIS_HOME=/opt/redis/master
REDIS_BIN=$REDIS_HOME/bin
REDIS_CONF=$REDIS_HOME/conf/redis.conf
CPU_PIN=taskset -c 0

echo "starting redis: master/slave mode ..."

$CPU_PIN $REDIS_BIN/redis-server $REDIS_CONF $*

echo "started redis: master/slave mode ."
