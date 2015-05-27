#!/bin/bash

REDIS_HOME=/opt/redis/master
REDIS_BIN=$REDIS_HOME/bin
REDIS_CONF=$REDIS_HOME/conf/sentinel.conf
CPU_PIN=taskset -c 1

echo "starting redis-sentinel: master/slave mode ..."

$CPU_PIN $REDIS_BIN/redis-server $REDIS_CONF --sentinel $*

echo "started redis-sentinel: master/slave mode ."
