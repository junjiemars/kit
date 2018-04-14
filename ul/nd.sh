#!/bin/bash
#------------------------------------------------
# require: bash env
# target : nginx maker
# author : junjiemars@gmail.com
# url    : https://raw.githubusercontent.com/junjiemars/kit/master/ul/nd.sh
#------------------------------------------------

VERSION="0.1.1"

ROOT="${ROOT:-$(cd `dirname ${BASH_SOURCE[0]}`; pwd -P)}"
OPT_RUN="${OPT_RUN:-${ROOT%/}/run}"

find_nginx_home() {
	for d in `ls -d ${ROOT%/}/*/`; do
		if [[ $d =~ ${ROOT%/}/(nginx|nginx-release-*) ]]; then
			if [ -f "${d%/}/auto/configure" ]; then
				echo "${d%/}"
				return 0
			fi
		fi
	done
	return 1
}

NGX_TARGET=( raw http https stream dns )
NGX_IDX=( ${NGX_TARGET[0]} )
NGX_HOME=${NGX_HOME:-`find_nginx_home`}
NGX_RUN_DIR=${NGX_RUN_DIR:-$OPT_RUN}
NGX_CONF_DIR=${NGX_CONF_DIR:-${NGX_RUN_DIR%/}/conf}
NGX_LOG_DIR=${NGX_LOG_DIR:-${NGX_RUN_DIR%/}/var/nginx}
NGX_OPTIONS=${NGX_OPTIONS}

NGX_ERR_LOG=error.log
NGX_PID_LOG=pid

NGX_CHAINED=( no yes )

NGX_GEN_CONF=( yes no )
NGX_GEN_SHELL=( yes no )

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


usage() {
  echo -e "Usage: $(basename $0) [OPTIONS] COMMAND [arg...]"
  echo -e "       $(basename $0) [ --help | --version ]\n"
  echo -e "Options:"
  echo -e "  --help\t\t\tPrint this message"
  echo -e "  --version\t\t\tPrint version information and quit"
  echo -e ""
  echo -e "  --target=\t\t\twhat nginx `opt_prompt ${NGX_TARGET[@]}` do, NGX_TARGET='$NGX_TARGET'"
  echo -e "  --home=\t\t\tnginx source dir, NGX_HOME='${NGX_HOME}'"
  echo -e "  --run-dir=\t\t\twhere nginx run, NGX_RUN_DIR='${NGX_RUN_DIR}'"
  echo -e "  --conf-dir=\t\t\twhere nginx conf, NGX_CONF_DIR='${NGX_CONF_DIR}'"
  echo -e "  --log-dir=\t\t\twhere nginx log store, NGX_LOG_DIR='${NGX_LOG_DIR}'"
  echo -e "  --options=\t\t\tnginx auto/configure options, NGX_OPTIONS='${NGX_OPTIONS}'"

  echo -e "  --chained=`opt_prompt ${NGX_CHAINED[@]}`\t\tchained commands, NGX_CHAINED='$NGX_CHAINED'"
  echo -e "  --gen-conf=`opt_prompt ${NGX_GEN_CONF[@]}`\t\tgenerate nginx.conf, NGX_GEN_CONF='$NGX_GEN_CONF'"
  echo -e "  --gen-shell=`opt_prompt ${NGX_GEN_SHELL[@]}`\t\tgenerate nginx.sh, NGX_GEN_SHELL='$NGX_GEN_SHELL'"
  echo -e ""
  echo -e "  --opt-processes=\t\toption: worker_processes, default is '$OPT_CPU_N'"
  echo -e "  --opt-connections=\t\toption: worker_connections, default is '$OPT_CON_N'"
  echo -e "  --opt-listen-port=\t\toption: listen_port, default is '$OPT_LISTEN_PORT'"
  echo -e "  --opt-upstream=\t\toption: upstream backends, ='upstream1 upstream2 ...'"
  echo -e "  --opt-server-name=\t\toption: server_name, default is '$OPT_SERVER_NAME'"
  echo -e "  --opt-server-tokens=\t\toption: server_tokens `opt_prompt ${OPT_SERVER_TOKENS[@]}`, default is '$OPT_SERVER_TOKENS'"
	echo -e ""
  echo -e "A nginx configurator and shell maker"
	echo -e ""
  echo -e "Commands:"
  echo -e "  list\t\t\t\tlist nginx configure options"
  echo -e "  configure\t\t\tconfigure nginx build env"
  echo -e "  make\t\t\t\tmake nginx"
  echo -e "  install\t\t\tinstall nginx"
  echo -e "  clean\t\t\t\tclean nginx build env"
  echo -e "  modules\t\t\tbuild nginx modules"
  echo -e "  upgrade\t\t\tupgrade nginx"
}


for option
do
  opt="$opt `echo $option | sed -e \"s/\(--[^=]*=\)\(.* .*\)/\1'\2'/\"`"
  
  case "$option" in
    -*=*) value=`echo "$option" | sed -e 's/[-_a-zA-Z0-9]*=//'` ;;
    *) value="" ;;
  esac
  
  case "$option" in
    --help)                  				help=yes                   				 ;;
    --version)               				version=yes                				 ;;

    --target=*)             				ngx_target=( $value ) 	  				 ;;
    --home=*)                				ngx_home="$value"    							 ;;
		--run-dir=*)             				ngx_run_dir="$value"       				 ;;
		--conf-dir=*)             			ngx_conf_dir="$value"     				 ;;
		--log-dir=*)             				ngx_log_dir="$value"       				 ;;
		--options=*)             				ngx_options="$value"       				 ;;

		--chained=*)            				ngx_chained="$value"       				 ;;
		--gen-conf=*)               		ngx_gen_conf="$value"      				 ;;
		--gen-shell=*)               		ngx_gen_shell="$value"     				 ;;

		--opt-processes=*)     					OPT_CPU_N="$value"      		       ;;
		--opt-connections=*)     				OPT_CON_N="$value"       		       ;;
		--opt-listen-port=*)     				OPT_LISTEN_PORT="$value"		       ;;
		--opt-upstream=*)								OPT_UPSTREAM=( "$value" )          ;;
		--opt-server-tokens=*)	 				OPT_SERVER_TOKENS=( "$value" )     ;;
    
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

if [ "yes" = "$version" ]; then
	echo -e "$VERSION"
	exit 0
fi

# setup env vars
retval=0

if [ -n "$ngx_home" ]; then
	NGX_HOME="$ngx_home"
fi
if [ ! -d "$NGX_HOME" ]; then
	echo -e "! --home=$NGX_HOME  =invalid"
	exit 1
fi


if [ -n "$ngx_run_dir" ]; then
  NGX_RUN_DIR="$ngx_run_dir"
fi
if [ ! -d "$NGX_RUN_DIR" ]; then
	echo -e "! --run-dir=$NGX_RUN_DIR  =invalid, try to create '$NGX_RUN_DIR' ..."
	mkdir -p "$NGX_RUN_DIR"
	retval=$?
	[ 0 -eq $retval ] || exit $retval
fi

if [ -n "$ngx_conf_dir" ]; then
	NGX_CONF_DIR="$ngx_conf_dir"
fi
if [ ! -d "$NGX_CONF_DIR" ]; then
	echo -e "! --conf-dir=$NGX_CONF_DIR  =invalid, try to create '$NGX_CONF_DIR'..."
	mkdir -p "$NGX_CONF_DIR"	
	retval=$?
	[ 0 -eq $retval ] || exit $retval
fi

if [ -n "$ngx_log_dir" ]; then
	NGX_LOG_DIR="$ngx_log_dir"
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
--prefix=$NGX_RUN_DIR                             \
--error-log-path=${NGX_LOG_DIR%/}/$NGX_ERR_LOG    \
--pid-path=${NGX_LOG_DIR%/}/$NGX_PID_LOG          \
"
}

configure_option() {
	case "$1" in

		raw)
echo "\
`echo ${NGX_OPTIONS[@]}`
"

		;;

		http)
echo "\
--http-log-path=${NGX_LOG_DIR%/}/access.log        \
--without-http_fastcgi_module    				           \
--without-http_memcached_module  				           \
--without-http_rewrite_module                      \
--without-http_scgi_module                         \
`echo ${NGX_OPTIONS[@]}`
"

		;;

		stream|dns)
echo "\
--with-stream                    				          \
--without-http_fastcgi_module    				          \
--without-http_geo_module        				          \
--without-http_map_module        				          \
--without-http_memcached_module  				          \
--without-http_scgi_module       				          \
--without-mail_imap_module       				          \
--without-mail_pop3_module       				          \
--without-mail_smtp_module       				          \
--without-stream_geo_module      				          \
`echo ${NGX_OPTIONS[@]}`
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
	make -j4
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

	cd $NGX_HOME
	make upgrade
}


gen_conf_header() {
	cat <<END >>"$1"
#
# generated by nd.sh (https://github.com/junjiemars/kit)
#

worker_processes	$OPT_CPU_N;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

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
    #default_type  application/octet-stream;
    #include       mime.types;
    #gzip  on;
		#gzip_min_length  1000;
		#gzip_types		text/plain application/xml;
    #keepalive_timeout  0;
    #keepalive_timeout  65;
    #sendfile        on;
    #tcp_nopush     on;

		upstream backend {
				#server x.x.x.x:8181 weight=5;
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

        #server x.x.x.x:12345     weight=5;
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
        proxy_connect_timeout 1s;
        proxy_timeout 3s;
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
#    --run-dir=$NGX_RUN_DIR
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

ROOT=${ROOT%/}
NGX_HOME=${NGX_RUN_DIR%/}
NGX_CONF_DIR=${NGX_CONF_DIR}
NGX_BIN=\${NGX_HOME}/sbin/nginx

check_nginx_env() {
  if [ ! -d "\$NGX_HOME" ]; then
    echo -e "! \$NGX_HOME does not exist"
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
  local s="\${ROOT}/$NGX_CONF"
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

check_nginx_env
copy_nginx_conf

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
