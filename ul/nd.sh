#!/bin/bash
#------------------------------------------------
# nd.sh:	nginx-deployment script
# author: 	junjiemars@gmail.com
# configure > build & install > on the fly 
#------------------------------------------------
#echo "OPTIND starts at $OPTIND"
_d=0
_b=0
_s="./"
_t="./run"
_p=8080
_n=0
_i=101
_f="./nginx.conf"
_g=1

_usage() {
	echo "usage: $(basename $0) -h -s -t -b -p -n -i -f -g -d"
	echo -e "\t-h help"
	echo -e "\t-s source nginx dir"
	echo -e "\t-t target nginx run dir"
	echo -e "\t-b build nginx?, 0:no >0:build"
	echo -e "\t-p nginx listen port"
	echo -e "\t-n node number of cluster, base zero"
	echo -e "\t-i increment of cluster port"
	echo -e "\t-f nginx.conf template"
	echo -e "\t-g go, 0:shutdown >0:run"
	echo -e "\t-d debug flag"
}

_debug() {
	if [[ $_d -gt 0 ]]; then
		echo "$@"
	fi
}

_cpu_count() {
	local c_=$(grep -c ^processor /proc/cpuinfo)
	echo "$c_"
}

_signal_nginx() {
	local x_="$1sbin/nginx"
	local fpid_="$1/logs/nginx.pid"
	local fpid_old_="$1/logs/nginx.pid.oldbin"
	local s_="$2"

	if [ -f $x_ ]; then
		if  [ -f $fpid_ ]; then
			local pid_=$(cat $fpid_)
			if [[ 0 -eq "$(ps hp$pid_ 2>&1 1>/dev/null;echo $?)" ]]; then
				`$x_ -s$s_`
				wait
			fi

			if [ -f $fpid_old_ ]; then
				local pid_old_=$(cat $fpid_old_)
				if [[ 0 -eq "$(ps hp$pid_old_ 2>&1 1>/dev/null;echo $?)" ]]; then
					kill -QUIT $pid_old_
					wait
				fi
			fi

			if [[ 0 -eq $_g ]]; then
				_debug "# quit nginx [g:$_g]..."
				$x_ -squit
				wait
			fi
		else
			if [[ 0 -lt $_g ]]; then
				_debug "# start nginx [g:$_g]..."
				$x_
				wait
			fi
		fi
	fi
}

_build_nginx() {
	local s_=$1
	local t_=$2

	cd "$s_"
	_debug "# switch to " $(pwd)

	_debug "# build nginx..."
	make clean 
	./configure --prefix=$t_ \
	--without-http_rewrite_module \
	--without-http_scgi_module \
	--without-http_fastcgi_module \
	--without-http_uwsgi_module \
	--without-http_geo_module \
	--without-http_memcached_module \
	--without-http_empty_gif_module \
	--without-http_limit_req_module \
	--without-http_limit_conn_module; 
	make
	make install

	_debug "# switch back to $OLDPWD"
	cd - 2>&1 1>/dev/null
	_debug "# build nginx successed"
}

_make_nginx_conf() {
	local t_=$1
	local p_=$2	
	local n_=$3
	local i_=$4
	local nf_=$5

	local f_=$(($p_+$i_))
	local l_=$(($f_+$i_*$n_))
	local c_="$t_""conf/nginx.conf"
	local o_="$t_""conf/nginx.conf.old"
	local cpu_=$(_cpu_count)
	local conn_=1024
	local backends_=''

	if [ -f $c_ ]; then
		mv $c_ $o_
		_debug "# rename the existing nginx.conf to nginx.conf.old"
	fi

	if [[ 0 -eq $(cp $nf_ $c_ 2>/dev/null;echo $?) ]]; then
		_debug "# make nginx.conf[cpu.num:$cpu_|conn.num:$conn_|listen.port:$p_]"
		sed -i "s/\${cpu\.num}/$cpu_/g" $c_
		sed -i "s/\${conn\.num}/$conn_/g" $c_
		sed -i "s/\${listen\.port}/$p_/g" $c_

		for p in `seq $f_ $i_ $l_`; do
			_debug "# make backend[$p]"
			backends_="$backends_\t\tserver localhost:$p;\n"
		done
		sed -i "s/\${backend\.list}/$backends_/g" $c_
		
		_signal_nginx $t_ "reload"	
		_debug "# make nginx.conf successed"
	else
		_debug "# cp nginx.conf to $c_ failed"
	fi
}

if [[ $# -lt 1 ]]; then
	_usage
fi

while getopts "hs:t:bp:n:i:f:g:d" optname; do
	case "$optname" in
		s) eval _s="$OPTARG";;
		t) eval _t="$OPTARG";;
		b) let _b++;;
		p) eval _p="$OPTARG";;
		n) eval _n="$OPTARG";;
		i) eval _i="$OPTARG";;
		f) eval _f="$OPTARG";;
		g) eval _g="$OPTARG";;
		d) let _d++;;
		h) _usage;;
		?) _usage;;
		:) _usage;;
	esac
done

_debug "# calling args: [$0 -s$_s -t$_t -b$_b -p$_p -f$_n -i$_i -f$_f -g$_g -d$_d]"

if [ ! -f $_f ]; then
	_debug "# [$_f] does not exists, exiting..."
	exit $?
fi

if [ ! -d $_s ]; then
	_debug "# [-s:$_s] does not exists, exiting..."
	exit $?
fi

if [ ! -d $_t ]; then
	_debug "# [-t:$_t] does not exists, exiting..."
	exit $?
fi

if [[ $_b -gt 0 ]]; then
	_build_nginx $_s $_t
fi

_make_nginx_conf $_t $_p $_n $_i $_f

