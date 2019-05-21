#!/bin/bash
#------------------------------------------------
# require: bash env
# target : nginx maker
# author : junjiemars@gmail.com
# url    : https://raw.githubusercontent.com/junjiemars/kit/master/ul/nd.sh
#------------------------------------------------

ND_ROOT="${ND_ROOT:-$(cd `dirname ${BASH_SOURCE[0]}`; pwd -P)}"
ND_PWD="`pwd -P`"
GREP_OPT_E="`echo 123 | grep -E '^[0-9]+$'`"

find_nginx_home() {
	local x="$@"
	for d in `find . -type d -depth 1`; do
		d="`echo $d | sed 's#^\.\/##g'`"
		case "$d" in
			nginx|nginx-release-*)
				if [ -f "${d%/}/auto/configure" ]; then
					echo "${d%/}"
					return 0
				fi
				;;
			*) continue ;;
		esac
	done
	return 1
}

is_int() {
	local n="$1"
	if [ 0 -eq $GREP_OPT_E ]; then
		echo "$n" | grep -E '^[0-9]+$'
	else
		test -n "$n" && test "$n" -eq "$n" 2>/dev/null
	fi
}

n_cpu() {
	local os="`uname -s`"
	local n=1
	case "$os" in
		Darwin) n="`sysctl -n hw.ncpu`" ;;
    Linux) n="`grep -c processor /proc/cpuinfo`" ;;
	esac
	echo $n
}

ND_CPU_N=`n_cpu`

NGX_TARGET=( raw http https stream dns )
NGX_IDX=( ${NGX_TARGET[0]} )
NGX_OPTIONS="${NGX_OPTIONS}"

NGX_HOME="${NGX_HOME:-`find_nginx_home ${ND_PWD}`}"
NGX_PREFIX="${NGX_PREFIX:-${PWD}/run}"
NGX_CONF_DIR="${NGX_PREFIX%/}/conf"
NGX_LOG_DIR="${NGX_LOG_DIR:-${NGX_PREFIX%/}/var/nginx}"

NGX_ERR_LOG=error.log
NGX_PID_LOG=pid

NGX_CHAINED=( no yes )

NGX_GEN_CONF=( no yes )
NGX_GEN_SHELL=( no yes )

NGX_CONF="nginx.conf"
NGX_SHELL="nginx.sh"

OPT_CPU_N=1
OPT_CON_N=1024

OPT_LISTEN_PORT=8080 
OPT_UPSTREAM=
OPT_SERVER_NAME=localhost
OPT_SERVER_TOKENS=( on off )

opt_prompt() {
	echo "[$@]" | tr ' ' '|'
}

opt_check() {
	local a=( "$@" )
	if [ 0 -eq ${#a[@]} ]; then
		return 1
	fi

	for i in ${a[@]:1}; do
		local opt="`echo ${a[0]} | tr [:upper:] [:lower:]`"
		if [ ".$opt" = ".$i" ]; then
			echo "$opt"
			return 0
		fi
	done
	return 1
}

opt_is_int() {
	local n="$1"
	local r='^[0-9]+$'
	[ $n =~ $r ]
}

usage() {
  echo -e "Usage: $(basename $0) [OPTIONS] COMMAND [arg...]"
  echo -e "       $(basename $0) [ --help | --version ]\n"
  echo -e "Options:"
  echo -e "  --help     Print this message"
  echo -e ""
  echo -e "  --target=   what nginx `opt_prompt ${NGX_TARGET[@]}` do, NGX_TARGET='$NGX_TARGET'"
  echo -e "  --options=  nginx auto/configure options, NGX_OPTIONS='${NGX_OPTIONS}'"
	echo -e ""
  echo -e "  --home=      nginx source dir, NGX_HOME='${NGX_HOME}'"
  echo -e "  --prefix=    nginx prefix dir, NGX_PREFIX='${NGX_PREFIX}'"
  echo -e "  --conf-dir=  where nginx conf, NGX_CONF_DIR='${NGX_CONF_DIR}'"
  echo -e "  --log-dir=   where nginx log store, NGX_LOG_DIR='${NGX_LOG_DIR}'"
	echo -e ""
  echo -e "  --chained=`opt_prompt ${NGX_CHAINED[@]}`    chained commands, NGX_CHAINED='$NGX_CHAINED'"
  echo -e "  --gen-conf=`opt_prompt ${NGX_GEN_CONF[@]}`   generate nginx.conf, NGX_GEN_CONF='$NGX_GEN_CONF'"
  echo -e "  --gen-shell=`opt_prompt ${NGX_GEN_SHELL[@]}`  generate nginx.sh, NGX_GEN_SHELL='$NGX_GEN_SHELL'"
  echo -e ""
  echo -e "  --opt-processes=      option: worker_processes, default is '$OPT_CPU_N'"
  echo -e "  --opt-connections=    option: worker_connections, default is '$OPT_CON_N'"
  echo -e "  --opt-listen-port=    option: listen_port, default is '$OPT_LISTEN_PORT'"
  echo -e "  --opt-upstream=       option: upstream backends, ='upstream1 upstream2 ...'"
  echo -e "  --opt-server-name=    option: server_name, default is '$OPT_SERVER_NAME'"
  echo -e "  --opt-server-tokens=  option: server_tokens `opt_prompt ${OPT_SERVER_TOKENS[@]}`, default is '$OPT_SERVER_TOKENS'"
	echo -e ""
  echo -e "A nginx configurator and shell maker"
	echo -e ""
  echo -e "Commands:"
  echo -e "  list       list nginx configure options"
  echo -e "  configure  configure nginx build env"
  echo -e "  make       make nginx"
  echo -e "  install    install nginx"
  echo -e "  clean      clean nginx build env"
  echo -e "  modules    build nginx modules"
  echo -e "  upgrade    upgrade nginx"
}


for option
do
  opt="$opt `echo $option | sed -e \"s/\(--[^=]*=\)\(.* .*\)/\1'\2'/\"`"
  
  case "$option" in
    -*=*) value=`echo "$option" | sed -e 's/[-_a-zA-Z0-9]*=//'` ;;
    *) value="" ;;
  esac
  
  case "$option" in
    --help)                           help=yes                             ;;

    --target=*)                       ngx_target=( $value )                ;;
    --options=*)                      ngx_options="$value"                 ;;

    --home=*)                         ngx_home="$value"                    ;;
    --prefix=*)                       ngx_prefix="$value"                  ;;
    --conf-dir=*)                     ngx_conf_dir="$value"                ;;
    --log-dir=*)                      ngx_log_dir="$value"                 ;;

    --chained=*)                      ngx_chained="$value"                 ;;
    --gen-conf=*)                     ngx_gen_conf="$value"                ;;
    --gen-shell=*)                    ngx_gen_shell="$value"               ;;

    --opt-processes=*)                OPT_CPU_N="$value"                   ;;
    --opt-connections=*)              OPT_CON_N="$value"                   ;;
    --opt-listen-port=*)              OPT_LISTEN_PORT="$value"             ;;
    --opt-upstream=*)                 OPT_UPSTREAM=( "$value" )            ;;
    --opt-server-tokens=*)            OPT_SERVER_TOKENS=( "$value" )       ;;
    
    *)

			case "$option" in
				-*)
					echo "$0: error: invalid option \"$option\""
					usage
					exit 1
				;;

				*) 
      		command="$option"
				;;
			esac

    ;;
  esac
done


if [ "yes" = "$help" -o 0 -eq $# ]; then
	usage
	exit 0
fi

# setup env vars
retval=0

if [ -n "$ngx_home" ]; then
	NGX_HOME="${ngx_home%/}"
fi
if [ ! -d "$NGX_HOME" ]; then
	echo -e "! --home=$NGX_HOME  =invalid"
	exit 1
fi

if [ -n "$ngx_prefix" ]; then
  NGX_PREFIX="${ngx_prefix%/}"
fi
if [ ! -d "$NGX_PREFIX" ]; then
	echo -e "! --prefix=$NGX_PREFIX  =invalid, try to create '$NGX_PREFIX' ..."
	mkdir -p "$NGX_PREFIX"
	retval=$?
	[ 0 -eq $retval ] || exit $retval
fi

if [ -n "$ngx_conf_dir" ]; then
	NGX_CONF_DIR="${ngx_conf_dir%/}"
fi
if [ ! -d "$NGX_CONF_DIR" ]; then
	echo -e "! --conf-dir=$NGX_CONF_DIR  =invalid, try to create '$NGX_CONF_DIR'..."
	mkdir -p "$NGX_CONF_DIR"	
	retval=$?
	[ 0 -eq $retval ] || exit $retval
fi

if [ -n "$ngx_log_dir" ]; then
	NGX_LOG_DIR="${ngx_log_dir%/}"
fi
if [ ! -d "$NGX_LOG_DIR" ]; then
	echo -e "! --log-dir=$NGX_LOG_DIR  =invalid, try to create '$NGX_LOG_DIR' ..."
	mkdir -p "$NGX_LOG_DIR"	
	retval=$?
	[ 0 -eq $retval ] || exit $retval
fi

if [ -n "$ngx_options" ]; then
	NGX_OPTIONS="$ngx_options"
fi

if [ -n "$ngx_chained" ]; then
	NGX_CHAINED=`opt_check $ngx_chained ${NGX_CHAINED[@]}`
	retval=$?
	if [ 0 -ne $retval ]; then
		echo -e "! --target=\"$ngx_chained\"  =invalid"
		exit $retval
	fi	
fi

if [ -n "$ngx_gen_conf" ]; then
	NGX_GEN_CONF=`opt_check $ngx_gen_conf ${NGX_GEN_CONF[@]}`
	retval=$?
	if [ 0 -ne $retval ]; then
		echo -e "! --target=\"$ngx_gen_conf\"  =invalid"
		exit $retval
	fi
fi

if [ -n "$ngx_gen_shell" ]; then
	NGX_GEN_SHELL=`opt_check $ngx_gen_shell ${NGX_GEN_SHELL[@]}`
	retval=$?
	if [ 0 -ne $retval ]; then
		echo -e "! --target=\"$ngx_gen_shell\"  =invalid"
		exit $retval
	fi
fi

if [ -n "$ngx_target" ]; then
	NGX_IDX=()
	for i in "${ngx_target[@]}"; do
		j=`opt_check "${i}" "${NGX_TARGET[@]}"`
		retval=$?
		if [ 0 -ne $retval ]; then
			echo -e "! --target=\"${i}\"  =invalid"
			exit $retval
		fi
		NGX_IDX+=( "${j}" )
	done
fi


do_list() {
	cd $NGX_HOME
	auto/configure --help
}

configure_prefix() {
echo "\
--prefix=$NGX_PREFIX                             \
--error-log-path=${NGX_LOG_DIR%/}/$NGX_ERR_LOG   \
--pid-path=${NGX_LOG_DIR%/}/$NGX_PID_LOG         \
"
}

configure_option() {
	case "$1" in

		raw)
echo "\
"

		;;

		http)
echo "\
--http-log-path=${NGX_LOG_DIR%/}/access.log        \
--without-http_fastcgi_module    				           \
--without-http_memcached_module  				           \
--without-http_rewrite_module                      \
--without-http_scgi_module                         \
"

		;;

		stream|dns)
echo "\
--with-stream                    				          \
--without-stream_geo_module      				          \
"

		;;

		*)
		;;

	esac
}


do_configure() {
	local c="`configure_prefix | tr -s ' '`"

	for i in "${NGX_IDX[@]}"; do
		c="${c} `configure_option ${i} | tr -s ''`"
	done
	c="${c} ${NGX_OPTIONS[@]}"

	if [ "yes" = "$NGX_GEN_SHELL" ]; then
		gen_shell
	fi

	if [ "yes" = "$NGX_GEN_CONF" ]; then
		gen_conf
	fi

	cd $NGX_HOME
	auto/configure ${c}
}


do_make() {
	local t=0
	if [ "yes" = "$NGX_CHAINED" ]; then
		do_configure	
		t=$?
		[ 0 -eq $t ] || exit $t
	fi
	cd $NGX_HOME
	make -j$ND_CPU_N
}


do_install() {
	local t=0
	
	if [ "yes" = "$NGX_CHAINED" ]; then
		do_make
		t=$?
		[ 0 -eq $t ] || exit $t
	fi

	cd $NGX_HOME
	make install
}

do_clean() {
	[ -f "$NGX_CONF" ] && rm $NGX_CONF
	[ -f "$NGX_SHELL" ] && rm $NGX_SHELL

	cd $NGX_HOME
	make clean
}


do_modules() {
	local t=0

	if [ "yes" = "$NGX_CHAINED" ]; then
		do_configure	
		t=$?
		[ 0 -eq $t ] || exit $t
	fi

	cd $NGX_HOME
	make modules
}


do_upgrade() {
	local t=0

	if [ "yes" = "$NGX_CHAINED" ]; then
		do_install
		t=$?
		[ 0 -eq $t ] || exit $t
	fi

	cd $NGX_HOME
	make upgrade
}


gen_conf_header() {
	cat <<END >>"$1"
#
# generated by nd.sh (https://github.com/junjiemars/kit)
#

worker_processes	$OPT_CPU_N;

#error_log  ${NGX_LOG_DIR%/}/error.log;
#error_log  ${NGX_LOG_DIR%/}/error.log  notice;
#error_log  ${NGX_LOG_DIR%/}/error.log  info;

#pid        logs/pid;

events {
    worker_connections	$OPT_CON_N;
}

END
}


gen_raw_section() {
	return 0
}

gen_http_section() {
	cat <<END >>"$1"

http {
    #access_log  off;
    #log_format access_log_format '\$remote_addr "\$remote_user" [\$time_local] '
    #                             '"\$request" \$status "\$http_referer" '
    #                             '"\$http_user_agent" \$bytes_sent "\$request_body"';
    #access_log ${NGX_LOG_DIR%/}/access.log access_log_format;
    #access_log ${NGX_LOG_DIR%/}/access.log;
    #default_type  application/octet-stream;
    #include       mime.types;
    #gzip  on;
    #gzip_min_length  1000;
    #gzip_types     text/plain application/xml;
    #keepalive_timeout  0;
    #keepalive_timeout  65;
    #sendfile        on;
    #tcp_nopush     on;

    upstream backend {
        server 127.0.0.1:8181 weight=5;
        #server x.x.x.x:8282 backup;
`
for i in ${OPT_UPSTREAM[@]}; do
    echo "\
        server $i;"
done
`
    } # end of upstream

    server {
        listen $OPT_LISTEN_PORT;
        server_name  localhost;
        server_tokens $OPT_SERVER_TOKENS;

        location / {
          proxy_pass http://backend;

        } # end of location

    } # end of server

} # end of http

END
}


gen_stream_section() {
	cat <<END >>"$NGX_CONF"

stream {

    upstream backend {
        hash \$remote_addr consistent;

        server 127.0.0.1:12345    weight=5;
        #server x.x.x.x:12345     max_fails=3 fail_timeout=30s;
`
for i in ${OPT_UPSTREAM[@]}; do
    echo "\
        server $i;"
done
`

    } # end of upstream backend

    server {
        listen $OPT_LISTEN_PORT;
        #proxy_connect_timeout 1s;
        #proxy_timeout 3s;
        proxy_pass backend;

    } # end of server

} # end of stream

END
}


gen_dns_section() {
	cat <<END >>"$NGX_CONF"

stream {

    upstream dns {
        #server x.x.x.x:53;
`
for i in ${OPT_UPSTREAM[@]}; do
    echo "\
        server $i;"
done
`

    } # end of upstream dns

    server {
        listen $OPT_LISTEN_PORT udp;
        proxy_responses 1;
        proxy_timeout 20s;
        proxy_pass dns;

    } #end of server

} # end of stream

END
}


gen_shell() {
	cat << END > $NGX_SHELL
#!/bin/bash
#------------------------------------------------
# target: init script
# author: junjiemars@gmail.com
# generated by Kit (https://github.com/junjiemars/kit/ul/nd.sh)
#------------------------------------------------
# $0
#    --target='${NGX_IDX[@]}'
#    --home=$NGX_HOME
#    --run-dir=$NGX_PREFIX
#    --conf-dir=$NGX_CONF_DIR
#    --log-dir=$NGX_LOG_DIR
#    --options=$NGX_OPTIONS
#    --chained=$NGX_CHAINED
#    --gen-conf=$NGX_GEN_CONF
#    --gen-shell=$NGX_GEN_SHELL
#    --opt-processes=$OPT_CPU_N
#    --opt-connections=$OPT_CON_N
#    --opt-listen-port=$OPT_LISTEN_PORT
#    --opt-upstream=$OPT_UPSTREAM
#    --opt-server-name=$OPT_SERVER_NAME
#    --opt-server-tokens=$OPT_SERVER_TOKENS

ND_ROOT="${ND_ROOT%/}"
ND_PWD="${ND_PWD%/}"
ND_CPU_N=${ND_CPU_N}
NGX_PREFIX="${NGX_PREFIX%/}"
NGX_CONF_DIR="${NGX_CONF_DIR%/}"
NGX_LOG_DIR="${NGX_LOG_DIR%/}"
NGX_BIN="${NGX_PREFIX%/}/sbin/nginx"
NGX_PID="${NGX_LOG_DIR%/}/${NGX_PID_LOG}"

check_nginx_env() {
  if [ ! -d "\$NGX_PREFIX" ]; then
    echo -e "! \$NGX_PREFIX does not exist"
    exit 1
  fi

  if [ ! -d "\$NGX_CONF_DIR" ]; then
    echo -e "! \$NGX_CONF_DIR does not exist"
    exit 1
  fi

  if [ ! -f "\$NGX_BIN" ]; then
    echo -e "! \$NGX_BIN does not exist"
    exit 1
  fi
}

copy_nginx_conf() {
  local s="\${ND_PWD}/$NGX_CONF"
  local d="\${NGX_CONF_DIR}/$NGX_CONF"

  if [ ! -f "\$s" ]; then
    echo -e "! \$s does not exist"
    exit 1
  fi

  if \`diff "\$s" "\$d" &>/dev/null\`; then
    return 0
  fi

  if [ ! -f "\${d}.ori" ]; then
    if [ -f "\${d}" ]; then
      cp "\${d}" "\${d}.ori"
    else
      cp "\${s}" "\${d}.ori"
    fi
  fi
  if [ -f "\${d}" ]; then
    cp "\${d}" "\${d}.pre"
  fi
  cp "\${s}" "\${d}"
}

echo -n "+check nginx env ... "
if \`check_nginx_env\`; then
	echo "done"
else
	echo "failed"
fi

echo -n "+copy nginx conf ... "
if \`copy_nginx_conf\`; then
	echo "done"
else
	echo "failed"
fi

echo "+run: \$@ ... "
echo "--------------------"
\${NGX_BIN} \$@

END

	[ -f $NGX_SHELL ] && chmod u+x $NGX_SHELL
}


gen_conf() {
	echo -n > "$NGX_CONF"

	gen_conf_header "$NGX_CONF"

	for i in "${NGX_IDX[@]}"; do
		gen_${i}_section "$NGX_CONF"
	done

	local f="${NGX_CONF_DIR%/}/$NGX_CONF"
	if [ -f "${f}" ]; then
		mv ${f} ${f}.b0
	fi
	cp $NGX_CONF ${f}
}


command="`echo $command | tr '[:upper:]' '[:lower:]'`"
case "$command" in

	list)
		do_list
	;;

  configure)
		do_configure	
	;;

	make)
		do_make -j4
	;;

	install)
		do_install
	;;

	clean)
		do_clean
	;;

	modules)
		do_modules
	;;

	upgrade)
		do_upgrade
	;;

  *)
		echo "$0: error: invalid command \"$command\""
		usage
		exit 1
  ;;

esac
