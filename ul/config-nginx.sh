#!/bin/bash

build_dir=nginx.git
prefix_dir=/opt/nginx/run
echo "# $build_dir --prefix=$prefix_dir"
cd "$build_dir"
echo `pwd`

pushd /opt/nginx/src
echo `pwd`
./configure --prefix="$prefix_dir" \
--add-module=/opt/nginx/clojure/src/c/
#--without-http_rewrite_module \
#--without-http_scgi_module \
#--without-http_fastcgi_module \
#--without-http_uwsgi_module \
#--without-http_geo_module \
#--without-http_memcached_module \
#--without-http_empty_gif_module
#--without-http_limit_req_module \
#--without-http_limit_zone_module \
#--without-http_limit_conn_module 

popd
