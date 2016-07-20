#!/bin/sh

NGX_DIR=${NGX_DIR:-"/opt/open/nginx"}
PREFIX_DIR=${PREFIX_DIR:-"/opt/run"}
CFLAGS=${CFLAGS:-"-g -O0"}
TO_MAKE=${TO_MAKE:-"0"}
TO_INSTALL=${TO_INSTALL:-"0"}


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
  --without-stream_limit_conn_module \
  --without-pcre \
  --with-debug 

[ 0 -lt ${TO_MAKE} ] && make
[ 0 -lt ${TO_INSTALL} ] && make install
