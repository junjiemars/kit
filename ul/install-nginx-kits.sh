#!/bin/sh

NGX_DIR=${NGX_DIR:-"/opt/open/nginx"}
PREFIX_DIR=${PREFIX_DIR:-"/opt/run"}
CFLAGS=${CFLAGS:-"-g -O0"}
TO_MAKE=${TO_MAKE:-"0"}
TO_INSTALL=${TO_INSTALL:-"0"}
LISTEN_ADDR=${LISTEN_ADDR:-"127.0.0.1:5533"}
FORWARD_ADDR=${FORWARD_ADDR:-"8.8.4.4:53"}

cd $NGX_DIR 

CFLAGS=${CFLAGS} ./auto/configure \
  --prefix=/opt/run \
  --without-http \
  --without-http-cache \
  --without-mail_pop3_module \
  --without-mail_imap_module \
  --without-mail_smtp_module \
  --with-stream \
  --without-stream_geo_module \
  --without-stream_map_module \
  --without-stream_split_clients_module \
  --without-stream_limit_conn_module \
  --without-pcre \
  --with-debug 

[ 0 -lt ${TO_MAKE} ] && make
[ 0 -lt ${TO_INSTALL} ] && make install && \
cat << END > ${PREFIX_DIR}/conf/nginx.conf
#user  nobody;
worker_processes  1;

#error_log  logs/nginx.log;
#error_log  logs/nginx.log  notice;
#error_log  logs/nginx.log  info;
error_log  logs/nginx.log  debug;
#error_log  memory:32m  debug;

pid logs/nginx.pid;
daemon on;
debug_points abort;

events {
    worker_connections  64;
    debug_connection 127.0.0.1;
}

stream {
    upstream dns {
        server ${FORWARD_ADDR};
    }

    server {
        listen ${LISTEN_ADDR} udp;
        proxy_pass dns;
    }
}
END
