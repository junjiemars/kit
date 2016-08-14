#!/bin/bash
#------------------------------------------------
# author: junjiemars@gmail.com
# target: Nginx Kits
# 
#------------------------------------------------

oNGX_DIR=${NGX_DIR:-"/opt/open/nginx"}
PREFIX_DIR=${PREFIX_DIR:-"/opt/run"}

DEBUG=${DEBUG:-"0"}
DAEMON=${DAEMON:-"on"}

DNS_LISTEN_IP=${DNS_LISTEN_IP:-"127.0.0.1"}
DNS_LISTEN_PORT=${DNS_LISTEN_PORT:-"5533"}
DNS_LISTEN_ADDR=${DNS_LISTEN_ADDR:-"${DNS_LISTEN_IP}:${DNS_LISTEN_PORT}"}
DNS_FORWARD_ADDR=${DNS_FORWARD_ADDR:-"8.8.4.4:53"}
DNS_FEATURES=" \
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
  --without-pcre"

config() {
  local features="`echo ${1} | tr -d '\n' | tr -s ' '`"
  cd "${NGX_DIR}"
  if [ ! -x "${NGX_DIR}/auto/configure" ]; then
    echo -e "${NGX_DIR}/auto/configure no found, panic!"
    return 1
  fi

  if [ 0 -lt "${DEBUG}" ]; then
    local dbg="--with-debug"
    CFLAGS="${CFLAGS} -g -O0"
  fi

  cd "${NGX_DIR}"
  ./auto/configure --prefix=${PREFIX_DIR} ${features} ${dbg}; echo $?
}

build() {
  cd "${NGX_DIR}"; make
  cd "${NGX_DIR}"; make install
}

setup_dns() {
  config "${DNS_FEATURES}"
  [ 0 -ne `echo $?` ] && return 1

  build
   
  if [ 0 -lt "${DEBUG}" ]; then
    local log="debug"
    local cnt="64"
  else
    local log="info"
    local cnt="1024"
  fi
cat << END > ${PREFIX_DIR}/conf/nginx.conf
worker_processes  1;

#error_log  logs/nginx.log;
#error_log  logs/nginx.log  notice;
#error_log  logs/nginx.log  info;
error_log  logs/nginx.log  ${log};
#error_log  memory:32m  debug;

pid logs/nginx.pid;
daemon ${DAEMON};
debug_points abort;

events {
    worker_connections  ${cnt};
    #debug_connection 127.0.0.1;
}

stream {
    upstream dns {
        server ${DNS_FORWARD_ADDR};
    }

    server {
        listen ${DNS_LISTEN_ADDR} udp;
        proxy_pass dns;
    }
}
END
}

usage() {
  echo -e "Usage: $(basename $0) [OPTIONS] COMMAND [arg...]"
  echo -e "       $(basename $0) [ -h | --help ]\n"
  echo -e "Options:"
  echo -e "  -h, --help\t\tPrint usage"
  echo -e "A tiny-handy kits for nginx.\n"
  echo -e "Commands:"
  echo -e "\tdns\t\tSetup a DNS server"
}

case ".$@" in
  .dns) setup_dns ;;
  .-h|.--help) usage ;;
  .*) usage ;;
esac

